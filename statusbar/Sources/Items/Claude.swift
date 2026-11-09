import AppKit
import SwiftUI

// --- claude usage: the OAuth usage endpoint Claude Code itself reads, with
// the token Claude Code keeps (and refreshes) in the login keychain
struct ClaudeLimit { var name: String; var used: Double; var resets: Date? }
var claudeLimits: [ClaudeLimit] = []
var claudePlan = "" // "Max 5x", from the tier the credentials carry

func updateClaude() {
    DispatchQueue.global(qos: .utility).async {
        guard let creds = shell("/usr/bin/security",
                                ["find-generic-password", "-s", "Claude Code-credentials", "-w"]).data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: creds) as? [String: Any],
              let oauth = json["claudeAiOauth"] as? [String: Any],
              let token = oauth["accessToken"] as? String,
              let url = URL(string: "https://api.anthropic.com/api/oauth/usage")
        else { return DispatchQueue.main.async { fetchFailed("claude", poll: CLAUDE_POLL) } }
        // default_claude_max_5x → Max 5x; no tier → the subscription's name
        let tier = (oauth["rateLimitTier"] as? String ?? "").components(separatedBy: "max_")
        let plan = tier.count == 2 ? "Max \(tier[1])" : (oauth["subscriptionType"] as? String ?? "").capitalized
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        URLSession.shared.dataTask(with: request) { data, response, error in
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            // limits: session, weekly, and weekly per model ("Fable"), in the endpoint's order
            let limits = ((data.flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any])?["limits"]
                as? [[String: Any]] ?? []).compactMap { l -> ClaudeLimit? in
                guard let used = l["percent"] as? Double, let group = l["group"] as? String else { return nil }
                let model = ((l["scope"] as? [String: Any])?["model"] as? [String: Any])?["display_name"] as? String
                return ClaudeLimit(name: model ?? group.capitalized, used: used,
                                   resets: (l["resets_at"] as? String).flatMap { iso.date(from: $0) })
            }
            guard let session = limits.first else {
                // 401: the token expired and nothing refreshed it (Claude Code
                // does on its next run) — a dot says so, unlike a 429 or no network
                let status = (response as? HTTPURLResponse)?.statusCode
                tlog("claude: no usage, HTTP \(status.map(String.init) ?? "-") \(error?.localizedDescription ?? "")")
                return DispatchQueue.main.async {
                    fetchFailed("claude", poll: CLAUDE_POLL)
                    set("claude") { $0.badge = status == 401 }
                }
            }
            DispatchQueue.main.async {
                claudeLimits = limits
                claudePlan = plan
                lastFetch["claude"] = Date()
                let worst = limits.map(\.used).max() ?? 0
                set("claude") {
                    $0.icon = "donut:\(session.used / 100)"
                    $0.iconColor = worst >= 90 ? \.red : worst >= 70 ? \.yellow : \.accent
                    $0.label = "\(Int(session.used))%"
                    $0.stale = false
                    $0.badge = false
                }
                if openPopup == "claude" { refreshPopup() }
            }
        }.resume()
    }
}

// 1h 49m, 2d 4h
func timeLeft(_ d: Date?) -> String {
    guard let d else { return "" }
    let m = max(0, Int(d.timeIntervalSinceNow / 60))
    return m >= 1440 ? "\(m / 1440)d \(m % 1440 / 60)h" : m >= 60 ? "\(m / 60)h \(m % 60)m" : "\(m)m"
}

func claudeRows() -> [PopupRow] {
    guard !claudeLimits.isEmpty else { return [] }
    let next = (lastFetch["claude"] ?? Date()).addingTimeInterval(CLAUDE_POLL).timeIntervalSinceNow
    return [PopupRow(width: 270, custom: AnyView(ClaudeCard(
        limits: claudeLimits, plan: claudePlan,
        next: "Next update in \(max(1, Int(ceil(next / 60))))m"
    )))]
}

// the "Priority" list: limits with room, the ones running out, the ones used up
struct ClaudeCard: View {
    let limits: [ClaudeLimit]
    let plan: String
    let next: String

    private func font(_ size: CGFloat, _ face: String = "Regular") -> Font { Font(nerdFont(face, size)) }

    var body: some View {
        let sections = [
            ("Claude", limits.filter { $0.used < 70 }),
            ("Running Out", limits.filter { $0.used >= 70 && $0.used < 100 }),
            ("Used Up", limits.filter { $0.used >= 100 }),
        ].filter { !$0.1.isEmpty }
        VStack(alignment: .leading, spacing: 4) {
            ForEach(sections, id: \.0) { title, rows in
                Text(verbatim: title).font(font(11, "Bold")).foregroundStyle(.secondary)
                    .opacity(title == "Used Up" ? 0.6 : 1)
                    .padding(.top, 6)
                ForEach(Array(rows.enumerated()), id: \.offset) { _, l in
                    if l.used >= 100 { usedUp(l) } else { row(l) }
                }
            }
            Divider().padding(.top, 6)
            HStack {
                Text(verbatim: next).font(font(12)).foregroundStyle(.secondary)
                Spacer()
                Button {
                    NSWorkspace.shared.open(URL(string: "https://claude.ai/settings/usage")!)
                    closePopup()
                } label: {
                    Image(systemName: "ellipsis").font(.system(size: 12, weight: .bold))
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(.primary.opacity(0.08)))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help("usage settings")
            }
            .padding(.vertical, 2)
        }
        .padding(.horizontal, 8)
    }

    private func row(_ l: ClaudeLimit) -> some View {
        let left = 100 - l.used
        let ring = Color(nsColor: l.used >= 70 ? palette.orange : palette.accent)
        return HStack(spacing: 10) {
            ZStack {
                Circle().stroke(.primary.opacity(0.1), lineWidth: 3)
                Circle().trim(from: 0, to: left / 100)
                    .stroke(ring, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                ClaudeMark().frame(width: 13, height: 13)
            }
            .frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: l.name).font(font(13)).lineLimit(1)
                Text(verbatim: plan).font(font(11)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 1) {
                Text(verbatim: "\(Int(left))% left").font(font(13)).monospacedDigit()
                Text(verbatim: timeLeft(l.resets)).font(font(11)).monospacedDigit().foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func usedUp(_ l: ClaudeLimit) -> some View {
        HStack(spacing: 8) {
            ClaudeMark().frame(width: 12, height: 12).opacity(0.5)
            Text(verbatim: l.name).font(font(13))
            Text(verbatim: plan).font(font(10))
            Spacer()
            Text(verbatim: timeLeft(l.resets)).font(font(12)).monospacedDigit()
        }
        .foregroundStyle(.secondary)
        .padding(.vertical, 3)
    }
}

// Claude's starburst: six capsules crossed into twelve rays
struct ClaudeMark: View {
    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                Capsule().frame(width: 2).rotationEffect(.degrees(Double(i) * 30))
            }
        }
        .foregroundStyle(Color(red: 0.85, green: 0.47, blue: 0.34))
    }
}
