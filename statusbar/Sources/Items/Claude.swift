import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

// --- claude usage: the OAuth usage endpoint Claude Code itself reads, with
// the token Claude Code keeps (and refreshes) in the login keychain
struct ClaudeWindow { var used: Double; var resets: Date? }
var claudeUsage: (fiveHour: ClaudeWindow, week: ClaudeWindow)?

func updateClaude() {
    DispatchQueue.global(qos: .utility).async {
        guard let creds = shell("/usr/bin/security",
                                ["find-generic-password", "-s", "Claude Code-credentials", "-w"]).data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: creds) as? [String: Any],
              let token = (json["claudeAiOauth"] as? [String: Any])?["accessToken"] as? String,
              let url = URL(string: "https://api.anthropic.com/api/oauth/usage")
        else { return DispatchQueue.main.async { fetchFailed("claude", poll: CLAUDE_POLL) } }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data, let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { return DispatchQueue.main.async { fetchFailed("claude", poll: CLAUDE_POLL) } }
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            func window(_ key: String) -> ClaudeWindow? {
                guard let w = root[key] as? [String: Any], let used = w["utilization"] as? Double else { return nil }
                return ClaudeWindow(used: used, resets: (w["resets_at"] as? String).flatMap { iso.date(from: $0) })
            }
            guard let five = window("five_hour"), let week = window("seven_day") else {
                tlog("claude: no usage in response") // an expired token lands here too
                return DispatchQueue.main.async { fetchFailed("claude", poll: CLAUDE_POLL) }
            }
            DispatchQueue.main.async {
                claudeUsage = (five, week)
                lastFetch["claude"] = Date()
                let worst = max(five.used, week.used)
                set("claude") {
                    $0.icon = "donut:\(five.used / 100)"
                    $0.iconColor = worst >= 90 ? \.red : worst >= 70 ? \.yellow : \.accent
                    $0.label = "\(Int(five.used))%"
                    $0.stale = false
                }
                if openPopup == "claude" { refreshPopup() }
            }
        }.resume()
    }
}

func claudeRows() -> [PopupRow] {
    guard let u = claudeUsage else { return [] }
    let time = DateFormatter()
    func left(_ d: Date?) -> String {
        guard let d else { return "" }
        time.dateFormat = Calendar.current.isDateInToday(d) ? "HH:mm" : "EEE HH:mm"
        return time.string(from: d).lowercased()
    }
    return [
        PopupRow(text: "claude", hero: true),
        PopupRow(cells: ["", "used", "resets"], cellDim: [0, 1, 2], labelCol: true),
        PopupRow(cells: ["5 hours", "\(Int(u.fiveHour.used))%", left(u.fiveHour.resets)], cellDim: [0], labelCol: true),
        PopupRow(cells: ["7 days", "\(Int(u.week.used))%", left(u.week.resets)], cellDim: [0], labelCol: true),
        PopupRow(separator: true),
        PopupRow(text: "usage settings…", dim: true, action: {
            NSWorkspace.shared.open(URL(string: "https://claude.ai/settings/usage")!)
            closePopup()
        }),
    ]
}
