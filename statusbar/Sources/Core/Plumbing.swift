import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

// --- plumbing -------------------------------------------------------------

// OmniWM, the one window manager this bar speaks to. The running-app
// check is an in-process lookup, cheap enough to be the whole detection.
let omniwmBundleID = "com.barut.OmniWM"

func omniwmActive() -> Bool {
    !NSRunningApplication.runningApplications(withBundleIdentifier: omniwmBundleID).isEmpty
}

let omniwmctlBin = ["/opt/homebrew/bin/omniwmctl",
                    "/Applications/OmniWM.app/Contents/MacOS/omniwmctl"]
    .first { FileManager.default.isExecutableFile(atPath: $0) } ?? "omniwmctl"

@discardableResult
func omniwmctl(_ args: [String]) -> String { shell(omniwmctlBin, args) }

// One query, unwrapped to its payload. The CLI prints the whole
// IPCResponse envelope; everything the bar wants lives two levels down
// at result.payload (OmniWM docs/IPC-CLI.md, "Response Format").
func omniQuery(_ name: String, _ args: [String] = []) -> [String: Any]? {
    let out = omniwmctl(["query", name] + args + ["--format", "json"])
    guard let data = out.data(using: .utf8),
          let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          (root["ok"] as? Bool) == true,
          let result = root["result"] as? [String: Any]
    else { return nil }
    return result["payload"] as? [String: Any]
}

// click-to-jump. OmniWM's focus-name resolves
// a numeric raw workspace ID across all monitors, which is exactly what a
// chip on either display means.
func focusWindow(_ id: String) { omniwmctl(["window", "focus", id]) }

func focusWorkspace(_ ws: String) { omniwmctl(["workspace", "focus-name", ws]) }

// one append-mode descriptor for the daemon's life: no open/close per line
let logHandle: FileHandle = {
    let fd = open("/tmp/statusbar.log", O_WRONLY | O_APPEND | O_CREAT, 0o644)
    return fd >= 0 ? FileHandle(fileDescriptor: fd, closeOnDealloc: true) : .nullDevice
}()
func tlog(_ m: String) {
    // ponytail: start over past 1 MB; /tmp only empties on reboot
    if logHandle.offsetInFile > 1_000_000 { try? logHandle.truncate(atOffset: 0) }
    logHandle.write("\(Date()) \(m)\n".data(using: .utf8)!)
}

// Optional chip icons, ~/.config/statusbar/workspace-icons.conf:
//   1 = com.apple.Safari      an app's icon, by bundle id
//   2 = 󰊯                      a single glyph
// A workspace "12" with no line of its own uses "2"'s. Missing file = digits.
enum WorkspaceIcon { case glyph(String), image(NSImage) }
let workspaceIcons: [String: WorkspaceIcon] = {
    let path = NSHomeDirectory() + "/.config/statusbar/workspace-icons.conf"
    guard let text = try? String(contentsOfFile: path, encoding: .utf8) else { return [:] }
    var icons: [String: WorkspaceIcon] = [:]
    for line in text.split(separator: "\n") where !line.hasPrefix("#") {
        let kv = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        guard kv.count == 2, !kv[1].isEmpty else { continue }
        if kv[1].count == 1 {
            icons[kv[0]] = .glyph(kv[1])
        } else if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: kv[1]) {
            icons[kv[0]] = .image(NSWorkspace.shared.icon(forFile: url.path))
        } else {
            tlog("workspace-icons: \(kv[0]): no app \(kv[1])")
        }
    }
    return icons
}()
func workspaceIcon(_ ws: String) -> WorkspaceIcon? { workspaceIcons[ws] ?? ws.last.flatMap { workspaceIcons[String($0)] } }
