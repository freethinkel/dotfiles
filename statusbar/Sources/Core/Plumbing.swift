import AppKit

// --- plumbing -------------------------------------------------------------

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
// Missing file = digits.
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
func workspaceIcon(_ ws: String) -> WorkspaceIcon? { workspaceIcons[ws] }
