import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

// --- theme: themes/ via the ~/.config/themes link, `theme set` does the rest
let THEMES_DIR = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/themes").resolvingSymlinksInPath()

func currentTheme() -> String {
    let f = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/theme/.current")
    return ((try? String(contentsOf: f, encoding: .utf8)) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
}

func updateTheme() { set("theme") { $0.icon = "sf:paintpalette.fill"; $0.iconColor = nil; $0.label = "" } }

func themeRows() -> [PopupRow] {
    let names = ((try? FileManager.default.contentsOfDirectory(atPath: THEMES_DIR.path)) ?? [])
        .filter { FileManager.default.fileExists(atPath: THEMES_DIR.appendingPathComponent("\($0)/colors.toml").path) }
        .map { ($0, themePreview(THEMES_DIR.appendingPathComponent($0))) }
        .sorted { ($0.1.0 ? 0 : 1, $0.0) < ($1.1.0 ? 0 : 1, $1.0) } // light first, then by name
    let current = currentTheme()
    var rows = [PopupRow(text: "theme", hero: true)]
    let bin = THEMES_DIR.deletingLastPathComponent().appendingPathComponent("bin/theme").path
    for (name, (light, swatches)) in names {
        rows.append(PopupRow(icon: light ? "sf:sun.max.fill" : "sf:moon.fill", text: name,
                             swatches: swatches, highlight: name == current, action: {
            closePopup()
            // login shell: launchd's PATH lacks brew, which theme-apply's reloads need
            DispatchQueue.global(qos: .userInitiated).async { _ = shell("/bin/zsh", ["-lc", "\"$0\" set \"$1\"", bin, name]) }
        }))
    }
    return rows
}

// light?, then bg / fg / accent / red — same picks as `theme set`'s fzf rows
func themePreview(_ dir: URL) -> (Bool, [NSColor]) {
    let text = (try? String(contentsOf: dir.appendingPathComponent("colors.toml"), encoding: .utf8)) ?? ""
    var colors: [String: NSColor] = [:]
    var light = FileManager.default.fileExists(atPath: dir.appendingPathComponent("light.mode").path)
    for line in text.split(separator: "\n") {
        let parts = line.split(separator: "=", maxSplits: 1)
        guard parts.count == 2 else { continue }
        let key = parts[0].trimmingCharacters(in: .whitespaces)
        let value = parts[1].trimmingCharacters(in: CharacterSet(charactersIn: " \"'"))
        if key == "mode" && value.hasPrefix("light") { light = true }
        guard value.hasPrefix("#"), value.count >= 7,
              let v = UInt64(value.dropFirst().prefix(6), radix: 16) else { continue }
        colors[key] = color(fromARGB: 0xff00_0000 | v)
    }
    let picks = [["background"], ["foreground"], ["accent", "blue", "color4"], ["color1", "red"]]
    return (light, picks.compactMap { $0.lazy.compactMap { colors[$0] }.first })
}
