import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

// --- tailscale: the CLI's JSON, polled — no event stream to subscribe to.
// The tailnet can hold hundreds of peers, so the popup lists exit nodes
// only, never the whole peer list.

struct TailscaleState {
    var running = false
    var tailnet = ""
    var ip = ""
    var exitNode = "" // hostname of the active one, "" = none
    var exitNodes: [(name: String, ip: String)] = []
}
var tailscale = TailscaleState()

func updateTailscale() {
    guard FileManager.default.isExecutableFile(atPath: TAILSCALE_CLI) else { return }
    DispatchQueue.global(qos: .utility).async {
        var t = TailscaleState()
        if let data = shell(TAILSCALE_CLI, ["status", "--json", "--peers"]).data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            t.running = json["BackendState"] as? String == "Running"
            t.tailnet = (json["CurrentTailnet"] as? [String: Any])?["Name"] as? String ?? ""
            t.ip = ((json["Self"] as? [String: Any])?["TailscaleIPs"] as? [String])?.first ?? ""
            for peer in (json["Peer"] as? [String: [String: Any]] ?? [:]).values {
                let name = peer["HostName"] as? String ?? "?"
                if peer["ExitNode"] as? Bool == true { t.exitNode = name }
                guard peer["ExitNodeOption"] as? Bool == true,
                      let ip = (peer["TailscaleIPs"] as? [String])?.first else { continue }
                t.exitNodes.append((name, ip))
            }
            t.exitNodes.sort { $0.name < $1.name }
        }
        DispatchQueue.main.async {
            tailscale = t
            set("tailscale") {
                $0.drawing = true
                $0.icon = t.running ? "ts" : "ts:off"
                $0.iconColor = nil
                $0.label = "" // the exit node lives in the popup
            }
            if openPopup == "tailscale" { refreshPopup() }
        }
    }
}

func tailscaleRows() -> [PopupRow] {
    let t = tailscale
    func run(_ args: [String]) -> () -> Void {
        { DispatchQueue.global(qos: .userInitiated).async { _ = shell(TAILSCALE_CLI, args); updateTailscale() } }
    }
    var rows = [PopupRow(text: t.tailnet.isEmpty ? "tailscale" : t.tailnet, hero: true,
                         toggle: t.running, onToggle: { on in
        tailscale.running = on // the switch moves now, the CLI confirms on the next update
        refreshPopup()
        run(on ? ["up"] : ["down"])()
    })]
    rows.append(PopupRow(icon: t.running ? "ts" : "ts:off",
                         text: t.running ? "connected" : "disconnected",
                         detail: t.running ? t.ip : "", dim: true))
    if t.running && !t.exitNodes.isEmpty {
        rows.append(PopupRow(separator: true))
        rows.append(PopupRow(text: "exit node", dim: true))
        rows.append(PopupRow(text: "none", highlight: t.exitNode.isEmpty,
                             action: run(["set", "--exit-node="])))
        for node in t.exitNodes {
            rows.append(PopupRow(text: node.name, highlight: node.name == t.exitNode,
                                 action: run(["set", "--exit-node=\(node.ip)"])))
        }
    }
    rows.append(PopupRow(separator: true))
    rows.append(PopupRow(text: "open Tailscale…", dim: true, action: {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Tailscale.app"))
        closePopup()
    }))
    return rows
}
