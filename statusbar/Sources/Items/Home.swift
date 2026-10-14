import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

// --- home assistant: the REST API, polled. HA_URL and HA_TOKEN (a
// long-lived token from the HA profile page) come from ~/.env, the file
// bin/acc sources too — no token, no item.
// ponytail: whatever HA has in HOME_DOMAINS shows up, no per-device config

struct HomeEntity {
    var id = "", name = "", state = ""
    var temp: Double?, target: Double? // climate only
    var minT = 16.0, maxT = 30.0, step = 1.0
    var domain: String { String(id.prefix { $0 != "." }) }
    var on: Bool { !["off", "unavailable", "unknown"].contains(state) }
}
var home: [HomeEntity]? // nil = HA unreachable
var homeSlide: DispatchWorkItem? // debounces the climate slider

// re-read on every call: editing ~/.env needs no rebuild or restart
func dotenv(_ key: String) -> String {
    let text = (try? String(contentsOfFile: NSHomeDirectory() + "/.env", encoding: .utf8)) ?? ""
    for line in text.split(separator: "\n") {
        let kv = line.split(separator: "=", maxSplits: 1)
        guard kv.count == 2, kv[0].trimmingCharacters(in: .whitespaces) == key else { continue }
        return kv[1].trimmingCharacters(in: CharacterSet(charactersIn: " \"'"))
    }
    return ""
}
var HA_URL: String { dotenv("HA_URL") }
func haToken() -> String { dotenv("HA_TOKEN") }

func haRequest(_ path: String, _ body: [String: Any]? = nil, done: @escaping (Data?) -> Void) {
    DispatchQueue.global(qos: .utility).async {
        let token = haToken()
        guard !token.isEmpty, let url = URL(string: HA_URL + "/api/" + path) else { return done(nil) }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body {
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        URLSession.shared.dataTask(with: request) { data, response, _ in
            done((response as? HTTPURLResponse)?.statusCode == 200 ? data : nil)
        }.resume()
    }
}

// the switch moves now, HA's answer (via updateHome) has the last word
func haToggle(_ e: HomeEntity, _ on: Bool, _ service: String) {
    if let i = home?.firstIndex(where: { $0.id == e.id }) { home?[i].state = on ? "on" : "off" }
    refreshPopup()
    haCall(e, service)
}

func haCall(_ e: HomeEntity, _ service: String, _ extra: [String: Any] = [:]) {
    haRequest("services/\(e.domain)/\(service)", extra.merging(["entity_id": e.id]) { a, _ in a }) { _ in
        updateHome()
    }
}

func updateHome() {
    DispatchQueue.global(qos: .utility).async {
        guard !haToken().isEmpty else { return } // not set up: the item stays hidden
        haRequest("states") { data in
            var list: [HomeEntity]?
            if let data, let states = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                list = states.compactMap { s in
                    guard let id = s["entity_id"] as? String, let state = s["state"] as? String,
                          state != "unavailable" else { return nil }
                    var e = HomeEntity(id: id, state: state)
                    guard HOME_DOMAINS.contains(e.domain) else { return nil }
                    let a = s["attributes"] as? [String: Any] ?? [:]
                    e.name = a["friendly_name"] as? String ?? id
                    // no room sensor: show the setpoint (pitsos_ac reports it read-only)
                    e.temp = a["current_temperature"] as? Double ?? a["setpoint"] as? Double
                    e.target = a["temperature"] as? Double
                    e.minT = a["min_temp"] as? Double ?? e.minT
                    e.maxT = a["max_temp"] as? Double ?? e.maxT
                    e.step = a["target_temp_step"] as? Double ?? e.step
                    return e
                }.sorted { a, b in
                    // climate first, then by name
                    a.domain == b.domain || (a.domain != "climate" && b.domain != "climate")
                        ? a.name < b.name : a.domain == "climate"
                }
            }
            DispatchQueue.main.async {
                home = list
                set("home") {
                    $0.drawing = true
                    $0.icon = "sf:house.fill"
                    $0.iconColor = list == nil ? \.red : nil
                }
                if openPopup == "home" { refreshPopup() }
            }
        }
    }
}

func homeRows() -> [PopupRow] {
    guard rightItems["home"]?.drawing == true else { return [] }
    var rows = [PopupRow(text: "home assistant", hero: true)]
    if let list = home {
        for e in list {
            let on = e.on
            switch e.domain {
            case "climate":
                let temp = e.temp.map { "\(Int($0.rounded()))° · " } ?? ""
                rows.append(PopupRow(icon: on ? "sf:snowflake" : "sf:power", text: e.name,
                                     detail: temp + e.state, toggle: on,
                                     onToggle: { haToggle(e, $0, $0 ? "turn_on" : "turn_off") }))
                guard on, let target = e.target else { continue }
                let span = e.maxT - e.minT
                rows.append(PopupRow(text: String(format: target.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f°" : "%.1f°", target),
                                     slider: (target - e.minT) / span,
                                     onSlide: { f in
                                         let v = e.minT + ((f * span) / e.step).rounded() * e.step
                                         // the row follows the pointer now, HA hears it once the drag settles
                                         if let i = home?.firstIndex(where: { $0.id == e.id }) { home?[i].target = v }
                                         refreshPopup()
                                         homeSlide?.cancel()
                                         let work = DispatchWorkItem { haCall(e, "set_temperature", ["temperature": v]) }
                                         homeSlide = work
                                         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
                                     }))
            default:
                let icon = ["light": "sf:lightbulb", "fan": "sf:fan"][e.domain] ?? "sf:power"
                rows.append(PopupRow(icon: icon, text: e.name, toggle: on,
                                     onToggle: { haToggle(e, $0, "toggle") }))
            }
        }
        if list.isEmpty { rows.append(PopupRow(text: "no devices", dim: true)) }
    } else {
        rows.append(PopupRow(icon: "sf:exclamationmark.triangle", text: "unreachable", detail: HA_URL, dim: true))
    }
    rows.append(PopupRow(separator: true))
    rows.append(PopupRow(text: "open Home Assistant…", dim: true, action: {
        if let url = URL(string: HA_URL) { NSWorkspace.shared.open(url) }
        closePopup()
    }))
    return rows
}
