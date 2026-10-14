import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

// --- agents: one mark per agent of the chosen orchestrator, herdr-style:
// ◐ working, ● done, ◎ blocked (wants input), ○ idle. Three orchestrators,
// each read through its own CLI; the pick lives on the right button.
// ponytail: 5 s poll — herdr and zeron both stream events if this ever lags

enum AgentState: Int, Comparable {
    case blocked, working, done, idle // pill order: what needs you first
    static func < (a: AgentState, b: AgentState) -> Bool { a.rawValue < b.rawValue }
    var color: NSColor {
        switch self {
        case .blocked: return palette.red
        case .working: return palette.accent
        case .done: return palette.green
        case .idle: return palette.muted
        }
    }
}

struct Agent {
    var state: AgentState
    var name = "", detail = ""
    var open: () -> Void = {}
}

var agents: [Agent] = []
let ORCHESTRATORS = ["herdr", "zeron", "superconductor"]
var orchestrator: String {
    get { UserDefaults.standard.string(forKey: "orchestrator") ?? ORCHESTRATORS[0] }
    set { UserDefaults.standard.set(newValue, forKey: "orchestrator"); updateAgents() }
}

func activate(_ app: String) { NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/\(app).app")) }
func basename(_ path: String) -> String { (path as NSString).lastPathComponent }

let HERDR_BIN = "/opt/homebrew/bin/herdr"
func herdrAgents() -> [Agent] {
    guard let data = shell(HERDR_BIN, ["api", "snapshot"]).data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let list = ((json["result"] as? [String: Any])?["snapshot"] as? [String: Any])?["agents"] as? [[String: Any]]
    else { return [] }
    let states: [String: AgentState] = ["working": .working, "blocked": .blocked, "done": .done]
    return list.map { a -> Agent in
        let pane = a["pane_id"] as? String ?? ""
        return Agent(state: states[a["agent_status"] as? String ?? ""] ?? .idle,
                     name: basename(a["cwd"] as? String ?? ""), detail: a["agent"] as? String ?? "",
                     open: {
                         DispatchQueue.global(qos: .userInitiated).async { _ = shell(HERDR_BIN, ["agent", "focus", pane]) }
                         activate("Herdr")
                     })
    }
}

// the engine's IPC is a private websocket; `zeron mcp` is the documented door to it
let ZERON_BIN = "/Applications/Zeron.app/Contents/MacOS/zeron"
func zeronAgents() -> [Agent] {
    let rpc = """
    {"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"statusbar","version":"0"}}}
    {"jsonrpc":"2.0","method":"notifications/initialized"}
    {"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"list_chats","arguments":{}}}

    """
    guard let line = shell(ZERON_BIN, ["mcp"], stdin: rpc).split(separator: "\n").last,
          let reply = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any],
          let text = ((reply["result"] as? [String: Any])?["content"] as? [[String: Any]])?.first?["text"] as? String,
          let body = try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any],
          let chats = body["chats"] as? [[String: Any]] else { return [] }
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return chats.compactMap { c -> Agent? in
        guard c["archived"] as? Bool != true, let status = c["status"] as? String else { return nil }
        let state: AgentState = status.hasPrefix("working") ? .working
            : status == "awaitingInput" || status == "errored" ? .blocked : .idle
        // chats never die, so an idle one counts only while it is recent
        let last = (c["lastMessageAt"] as? String).flatMap(iso.date) ?? .distantPast
        guard state != .idle || last.timeIntervalSinceNow > -3600 else { return nil }
        let id = c["id"] as? String ?? ""
        let project = (c["project"] as? [String: Any])?["name"] as? String ?? ""
        return Agent(state: state, name: c["title"] as? String ?? project, detail: project,
                     open: { NSWorkspace.shared.open(URL(string: "zeron://open/chat/\(id)")!) })
    }
}

let SC_BIN = NSHomeDirectory() + "/.superconductor/bin/sc"
func superconductorAgents() -> [Agent] {
    guard let data = shell(SC_BIN, ["chat", "list", "--json"]).data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) else { return [] }
    // ponytail: the list's shape is unverified (the app was down when this was
    // written) — any object carrying a known status string counts as an agent
    let states: [String: AgentState] = ["running": .working, "awaiting_user_input": .blocked,
                                        "completion_candidate": .done, "idle": .idle, "unknown": .idle]
    var found: [Agent] = []
    func walk(_ v: Any) {
        if let d = v as? [String: Any] {
            if let s = ["agent_status", "status", "phase", "state"].compactMap({ d[$0] as? String }).first(where: { states[$0] != nil }) {
                found.append(Agent(state: states[s]!,
                                   name: d["label"] as? String ?? d["title"] as? String ?? basename(d["worktree_path"] as? String ?? ""),
                                   detail: d["provider"] as? String ?? "", open: { activate("super.engineering") }))
                return
            }
            d.values.forEach(walk)
        } else if let a = v as? [Any] { a.forEach(walk) }
    }
    walk(json)
    return found
}

func updateAgents() {
    let which = orchestrator
    DispatchQueue.global(qos: .utility).async {
        let list: [Agent]
        switch which {
        case "zeron": list = zeronAgents()
        case "superconductor": list = superconductorAgents()
        default: list = herdrAgents()
        }
        let sorted = list.sorted { $0.state < $1.state }
        DispatchQueue.main.async {
            guard which == orchestrator else { return } // switched while we polled
            agents = sorted
            // one mark per agent that is doing something; the idle ones (a
            // dozen parked herdr panes) fold into a single ring and a count
            // ponytail: active marks cap at 8 with no overflow hint
            let active = sorted.filter { $0.state != .idle }, idle = sorted.count - active.count
            set("agents") {
                $0.icon = sorted.isEmpty ? "sf:circle.dotted"
                    : "agents:" + active.prefix(8).map { String($0.state.rawValue) }.joined() + (idle > 0 ? "\(AgentState.idle.rawValue)" : "")
                $0.iconColor = sorted.isEmpty ? \Palette.muted : nil
                $0.label = idle > 1 ? "\(idle)" : ""
            }
        }
    }
}

func orchestratorRows() -> [PopupRow] {
    [PopupRow(text: "orchestrator", hero: true)] + ORCHESTRATORS.map { name in
        PopupRow(text: name, checked: name == orchestrator, action: { orchestrator = name; closePopup() })
    }
}

func agentRows() -> [PopupRow] {
    var rows = [PopupRow(text: orchestrator, hero: true)]
    if agents.isEmpty { rows.append(PopupRow(text: "no agents", dim: true)) }
    // the widest row sets the popup's width, and a zeron chat title runs a whole sentence
    func clip(_ s: String, _ n: Int) -> String { s.count > n ? s.prefix(n - 1) + "…" : s }
    for a in agents {
        rows.append(PopupRow(icon: "agents:\(a.state.rawValue)", text: clip(a.name, 28), detail: clip(a.detail, 14),
                             action: { a.open(); closePopup() }))
    }
    return rows
}
