// statusbar — a native bar surface, in ONE process.
//
// SLICE: workspace chips + front-app pill, on the built-in display only,
// drawn over sketchybar's own bar so the two can be watched side by side
// (sketchybar keeps the external display). This exists to answer one
// question with numbers rather than opinion: how much of the bar's
// latency is the work, and how much is the process boundaries?
//
// The shape of the answer is in the data flow. sketchybar learns that a
// workspace changed, forks a shell script, and that script spawns several
// WM CLI calls to ask what happened before a pixel moves. This daemon already holds the window model in
// memory, fed by the same SkyLight notifications the other daemons use,
// so a workspace switch touches no subprocess at all: update one field,
// draw one frame. The slow path (which windows exist, where) runs only
// on window create/destroy, off the critical path.
//
// Timings land in /tmp/statusbar.log as `switch <ws> <ms>`.
//
// The right cluster is the same eight pills the bar already carries, but
// reading their sources directly instead of forking a script that forks
// `pmset`, `osascript`, `networksetup` and `ipconfig`: IOPS for power,
// CoreAudio for volume, DisplayServices for brightness, SCDynamicStore
// for the network, IOBluetooth for devices. Every one of those is a
// publisher, so nothing here polls except the clock and the weather,
// which have no publisher to listen to.
import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreBluetooth
import CoreLocation
import CoreWLAN
import IOBluetooth
import IOKit.ps
import SystemConfiguration
import UniformTypeIdentifiers

// --- config ---------------------------------------------------------------
// Tunables live here; everything else derives from them.

let FONT_FAMILY = "IoskeleyMonoNL Nerd Font Mono"

// geometry (pt)
let BAR_HEIGHT: CGFloat = 34
let PILL_HEIGHT: CGFloat = 26     // hit/draw box of every item
let PAD_LEFT: CGFloat = 10        // outer edge padding, both ends
let GAP: CGFloat = 14             // between the left-cluster groups
let ITEM_GAP: CGFloat = 2         // between right-cluster items
let ITEM_PAD: CGFloat = 10        // inside a right-cluster item, each side
let RADIUS: CGFloat = 4           // active-workspace / focus plates
let CHIP_BOX: CGFloat = 20        // workspace label box
let CHIP_PAD: CGFloat = 2
let CHIP_GAP: CGFloat = 4         // between workspace chips
let APP_ICON_SIZE: CGFloat = 20
let ICON_SIZE: CGFloat = 16
let ICON_GAP: CGFloat = 4         // icon to label, right-cluster items       // bar glyphs; "sf:" icons are SF Symbols at this point size
let APP_ICON_GAP: CGFloat = 2

// popups
let ROW_HEIGHT: CGFloat = 26
let POPUP_PAD: CGFloat = 8
let POPUP_RADIUS: CGFloat = 8
let CELL_PAD: CGFloat = 14        // table cells: added to the widest cell of a column

// right cluster, screen order left to right
let RIGHT_ITEMS = ["claude", "weather", "tailscale", "layout", "brightness", "volume", "battery", "clock", "activity"]

// above app windows, one below the native menu bar: with the menu bar on
// auto-hide it slides in OVER the bar when the pointer hits the top edge
let BAR_LEVEL = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue - 1)

// polling (s) — only for sources with no publisher
let WEATHER_POLL: TimeInterval = 1800
let TAILSCALE_POLL: TimeInterval = 15
let TAILSCALE_CLI = "/usr/local/bin/tailscale"
let CLAUDE_POLL: TimeInterval = 300

// DisplayServices (private) — the same calls Control Center makes, and
// the brightness keys go through.
@_silgen_name("DisplayServicesGetBrightness")
func DSGetBrightness(_ display: CGDirectDisplayID, _ value: UnsafeMutablePointer<Float>) -> Int32
@_silgen_name("DisplayServicesSetBrightness")
func DSSetBrightness(_ display: CGDirectDisplayID, _ value: Float) -> Int32

// Brightness has a publisher after all. The callback's later arguments
// are deliberately untyped and never dereferenced: the arity is what the
// ABI needs, the contents are not ours to trust.
typealias DSBrightnessProc = @convention(c) (UnsafeRawPointer?, CGDirectDisplayID, UnsafeRawPointer?, UnsafeRawPointer?) -> Void
@_silgen_name("DisplayServicesRegisterForBrightnessChangeNotifications")
func DSRegisterBrightnessNotifications(_ display: CGDirectDisplayID, _ context: UnsafeMutableRawPointer?, _ callback: DSBrightnessProc) -> Int32

@_silgen_name("IOBluetoothPreferenceGetControllerPowerState")
func BTGetPower() -> Int32

// --- SkyLight window events (borders.swift recipe) ------------------------

typealias NotifyProc = @convention(c) (UInt32, UnsafeMutableRawPointer?, Int, UnsafeMutableRawPointer?) -> Void

@_silgen_name("SLSMainConnectionID")
func SLSMainConnectionID() -> Int32
@_silgen_name("SLSRequestNotificationsForWindows")
func SLSRequestNotificationsForWindows(_ cid: Int32, _ windows: UnsafePointer<UInt32>, _ count: Int32) -> CGError
@_silgen_name("SLSRegisterNotifyProc")
func SLSRegisterNotifyProc(_ proc: NotifyProc, _ event: UInt32, _ context: UnsafeMutableRawPointer?) -> CGError
@_silgen_name("SLSGetEventPort")
func SLSGetEventPort(_ cid: Int32, _ port: UnsafeMutablePointer<mach_port_t>) -> CGError
@_silgen_name("SLEventCreateNextEvent")
func SLEventCreateNextEvent(_ cid: Int32) -> Unmanaged<CGEvent>?

let EVENT_WINDOW_MOVE: UInt32 = 806
let EVENT_WINDOW_RESIZE: UInt32 = 807
// Sending a window to another workspace ORDERS IT OUT, it does not move
// it: measured with a SkyLight probe, a workspace switch fires
// 806/808/815 but a window changing workspace fires only 808 and 815.
// Watching 806 for that is why the chips sat stale until some unrelated
// app next opened a window. They arrive as a pair; both are watched
// because the pairing is observed behaviour, not a documented promise.
let EVENT_WINDOW_ORDER: UInt32 = 808
let EVENT_WINDOW_VISIBILITY: UInt32 = 815
let EVENT_WINDOW_CREATE: UInt32 = 1325
let EVENT_WINDOW_DESTROY: UInt32 = 1326

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

let logURL = URL(fileURLWithPath: "/tmp/statusbar.log")
func tlog(_ m: String) {
    let line = "\(Date()) \(m)\n"
    if let h = try? FileHandle(forWritingTo: logURL) {
        h.seekToEndOfFile()
        h.write(line.data(using: .utf8)!)
        try? h.close()
    } else {
        try? line.data(using: .utf8)!.write(to: logURL)
    }
}

private struct BundleIdentifier {
    let rawValue: String

    init?(_ rawValue: String) {
        let segments = rawValue.split(separator: ".", omittingEmptySubsequences: false)
        guard segments.count >= 2,
              segments.allSatisfy({ segment in
                  guard let first = segment.unicodeScalars.first,
                        BundleIdentifier.isAlphanumeric(first) else { return false }
                  return segment.unicodeScalars.allSatisfy(BundleIdentifier.isAlphanumericOrHyphen)
              })
        else { return nil }
        self.rawValue = rawValue
    }

    private static func isAlphanumeric(_ scalar: UnicodeScalar) -> Bool {
        (48...57).contains(scalar.value) || (65...90).contains(scalar.value)
            || (97...122).contains(scalar.value)
    }

    private static func isAlphanumericOrHyphen(_ scalar: UnicodeScalar) -> Bool {
        isAlphanumeric(scalar) || scalar.value == 45
    }
}

private enum WorkspaceIcon {
    case glyph(String)
    case image(NSImage)
    case unavailable
}

private enum WorkspaceIconDeclaration {
    case glyph(String)
    case bundle(BundleIdentifier)
}

private struct WorkspaceIconConfig {
    let values: [String: WorkspaceIcon]

    func icon(for workspace: String) -> WorkspaceIcon? {
        if let icon = values[workspace] { return icon }
        guard workspace.count > 1,
              workspace.unicodeScalars.allSatisfy({ (48...57).contains($0.value) }),
              let last = workspace.unicodeScalars.last,
              (49...57).contains(last.value)
        else { return nil }
        return values[String(Character(last))]
    }
}

private func loadWorkspaceIconConfig() -> WorkspaceIconConfig {
    let file = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/statusbar/workspace-icons.conf")
    guard FileManager.default.fileExists(atPath: file.path) else {
        return WorkspaceIconConfig(values: [:])
    }
    guard let text = try? String(contentsOf: file, encoding: .utf8) else {
        tlog("workspace-icons: could not read \(file.path)")
        return WorkspaceIconConfig(values: [:])
    }

    var declarations: [String: WorkspaceIconDeclaration] = [:]
    for (offset, rawLine) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
        let lineNumber = offset + 1
        let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty, !line.hasPrefix("#") else { continue }
        guard let separator = line.firstIndex(of: "=") else {
            tlog("workspace-icons: malformed line \(lineNumber)")
            continue
        }
        let key = String(line[..<separator]).trimmingCharacters(in: .whitespacesAndNewlines)
        let value = String(line[line.index(after: separator)...]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, !value.isEmpty else {
            tlog("workspace-icons: malformed line \(lineNumber)")
            continue
        }

        let declaration: WorkspaceIconDeclaration?
        if let bundle = BundleIdentifier(value) {
            declaration = .bundle(bundle)
        } else if value.unicodeScalars.count == 1 {
            declaration = .glyph(value)
        } else {
            declaration = nil
        }
        guard let declaration else {
            tlog("workspace-icons: malformed line \(lineNumber)")
            continue
        }
        if declarations[key] != nil {
            tlog("workspace-icons: duplicate \(key) on line \(lineNumber), last valid value wins")
        }
        declarations[key] = declaration
    }

    var values: [String: WorkspaceIcon] = [:]
    for (key, declaration) in declarations {
        switch declaration {
        case .glyph(let glyph):
            values[key] = .glyph(glyph)
        case .bundle(let identifier):
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier.rawValue) else {
                tlog("workspace-icons: \(key) could not resolve \(identifier.rawValue)")
                values[key] = .unavailable
                continue
            }
            values[key] = .image(NSWorkspace.shared.icon(forFile: url.path))
        }
    }
    return WorkspaceIconConfig(values: values)
}

private let workspaceIconConfig = loadWorkspaceIconConfig()

// --- theme ----------------------------------------------------------------
// The same palette sketchybar reads. Parsed once and kept as colours, not
// re-sourced per item by sixteen shell scripts.

struct Palette {
    var itemBG = NSColor.black
    var accent = NSColor.systemBlue
    var label = NSColor.white
    var muted = NSColor.gray
    var barBG = NSColor.black
    var red = NSColor.systemRed
    var green = NSColor.systemGreen
    var yellow = NSColor.systemYellow
}

func color(fromARGB v: UInt64) -> NSColor {
    NSColor(srgbRed: CGFloat((v >> 16) & 0xff) / 255,
            green: CGFloat((v >> 8) & 0xff) / 255,
            blue: CGFloat(v & 0xff) / 255,
            alpha: CGFloat((v >> 24) & 0xff) / 255)
}

func loadPalette() -> Palette {
    var p = Palette()
    let file = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/theme/bar.sh") // rendered from themes/templates/bar.sh.tpl
    guard let text = try? String(contentsOf: file, encoding: .utf8) else { return p }
    for line in text.split(separator: "\n") {
        let parts = line.replacingOccurrences(of: "export ", with: "").split(separator: "=")
        guard parts.count == 2, parts[1].hasPrefix("0x"),
              let v = UInt64(parts[1].dropFirst(2), radix: 16) else { continue }
        switch parts[0] {
        case "ITEM_BG": p.itemBG = color(fromARGB: v)
        case "ACCENT": p.accent = color(fromARGB: v)
        case "LABEL_COLOR": p.label = color(fromARGB: v)
        case "MUTED": p.muted = color(fromARGB: v)
        case "BAR_BG_SOLID": p.barBG = color(fromARGB: v)
        case "RED": p.red = color(fromARGB: v)
        case "GREEN": p.green = color(fromARGB: v)
        case "YELLOW": p.yellow = color(fromARGB: v)
        default: break
        }
    }
    return p
}

// Ask for the family by name and VERIFY we got it. sketchybar's
// `--default` silently handed half the bar "Hack Nerd Font", which is not
// installed, so the text fell back to a system face and nothing said so.
// A missing family is a loud fallback here, once, at startup.
func nerdFont(_ face: String, _ size: CGFloat) -> NSFont {
    let desc = NSFontDescriptor(fontAttributes: [
        .family: FONT_FAMILY,
        .face: face,
    ])
    if let f = NSFont(descriptor: desc, size: size), f.familyName == FONT_FAMILY {
        return f
    }
    tlog("font: \(FONT_FAMILY) \(face) unavailable — using system mono")
    return .monospacedSystemFont(ofSize: size, weight: face == "Bold" ? .bold : .semibold)
}

// --- model ----------------------------------------------------------------

// Shared across every display: which workspace has focus, what the front
// app is, which workspaces hold what. Anything that differs per screen —
// the workspace set, the visible one, the notch — belongs to the surface.
// a window as the chips see it: whose icon, how to focus it, whether it has focus
struct BarWin: Equatable {
    var app: String
    var id: String
    var focused = false
}

final class Model {
    var focused = "" // globally focused workspace
    var apps: [String: [BarWin]] = [:] // ws -> one entry per window, OmniWM-bar style
    var occupied: Set<String> = []
    var frontApp = ""
    var media = Media()
}

struct Media: Equatable {
    var running = false
    var playing = false
    var title = ""
}

let model = Model()
var palette = loadPalette()

// SLOW path: who lives where. Three CLI calls — and it runs only when a
// window is created or destroyed, never on a workspace switch.
//
// It is computed OFF the main queue and applied on it. Measured the hard
// way: with the CLI calls inline on main, one contended rebuild blocked
// the render path for 7.6 seconds and every switch queued behind it. The
// architecture only pays off if subprocess work never sits on the path a
// frame has to travel.
struct Snapshot {
    var perMonitor: [String: (workspaces: [String], visible: String)] = [:]
    var apps: [String: [BarWin]] = [:]
    var occupied: Set<String> = []
    var focused = ""
}

let rebuildQueue = DispatchQueue(label: "com.freethinkel.statusbar.rebuild")

func fetchSnapshot() -> Snapshot { omniwmSnapshot() }

// Two omniwmctl queries: workspaces arrive with their display and visibility in one query, and
// the windows query brings the app names the sole-app chips need. The
// snapshot also carries focus; the watch stream below covers the fast path.
func omniwmSnapshot() -> Snapshot {
    var s = Snapshot()
    var sets: [String: [String]] = [:]
    var visible: [String: String] = [:]
    if let list = omniQuery("workspaces",
                            ["--fields", "raw-name,display"])?["workspaces"]
        as? [[String: Any]] {
        for w in list {
            guard let name = w["rawName"] as? String,
                  let monitor = (w["display"] as? [String: Any])?["id"] as? String else { continue }
            sets[monitor, default: []].append(name)
        }
    }
    // visible/focused come from the DISPLAYS query: the workspaces
    // query's isVisible/isFocused go dark on EMPTY workspaces (the
    // same trap every workspace script hits), and the pill for a focused empty 8/9
    // never lit up
    if let displays = omniQuery("displays", [])?["displays"] as? [[String: Any]] {
        for d in displays {
            guard let id = d["id"] as? String,
                  let active = (d["activeWorkspace"] as? [String: Any])?["rawName"] as? String
            else { continue }
            visible[id] = active
            if (d["isCurrent"] as? Bool) == true { s.focused = active }
        }
    }
    for id in surfaces.map({ $0.monitorID }) {
        s.perMonitor[id] = (sets[id] ?? [], visible[id] ?? "")
    }

    if let list = omniQuery("windows", ["--fields", "id,workspace,app,mode,is-focused"])?["windows"]
        as? [[String: Any]] {
        for w in list {
            guard let ws = (w["workspace"] as? [String: Any])?["rawName"] as? String,
                  let app = (w["app"] as? [String: Any])?["name"] as? String,
                  let id = w["id"] as? String else { continue }
            guard (w["mode"] as? String) != "floating" else { continue }
            s.occupied.insert(ws)
            s.apps[ws, default: []].append(BarWin(app: app, id: id, focused: (w["isFocused"] as? Bool) == true))
        }
    }
    return s
}

// Reports whether anything actually moved. A workspace switch produces
// window moves too, and those snapshots come back identical — saying so
// keeps the repaint (and the log line) for the times something changed.
@discardableResult
func apply(_ s: Snapshot) -> Bool {
    var changed = false
    for surface in surfaces {
        guard let part = s.perMonitor[surface.monitorID] else { continue }
        if !part.workspaces.isEmpty, surface.workspaces != part.workspaces {
            surface.workspaces = part.workspaces
            surface.mine = Set(part.workspaces)
            changed = true
        }
        if !part.visible.isEmpty, surface.visible != part.visible {
            surface.visible = part.visible
            changed = true
        }
    }
    if model.occupied != s.occupied { model.occupied = s.occupied; changed = true }
    if model.apps != s.apps { model.apps = s.apps; changed = true }
    if !s.focused.isEmpty, model.focused != s.focused {
        tlog("focused \(s.focused) (snapshot)")
        model.focused = s.focused
        changed = true
    }
    return changed
}


// FAST path: a workspace switch changes focus and nothing else. No CLI,
// no IPC, no shell — every surface already knows the rest, and the one
// that owns the workspace also now shows it.
func setFocused(_ ws: String) {
    model.focused = ws
    for surface in surfaces where surface.mine.contains(ws) { surface.visible = ws }
}

// --- media (Spotify announces itself; the title needs no subprocess) -------
// media.sh spawns osascript to ask what is playing. Spotify's own
// PlaybackStateChanged notification already carries Name, Artist and
// Player State, so the only subprocess left is the one a click sends —
// and that is user-initiated, where 20 ms does not show.

let spotifyBundleID = "com.spotify.client"

func spotifyRunning() -> Bool {
    !NSRunningApplication.runningApplications(withBundleIdentifier: spotifyBundleID).isEmpty
}

func updateMedia(from info: [AnyHashable: Any]? = nil) {
    var next = Media()
    next.running = spotifyRunning()
    if next.running {
        if let info {
            next.playing = (info["Player State"] as? String) == "Playing"
            let name = info["Name"] as? String ?? ""
            let artist = info["Artist"] as? String ?? ""
            next.title = artist.isEmpty ? name : "\(artist) — \(name)"
        } else {
            next.title = model.media.title
            next.playing = model.media.playing
        }
    }
    guard next != model.media else { return }
    let t0 = DispatchTime.now().uptimeNanoseconds
    model.media = next
    repaint()
    tlog(String(format: "media %@ %@ %.2f ms", next.playing ? "play" : "pause", next.title,
                Double(DispatchTime.now().uptimeNanoseconds - t0) / 1_000_000))
}

// startup only: the notification fires on change, so the current track
// has to be asked for once
func primeMedia() {
    guard spotifyRunning() else { return }
    rebuildQueue.async {
        let script = """
        tell application "Spotify" to if it is running then \
        return (player state as text) & "|" & artist of current track & "|" & name of current track
        """
        let out = shell("/usr/bin/osascript", ["-e", script])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = out.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 3 else { return }
        DispatchQueue.main.async {
            model.media = Media(running: true, playing: parts[0] == "playing",
                                title: parts[1].isEmpty ? parts[2] : "\(parts[1]) — \(parts[2])")
            repaint()
        }
    }
}

func spotify(_ command: String) {
    DispatchQueue.global(qos: .userInitiated).async {
        _ = shell("/usr/bin/osascript", ["-e", "tell application \"Spotify\" to \(command)"])
    }
}

// --- right cluster ---------------------------------------------------------
// An item is data. Layout, hit-testing and drawing are generic over the
// list, so adding a pill is one entry and one provider — no per-item
// geometry, no padding arithmetic, no width caches.

struct BarItem: Equatable {
    var icon = ""
    var label = ""
    // which palette colour, not a copy of it: read when drawing, so a
    // theme switch recolours every pill in the repaint it already does
    var iconColor: KeyPath<Palette, NSColor>?
    var drawing = true
}

var rightItems: [String: BarItem] = [:]

func set(_ name: String, _ mutate: (inout BarItem) -> Void) {
    var item = rightItems[name] ?? BarItem()
    mutate(&item)
    guard item != rightItems[name] else { return } // no pixels owed
    let t0 = DispatchTime.now().uptimeNanoseconds
    rightItems[name] = item
    repaint()
    // an open popup shows the same state as its pill — the brightness
    // popup kept whatever value it was built with while the pill moved
    if openPopup == name { refreshPopup() }
    tlog(String(format: "item %@ %.2f ms", name, Double(DispatchTime.now().uptimeNanoseconds - t0) / 1_000_000))
}

func shell(_ launch: String, _ args: [String]) -> String {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: launch)
    p.arguments = args
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = FileHandle.nullDevice
    guard (try? p.run()) != nil else { return "" }
    let out = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return String(data: out, encoding: .utf8) ?? ""
}

// --- clock (no publisher: the one honest timer, aligned to the minute)
func updateClock() {
    let f = DateFormatter()
    f.dateFormat = "dd.MM.yyyy HH:mm"
    set("clock") { $0.icon = "sf:calendar"; $0.label = f.string(from: Date()) }
}

// --- battery (IOPS publishes, capacity ticks included)
func updateBattery() {
    guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
          let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef]
    else { return }
    for source in list {
        guard let d = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any],
              let cur = d[kIOPSCurrentCapacityKey] as? Int else { continue }
        let max = d[kIOPSMaxCapacityKey] as? Int ?? 100
        let pct = max > 0 ? Int((Double(cur) / Double(max) * 100).rounded()) : cur
        let charging = (d[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
        // same thresholds and glyphs the bar already uses
        var icon = "sf:battery.0percent", color: KeyPath<Palette, NSColor> = \.red
        switch pct {
        case 90...: icon = "sf:battery.100percent"; color = \.green
        case 60..<90: icon = "sf:battery.75percent"; color = \.label
        case 30..<60: icon = "sf:battery.50percent"; color = \.label
        case 10..<30: icon = "sf:battery.25percent"; color = \.yellow
        default: break
        }
        if charging { icon = "sf:battery.100percent.bolt"; color = \.green }
        set("battery") { $0.icon = icon; $0.iconColor = color; $0.label = "\(pct)%" }
        return
    }
}

// --- volume (CoreAudio publishes on the device itself)
func defaultOutputDevice() -> AudioDeviceID {
    var addr = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                                          mScope: kAudioObjectPropertyScopeGlobal,
                                          mElement: kAudioObjectPropertyElementMain)
    var id = AudioDeviceID(0)
    var size = UInt32(MemoryLayout<AudioDeviceID>.size)
    AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &id)
    return id
}

func volumeAddress(_ element: UInt32) -> AudioObjectPropertyAddress {
    AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyVolumeScalar,
                               mScope: kAudioDevicePropertyScopeOutput, mElement: element)
}

func readVolume() -> (percent: Int, muted: Bool)? {
    let dev = defaultOutputDevice()
    guard dev != 0 else { return nil }

    var muted: UInt32 = 0
    var muteAddr = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyMute,
                                              mScope: kAudioDevicePropertyScopeOutput,
                                              mElement: kAudioObjectPropertyElementMain)
    var muteSize = UInt32(MemoryLayout<UInt32>.size)
    AudioObjectGetPropertyData(dev, &muteAddr, 0, nil, &muteSize, &muted)

    var level: Float32 = 0
    var addr = volumeAddress(kAudioObjectPropertyElementMain)
    var size = UInt32(MemoryLayout<Float32>.size)
    if AudioObjectGetPropertyData(dev, &addr, 0, nil, &size, &level) != noErr {
        // a device without a master channel: average the stereo pair
        var sum: Float32 = 0
        var found = 0
        for channel in UInt32(1)...UInt32(2) {
            var chAddr = volumeAddress(channel)
            var chSize = UInt32(MemoryLayout<Float32>.size)
            var value: Float32 = 0
            if AudioObjectGetPropertyData(dev, &chAddr, 0, nil, &chSize, &value) == noErr {
                sum += value
                found += 1
            }
        }
        guard found > 0 else { return nil }
        level = sum / Float32(found)
    }
    return (Int((level * 100).rounded()), muted != 0)
}

func writeVolume(_ percent: Int) {
    let dev = defaultOutputDevice()
    guard dev != 0 else { return }
    var value = Float32(min(100, max(0, percent))) / 100
    let size = UInt32(MemoryLayout<Float32>.size)
    var addr = volumeAddress(kAudioObjectPropertyElementMain)
    if AudioObjectSetPropertyData(dev, &addr, 0, nil, size, &value) != noErr {
        for channel in UInt32(1)...UInt32(2) {
            var chAddr = volumeAddress(channel)
            AudioObjectSetPropertyData(dev, &chAddr, 0, nil, size, &value)
        }
    }
}

// the output devices the volume popup lists — the same enumeration
// Sound settings lists
func audioOutputDevices() -> [(id: AudioDeviceID, name: String)] {
    var addr = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
                                          mScope: kAudioObjectPropertyScopeGlobal,
                                          mElement: kAudioObjectPropertyElementMain)
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size) == noErr
    else { return [] }
    var ids = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
    guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &ids) == noErr
    else { return [] }

    var result: [(AudioDeviceID, String)] = []
    for id in ids {
        // output-capable only: a device with no output streams is a mic
        var streams = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreams,
                                                 mScope: kAudioDevicePropertyScopeOutput,
                                                 mElement: kAudioObjectPropertyElementMain)
        var streamSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(id, &streams, 0, nil, &streamSize) == noErr, streamSize > 0
        else { continue }

        var nameAddr = AudioObjectPropertyAddress(mSelector: kAudioObjectPropertyName,
                                                  mScope: kAudioObjectPropertyScopeGlobal,
                                                  mElement: kAudioObjectPropertyElementMain)
        var name: CFString = "" as CFString
        var nameSize = UInt32(MemoryLayout<CFString>.size)
        var ok = false
        withUnsafeMutablePointer(to: &name) { ptr in
            ok = AudioObjectGetPropertyData(id, &nameAddr, 0, nil, &nameSize, ptr) == noErr
        }
        guard ok else { continue }
        result.append((id, name as String))
    }
    return result
}

func setDefaultOutputDevice(_ id: AudioDeviceID) {
    var addr = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                                          mScope: kAudioObjectPropertyScopeGlobal,
                                          mElement: kAudioObjectPropertyElementMain)
    var dev = id
    AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil,
                               UInt32(MemoryLayout<AudioDeviceID>.size), &dev)
}

func updateVolume() {
    guard let v = readVolume() else { return }
    let icon: String
    if v.muted || v.percent == 0 {
        icon = "sf:speaker.slash.fill"
    } else if v.percent >= 70 {
        icon = "sf:speaker.wave.3.fill"
    } else if v.percent >= 30 {
        icon = "sf:speaker.wave.2.fill"
    } else {
        icon = "sf:speaker.wave.1.fill"
    }
    set("volume") { $0.icon = icon; $0.iconColor = nil; $0.label = v.muted ? "mute" : "\(v.percent)%" }
}

// --- shade (below the hardware minimum, without an overlay window) -------
// QuickShade and friends float a translucent black window over everything.
// That works, but the window is real: it sits in the z-order, it covers
// the bar, and it turns every screenshot black — including yours. Scaling
// the display's GAMMA instead dims at scanout, so there is no window, it
// applies over fullscreen apps, and captures come out normal.
//
// It also fails safe. Gamma set by a process is reset when that process
// exits (verified), so a crash or an uninstall restores the screen by
// itself and there is no way to be left staring at a dark display.
//
// Bonus: unlike DisplayServices this reaches EXTERNAL displays, which have
// no backlight API without DDC.
let shadeFile = "\(NSHomeDirectory())/.local/state/statusbar/shade"
let shadeFloor: Double = 0.15 // never darker than this fraction of output

var shade: Double = {
    guard let t = try? String(contentsOfFile: shadeFile, encoding: .utf8),
          let v = Double(t.trimmingCharacters(in: .whitespacesAndNewlines)) else { return 0 }
    return min(1, max(0, v))
}()

func applyShade() {
    let scale = Float(1 - shade * (1 - shadeFloor))
    var ids = [CGDirectDisplayID](repeating: 0, count: 8)
    var count: UInt32 = 0
    guard CGGetActiveDisplayList(8, &ids, &count) == .success else { return }
    for i in 0..<Int(count) {
        if shade <= 0.001 {
            CGDisplayRestoreColorSyncSettings()
        } else {
            CGSetDisplayTransferByFormula(ids[i], 0, scale, 1, 0, scale, 1, 0, scale, 1)
        }
    }
}

func setShade(_ value: Double) {
    shade = min(1, max(0, value))
    applyShade()
    try? String(format: "%.3f", shade).write(toFile: shadeFile, atomically: true, encoding: .utf8)
    updateBrightness()
}

// --- brightness (DisplayServices publishes; built-in panel only)
func builtinDisplayID() -> CGDirectDisplayID {
    var count: UInt32 = 0
    CGGetActiveDisplayList(0, nil, &count)
    var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
    CGGetActiveDisplayList(count, &ids, &count)
    return ids.first { CGDisplayIsBuiltin($0) != 0 } ?? CGMainDisplayID()
}

func updateBrightness() {
    var value: Float = 0
    guard DSGetBrightness(builtinDisplayID(), &value) == 0, value.isFinite else {
        set("brightness") { $0.drawing = false } // hide rather than lie
        return
    }
    let pct = Int((value * 100).rounded())
    // Shaded reads as BELOW zero, because that is what it is: past the
    // point the backlight can go. The moon says which side of zero you are on.
    if shade > 0.001 {
        set("brightness") {
            $0.drawing = true
            $0.icon = "sf:moon.fill"
            $0.iconColor = \.muted
            $0.label = "−\(Int((shade * 100).rounded()))%"
        }
        return
    }
    let icon = pct >= 66 ? "sf:sun.max.fill" : (pct >= 33 ? "sf:sun.min.fill" : "sf:sun.min")
    set("brightness") { $0.drawing = true; $0.icon = icon; $0.iconColor = nil; $0.label = "\(pct)%" }
}

// --- location (what the network name costs) -------------------------------
// macOS classes the SSID as location data. Two things are required and
// neither alone is enough: this grant, and a BUNDLED binary — measured,
// an unbundled build reads nil with authorisation held, services on and
// updates running, while a bundled one reads the name the instant the
// answer lands. The one coordinate read feeds the weather: wttr.in's IP
// geolocation lands wherever the VPN exit node is.
//
// Gated like bluetooth: TCC judges the RESPONSIBLE process, so only the
// launchd-started bar may prompt and running it by hand stays quiet.
final class LocationGate: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var managed: Bool { ProcessInfo.processInfo.environment["STATUSBAR_MANAGED"] != nil }

    func start() {
        manager.delegate = self
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorized:
            updateWifi() // the name is readable now; the pill may predate it
            manager.requestLocation()
        case .denied, .restricted:
            tlog("location: denied — the wi-fi pill stays nameless")
        default:
            guard managed else {
                tlog("location: not launchd-managed, so not prompting")
                return
            }
            manager.requestWhenInUseAuthorization()
        }
    }

    // the name appears the moment the answer lands — no restart, and no
    // polling for a permission that publishes
    func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        tlog("location: authorization now \(m.authorizationStatus.rawValue)")
        updateWifi()
        refresh()
    }

    // weather follows the machine, not the exit node; without a grant it
    // falls back to wttr.in's IP guess
    func refresh() {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorized: manager.requestLocation()
        default: updateWeather()
        }
    }

    func locationManager(_ m: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let c = locations.last?.coordinate else { return }
        weatherCoord = c
        updateWeather()
    }

    func locationManager(_ m: CLLocationManager, didFailWithError error: Error) {
        tlog("location: \(error.localizedDescription)")
        updateWeather() // last known coordinate, or the IP guess
    }
}
let locationGate = LocationGate()

// --- night shift (CBBlueLightClient publishes) ---------------------------
// Private CoreBrightness, reached by reflection. It has a publisher: setStatusNotificationBlock fires on
// every change whoever made it — the schedule, Control Center, System
// Settings, us. The popup used to cache what one subprocess printed
// the first time it opened, so anything that turned night shift off
// afterwards left the row reading yesterday's answer until the bar
// restarted.
struct BlueLightStatus {
    // `active` read true in every state measured here — toggle on and
    // off, inside and outside the schedule window — so the row reads
    // `enabled`, which is the field setEnabled: actually moves
    var active: ObjCBool = false
    var enabled: ObjCBool = false
    var sunSchedulePermitted: ObjCBool = false
    var mode: Int32 = 0
    var schedule: (Int32, Int32, Int32, Int32) = (0, 0, 0, 0)
    var disableFlags: UInt64 = 0
    var available: ObjCBool = false
}

let blueLight: (cls: NSObject.Type, client: NSObject)? = {
    guard dlopen("/System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness",
                 RTLD_LAZY) != nil,
        let cls = NSClassFromString("CBBlueLightClient") as? NSObject.Type
    else {
        tlog("CoreBrightness unavailable — no night shift row")
        return nil
    }
    return (cls, cls.init())
}()

func blueLightStatus() -> BlueLightStatus? {
    let sel = NSSelectorFromString("getBlueLightStatus:")
    guard let bl = blueLight, let m = class_getInstanceMethod(bl.cls, sel) else { return nil }
    typealias GetFn = @convention(c) (AnyObject, Selector, UnsafeMutableRawPointer) -> Bool
    let f = unsafeBitCast(method_getImplementation(m), to: GetFn.self)
    var st = BlueLightStatus()
    let ok = withUnsafeMutablePointer(to: &st) { f(bl.client, sel, UnsafeMutableRawPointer($0)) }
    return ok ? st : nil
}

func setNightShift(_ on: Bool) {
    let sel = NSSelectorFromString("setEnabled:")
    guard let bl = blueLight, let m = class_getInstanceMethod(bl.cls, sel) else { return }
    typealias SetFn = @convention(c) (AnyObject, Selector, Bool) -> Bool
    _ = unsafeBitCast(method_getImplementation(m), to: SetFn.self)(bl.client, sel, on)
}

// CoreBrightness keeps the block, so the block has to keep itself
var nightShiftBlock: (@convention(block) () -> Void)? = nil

func watchNightShift() {
    let sel = NSSelectorFromString("setStatusNotificationBlock:")
    guard let bl = blueLight, let m = class_getInstanceMethod(bl.cls, sel) else {
        tlog("night shift notifications unavailable — the row reads fresh on open only")
        return
    }
    let block: @convention(block) () -> Void = {
        DispatchQueue.main.async {
            guard let s = blueLightStatus() else { return }
            // which field a schedule boundary actually moves is worth
            // having in the log the morning after
            tlog("night shift changed: enabled=\(s.enabled.boolValue) "
                + "active=\(s.active.boolValue) mode=\(s.mode)")
            if openPopup == "brightness" { refreshPopup() }
        }
    }
    nightShiftBlock = block
    typealias SetFn = @convention(c) (AnyObject, Selector, Any) -> Void
    unsafeBitCast(method_getImplementation(m), to: SetFn.self)(bl.client, sel, block)
}

// --- wifi (SCDynamicStore publishes; SSID needs a subprocess, so it is
// fetched off-main and only when the network actually changed)
var wifiDevice = CWWiFiClient.shared().interface()?.interfaceName ?? "en0"

func updateWifi() {
    let powered = CWWiFiClient.shared().interface()?.powerOn() ?? false
    guard powered else {
        set("wifi") { $0.icon = "sf:wifi.slash"; $0.iconColor = nil; $0.label = "off" }
        return
    }
    // The name lives in the POPUP, not the pill: a seventeen-character
    // SSID is ~150pt of bar, and the right cluster is right-aligned, so
    // on the notched display it pushed the far end under the notch. The
    // icon says connected; a click says to what.
    set("wifi") { $0.icon = "sf:wifi"; $0.iconColor = nil; $0.label = "" }
}

// --- bluetooth (IOBluetooth publishes connect/disconnect)
//
// IOBluetooth ABORTS the process outright — SIGABRT, no exception to
// catch — if it is touched without the Bluetooth privacy grant. Learnt
// here the same way watcher.swift learnt it: exit code 134 and an empty
// log. So the grant is gated on CBCentralManager.authorization (reading
// that never prompts), and the pill simply stays hidden when it is not
// held. The binary carries helper/bar-info.plist for the usage string,
// without which the prompt cannot even be raised.
func updateBluetooth() {
    guard CBCentralManager.authorization == .allowedAlways else { return }
    guard BTGetPower() != 0 else {
        set("bluetooth") { $0.drawing = true; $0.icon = "bt"; $0.iconColor = \.muted; $0.label = "off" }
        return
    }
    let connected = ((IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice]) ?? [])
        .filter { $0.isConnected() }.count
    set("bluetooth") {
        $0.drawing = true
        $0.icon = "bt"
        $0.iconColor = nil
        $0.label = connected > 0 ? "\(connected)" : ""
    }
}

// IOBluetooth's connect/disconnect notifications are ObjC target/action,
// so they need a real object to aim at; CoreBluetooth's delegate is what
// tells us the grant has landed.
final class BluetoothWatcher: NSObject, CBCentralManagerDelegate {
    private var central: CBCentralManager?
    private var classicStarted = false

    // Creating a CBCentralManager is itself an access, and TCC judges it
    // by the RESPONSIBLE process rather than this binary: started from a
    // shell the whole process is killed (SIGABRT, exit 134, no report),
    // embedded Info.plist and signature notwithstanding. Under launchd it
    // is responsible for itself and may prompt — which is the only reason
    // watcher.swift could. The plist sets STATUSBAR_MANAGED so that running
    // this by hand for a test stays safe instead of dying.
    private var managed: Bool { ProcessInfo.processInfo.environment["STATUSBAR_MANAGED"] != nil }

    func start() {
        switch CBCentralManager.authorization {
        case .allowedAlways:
            startClassic()
            central = CBCentralManager(delegate: self, queue: .main)
        case .denied, .restricted:
            tlog("bluetooth: permission denied — pill hidden")
            set("bluetooth") { $0.drawing = false }
        default:
            guard managed else {
                tlog("bluetooth: not launchd-managed, so not prompting — pill hidden")
                set("bluetooth") { $0.drawing = false }
                return
            }
            set("bluetooth") { $0.drawing = false }
            central = CBCentralManager(delegate: self, queue: .main) // raises the prompt
        }
    }

    private func startClassic() {
        guard !classicStarted else { return }
        classicStarted = true
        IOBluetoothDevice.register(forConnectNotifications: self,
                                   selector: #selector(connected(_:device:)))
        for device in (IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice]) ?? []
        where device.isConnected() {
            device.register(forDisconnectNotification: self, selector: #selector(changed(_:device:)))
        }
        updateBluetooth()
    }

    @objc func connected(_ note: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        device.register(forDisconnectNotification: self, selector: #selector(changed(_:device:)))
        DispatchQueue.main.async { updateBluetooth() }
    }

    @objc func changed(_ note: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        DispatchQueue.main.async { updateBluetooth() }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if CBCentralManager.authorization == .allowedAlways { startClassic() }
        DispatchQueue.main.async { updateBluetooth() }
    }
}
let bluetoothWatcher = BluetoothWatcher()

// --- weather (no publisher; wttr.in, refreshed on a long timer)
// One j1 fetch feeds both the pill and its popup — weather.sh does the
// same, via a cache file it writes atomically because a click can read it
// mid-write. In one process the struct IS the cache and that race cannot
// be expressed.

struct Weather {
    var emoji = ""
    var symbol = ""
    var temp = ""
    var desc = ""
    var feels = ""
    var low = ""
    var high = ""
    var wind = ""
    var humidity = ""
    var rain = ""
    var sunrise = ""
    var sunset = ""
    var moon = ""
    var location = ""
    var uv = ""
    var days: [(name: String, emoji: String, low: String, high: String, rain: Int, uv: String)] = []
}

func uvLevel(_ uv: String) -> String {
    guard let n = Int(uv) else { return uv }
    let level = n <= 2 ? "low" : n <= 5 ? "moderate" : n <= 7 ? "high" : n <= 10 ? "very high" : "extreme"
    return "\(n) \(level)"
}

var weather: Weather?

// WWO condition code -> glyph, night-aware for the clear/partly pair
func weatherEmoji(_ code: Int, night: Bool) -> String {
    switch code {
    case 113: return night ? "🌙" : "☀️"
    case 116: return night ? "☁️" : "⛅"
    case 119, 122: return "☁️"
    case 143, 248, 260: return "🌫️"
    case 176, 263, 266, 293, 296, 353: return "🌦️"
    case 299, 302, 305, 308, 356, 359: return "🌧️"
    case 200, 386, 389, 392, 395: return "⛈️"
    case 179, 182, 185, 227, 230, 281, 284, 311...338, 350, 362...368, 374...377: return "❄️"
    default: return "🌡️"
    }
}

func weatherSymbol(_ code: Int, night: Bool) -> String {
    switch code {
    case 113: return night ? "sf:moon.stars.fill" : "sf:sun.max.fill"
    case 116: return night ? "sf:cloud.moon.fill" : "sf:cloud.sun.fill"
    case 119, 122: return "sf:cloud.fill"
    case 143, 248, 260: return "sf:cloud.fog.fill"
    case 176, 263, 266, 293, 296, 353: return "sf:cloud.drizzle.fill"
    case 299, 302, 305, 308, 356, 359: return "sf:cloud.rain.fill"
    case 200, 386, 389, 392, 395: return "sf:cloud.bolt.rain.fill"
    case 179, 182, 185, 227, 230, 281, 284, 311...338, 350, 362...368, 374...377: return "sf:cloud.snow.fill"
    default: return "sf:thermometer.medium"
    }
}

func moonEmoji(_ phase: String) -> String {
    switch phase {
    case "New Moon": return "🌑"
    case "Waxing Crescent": return "🌒"
    case "First Quarter": return "🌓"
    case "Waxing Gibbous": return "🌔"
    case "Full Moon": return "🌕"
    case "Waning Gibbous": return "🌖"
    case "Last Quarter", "Third Quarter": return "🌗"
    case "Waning Crescent": return "🌘"
    default: return "🌙"
    }
}

var weatherCoord: CLLocationCoordinate2D?

func updateWeather() {
    // no coordinate: the timezone's city beats an IP that sits behind the VPN
    // ponytail: a tz city is coarse (Europe/Moscow covers far more than Moscow)
    let place = weatherCoord.map { String(format: "%.3f,%.3f", $0.latitude, $0.longitude) }
        ?? TimeZone.current.identifier.split(separator: "/").last.map { String($0).replacingOccurrences(of: "_", with: "+") }
        ?? ""
    guard let url = URL(string: "https://wttr.in/\(place)?format=j1") else { return }
    var request = URLRequest(url: url)
    request.timeoutInterval = 15
    URLSession.shared.dataTask(with: request) { data, _, _ in
        guard let data,
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let current = (root["current_condition"] as? [[String: Any]])?.first,
              let today = (root["weather"] as? [[String: Any]])?.first
        else { return }

        func text(_ d: [String: Any], _ key: String) -> String { d[key] as? String ?? "" }
        func nested(_ d: [String: Any], _ key: String) -> String {
            ((d[key] as? [[String: Any]])?.first?["value"] as? String) ?? ""
        }

        var w = Weather()
        let hour = Calendar.current.component(.hour, from: Date())
        w.emoji = weatherEmoji(Int(text(current, "weatherCode")) ?? 0, night: hour < 7 || hour >= 20)
        w.symbol = weatherSymbol(Int(text(current, "weatherCode")) ?? 0, night: hour < 7 || hour >= 20)
        w.temp = text(current, "temp_C")
        w.desc = nested(current, "weatherDesc").lowercased()
        w.feels = text(current, "FeelsLikeC")
        w.low = text(today, "mintempC")
        w.high = text(today, "maxtempC")
        w.humidity = text(current, "humidity")
        w.uv = text(current, "uvIndex")
        let iso = DateFormatter()
        iso.dateFormat = "yyyy-MM-dd"
        let short = DateFormatter()
        short.dateFormat = "EEE"
        for (i, day) in ((root["weather"] as? [[String: Any]]) ?? []).enumerated() {
            let hourly = (day["hourly"] as? [[String: Any]]) ?? []
            let noon = hourly.count > 4 ? hourly[4] : hourly.first ?? [:]
            let name = i == 0 ? "today"
                : iso.date(from: text(day, "date")).map { short.string(from: $0).lowercased() } ?? text(day, "date")
            w.days.append((name, weatherEmoji(Int(text(noon, "weatherCode")) ?? 0, night: false),
                           text(day, "mintempC"), text(day, "maxtempC"),
                           hourly.compactMap { Int(($0["chanceofrain"] as? String) ?? "0") }.max() ?? 0,
                           text(day, "uvIndex")))
        }

        let degrees = Int(text(current, "winddirDegree")) ?? 0
        let arrows = ["↓", "↙", "←", "↖", "↑", "↗", "→", "↘"]
        w.wind = "\(arrows[((degrees + 180) / 45) % 8]) \(text(current, "windspeedKmph")) km/h"

        // rain earns a row only with real signal: falling now, or likely today
        let precip = Double(text(current, "precipMM")) ?? 0
        let chance = ((today["hourly"] as? [[String: Any]]) ?? [])
            .compactMap { Int(($0["chanceofrain"] as? String) ?? "0") }.max() ?? 0
        if precip > 0 {
            w.rain = "☔ \(text(current, "precipMM"))mm now"
            if chance >= 30 { w.rain += " · rain \(chance)% today" }
        } else if chance >= 30 {
            w.rain = "☔ rain \(chance)% today"
        }

        if let astro = (today["astronomy"] as? [[String: Any]])?.first {
            w.sunrise = text(astro, "sunrise")
            w.sunset = text(astro, "sunset")
            w.moon = "\(moonEmoji(text(astro, "moon_phase"))) \(text(astro, "moon_phase").lowercased())"
        }

        if let area = (root["nearest_area"] as? [[String: Any]])?.first {
            // wttr repeats the city as its region ("Porto, Porto"), so the
            // region is dropped whenever either name contains the other
            let city = nested(area, "areaName")
            let region = nested(area, "region")
            let country = nested(area, "country")
            var parts = [city]
            if !region.isEmpty,
               !city.lowercased().contains(region.lowercased()),
               !region.lowercased().contains(city.lowercased()) {
                parts.append(region)
            }
            if !country.isEmpty { parts.append(country) }
            w.location = parts.joined(separator: ", ")
        }

        DispatchQueue.main.async {
            weather = w
            set("weather") { $0.icon = w.symbol; $0.label = "\(w.temp)°" }
            if openPopup == "weather" { refreshPopup() }
        }
    }.resume()
}

// --- popups ----------------------------------------------------------------
// A popup is a list of rows in its own window. sketchybar has to model
// these as bar items with a naming convention (`clock.cal.3`) that a
// separate shell guard greps to clean up; here they are just views that
// go away when the window closes, so there is no convention to break and
// nothing to leak.

struct PopupRow {
    var icon = ""
    var image: NSImage? // 16pt leading icon — Recent Items entries
    var text = ""
    var detail = "" // right-aligned, dim — menu shortcuts live here
    var separator = false // a thin rule instead of content
    var hero = false // accent, bold — the title row
    var dim = false // the quiet action footer
    var highlight = false // today's week, the active device
    var slider: Double? // 0...1 draws a track instead of text
    var onSlide: ((Double) -> Void)?
    var action: (() -> Void)?
    // a table row: columns line up with the neighbouring rows that have the
    // same number of cells, each column as wide as its widest cell
    var cells: [String] = []
    var cellDim: Set<Int> = []
    var cellMark: Int? // accent plate, e.g. today in the calendar
    var labelCol = false // first cell is a left-aligned label, the rest centred
}


final class PopupView: NSView {
    var rows: [PopupRow] = []
    private var rowRects: [(Int, NSRect)] = []
    // the row under the pointer, actionable rows only — menus read as
    // menus when they answer the hover
    private var hoveredRow: Int?

    // NOT flipped: CTLineDraw draws in the CONTEXT's coordinates, so a
    // flipped view renders every glyph mirrored. NSString.draw hid that
    // difference, which is why this only broke when the text layer moved to
    // CoreText — the bar is unflipped and looked fine. Rows are laid out
    // downward explicitly instead of flipping the view.
    func font(_ row: PopupRow) -> NSFont {
        if row.hero { return nerdFont("Bold", 13) }
        if row.dim { return nerdFont("Regular", 12) }
        return nerdFont("Regular", 13)
    }

    func color(_ row: PopupRow) -> NSColor {
        if row.hero { return palette.accent }
        // the dim footer is the label colour at 60%, the same relationship
        // the shell popups build with a 0x99 alpha prefix
        if row.dim { return palette.label.withAlphaComponent(0.6) }
        return palette.label
    }

    // separators are hairlines, not rows: a full 26 pt of blank per
    // rule made long menus read bulky instead of sectioned
    func rowH(_ row: PopupRow) -> CGFloat { row.separator ? 10 : ROW_HEIGHT }

    // per row: its table's column widths ([] for a plain row)
    func tableWidths() -> [[CGFloat]] {
        var out: [[CGFloat]] = []
        var i = 0
        while i < rows.count {
            let n = rows[i].cells.count
            guard n > 0 else { out.append([]); i += 1; continue }
            var j = i
            while j < rows.count && rows[j].cells.count == n { j += 1 }
            var w = [CGFloat](repeating: 0, count: n)
            for r in rows[i..<j] {
                for (k, c) in r.cells.enumerated() { w[k] = max(w[k], advance(c, font(r))) }
            }
            out.append(contentsOf: Array(repeating: w.map { $0 + CELL_PAD }, count: j - i))
            i = j
        }
        return out
    }

    func measure() -> NSSize {
        var width: CGFloat = 0
        var height: CGFloat = POPUP_PAD * 2
        let tables = tableWidths()
        for (index, row) in rows.enumerated() {
            if !row.cells.isEmpty {
                width = max(width, tables[index].reduce(0, +))
                height += rowH(row)
                continue
            }
            var w = advance(row.text, font(row))
            if !row.detail.isEmpty { w += advance(row.detail, nerdFont("Regular", 11)) + 24 }
            if !row.icon.isEmpty { w += inkBox(row.icon, nerdFont("Bold", 13)).width + 8 }
            if row.image != nil { w += 22 }
            if row.slider != nil { w = max(w, 150) }
            width = max(width, w)
            height += rowH(row)
        }
        return NSSize(width: width + POPUP_PAD * 2 + 20, height: height)
    }

    override func draw(_ dirtyRect: NSRect) {
        rowRects.removeAll()
        // plain fill: the scroll CONTAINER carries the rounded clip and
        // border, so corners stay put while tall content scrolls
        palette.barBG.setFill()
        bounds.fill()

        var y = bounds.height - POPUP_PAD
        let tables = tableWidths()
        for (index, row) in rows.enumerated() {
            let h = rowH(row)
            y -= h
            let rect = NSRect(x: POPUP_PAD, y: y, width: bounds.width - POPUP_PAD * 2, height: h)
            if row.separator {
                palette.label.withAlphaComponent(0.15).setFill()
                NSRect(x: rect.minX + 2, y: rect.midY - 0.5, width: rect.width - 4, height: 1).fill()
                rowRects.append((index, rect))
                continue
            }
            if !row.cells.isEmpty {
                let f = font(row)
                var cx = rect.minX
                for (k, cell) in row.cells.enumerated() {
                    let cw = tables[index][k]
                    let box = NSRect(x: cx, y: rect.minY, width: cw, height: rect.height)
                    let marked = k == row.cellMark
                    if marked {
                        palette.accent.setFill()
                        NSBezierPath(roundedRect: box.insetBy(dx: 1, dy: 2), xRadius: RADIUS, yRadius: RADIUS).fill()
                    }
                    let tint = marked ? palette.barBG
                        : row.cellDim.contains(k) ? palette.label.withAlphaComponent(0.4) : color(row)
                    // a 2-cell label row is key/value: the value reads left-aligned
                    let left = row.labelCol && (k == 0 || row.cells.count == 2)
                    let tx = left ? cx + 4 : cx + (cw - advance(cell, f)) / 2
                    drawText(cell, f, tint, leftAt: tx, midY: rect.midY)
                    cx += cw
                }
                rowRects.append((index, rect))
                continue
            }
            if row.highlight || index == hoveredRow {
                palette.itemBG.setFill()
                NSBezierPath(roundedRect: rect.insetBy(dx: -2, dy: 2), xRadius: 4, yRadius: 4).fill()
            }
            var x = rect.minX + 4
            if let image = row.image {
                image.draw(in: NSRect(x: x, y: rect.midY - 8, width: 16, height: 16))
                x += 22
            }
            if !row.icon.isEmpty {
                // same strategy as the bar: glyphs centre on ink, text on
                // cap height — one way of placing things in this file
                let iconFont = nerdFont("Bold", 13)
                let w = inkBox(row.icon, iconFont).width
                drawIcon(row.icon, iconFont, palette.accent,
                         centeredIn: NSRect(x: x, y: rect.minY, width: w, height: rect.height))
                x += w + 8
            }
            if let value = row.slider {
                // track, then filled portion — the readout is the row's text
                let trackW = rect.width - (x - rect.minX) - 52
                let track = NSRect(x: x, y: rect.midY - 3, width: trackW, height: 6)
                palette.itemBG.setFill()
                NSBezierPath(roundedRect: track, xRadius: 3, yRadius: 3).fill()
                palette.accent.setFill()
                NSBezierPath(roundedRect: NSRect(x: track.minX, y: track.minY,
                                                 width: track.width * CGFloat(value), height: track.height),
                             xRadius: 3, yRadius: 3).fill()
                drawText(row.text, font(row), color(row),
                         leftAt: rect.maxX - advance(row.text, font(row)) - 4, midY: rect.midY)
            } else {
                let tint = index == hoveredRow && row.action != nil ? palette.accent : color(row)
                drawText(row.text, font(row), tint, leftAt: x, midY: rect.midY)
                if !row.detail.isEmpty {
                    let df = nerdFont("Regular", 11)
                    drawText(row.detail, df, palette.label.withAlphaComponent(0.5),
                             leftAt: rect.maxX - advance(row.detail, df) - 4, midY: rect.midY)
                }
            }
            rowRects.append((index, rect))
        }
    }


    // Tracking areas, not a poll and not a global monitor: a global
    // monitor stops delivering once this app is itself active, which is
    // exactly what clicking the bar makes it.
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: bounds,
                                       options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
                                       owner: self))
    }

    override func mouseMoved(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        let hit = rowRects.first(where: { $0.1.contains(p) && rows[$0.0].action != nil })?.0
        if hit != hoveredRow { hoveredRow = hit; needsDisplay = true }
    }

    override func mouseExited(with event: NSEvent) {
        if hoveredRow != nil { hoveredRow = nil; needsDisplay = true }
        scheduleHullCheck()
    }

    private func slide(_ event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        guard let (index, rect) = rowRects.first(where: { $0.1.contains(p) }),
              rows[index].slider != nil, let onSlide = rows[index].onSlide else { return }
        let trackX = rect.minX + 4
        let trackW = rect.width - 4 - 52
        onSlide(min(1, max(0, (p.x - trackX) / trackW)))
    }

    override func mouseDown(with event: NSEvent) { slide(event) }
    override func mouseDragged(with event: NSEvent) { slide(event) }

    override func mouseUp(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        guard let (index, _) = rowRects.first(where: { $0.1.contains(p) }),
              rows[index].slider == nil, let action = rows[index].action else { return }
        action()
    }
}

// non-activating: clicking a popup row must not pull focus off the app
final class PopupWindow: NSPanel {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
}

var popupWindow: PopupWindow?
var popupView: PopupView?
var openPopup: String? // which bar item owns it

func closePopup() {
    popupWindow?.orderOut(nil)
    popupWindow = nil
    popupView = nil
    openPopup = nil
}

// rows are rebuilt, not patched: the content is cheap to regenerate and a
// stale row is worse than a redrawn one
// exact-fit on every refresh: grow-only left the app-menu popup huge
// after backing out of a long menu. The window is bottom-anchored, so
// the frame is recomputed to keep the TOP edge pinned under the bar.
var popupTopY: CGFloat = 0
var popupAnchorX: CGFloat = 0
var popupAlignLeft = false

func refreshPopup() {
    guard let name = openPopup, let view = popupView, let window = popupWindow else { return }
    view.rows = popupRows(for: name)
    let size = view.measure()
    let screen = window.screen ?? NSScreen.main
    var winH = size.height
    var x = popupAlignLeft ? popupAnchorX : popupAnchorX - size.width
    if let screen {
        winH = min(size.height, popupTopY - screen.frame.minY - 20)
        x = min(max(screen.frame.minX + 6, x), screen.frame.maxX - size.width - 6)
    }
    window.setFrame(NSRect(x: x, y: popupTopY - winH,
                           width: size.width, height: winH), display: false)
    if let scroll = window.contentView as? NSScrollView {
        scroll.frame = NSRect(origin: .zero, size: NSSize(width: size.width, height: winH))
        scroll.verticalScrollElasticity = winH < size.height ? .automatic : .none
    }
    view.frame = NSRect(origin: .zero, size: size)
    view.scroll(NSPoint(x: 0, y: max(0, size.height - winH))) // drilling resets to the top
    view.needsDisplay = true
    view.display()
}

func showPopup(_ name: String, under anchor: NSRect, on surface: BarSurface, alignLeft: Bool = false) {
    if openPopup == name { closePopup(); return }
    closePopup()
    let rows = popupRows(for: name)
    guard !rows.isEmpty else { return }

    let view = PopupView(frame: .zero)
    view.rows = rows
    let size = view.measure()
    view.frame = NSRect(origin: .zero, size: size)

    // right-aligned under the item, clamped to the screen it opened on;
    // taller-than-screen content (Recent Items) scrolls inside a capped
    // window instead of running off the display
    let screen = surface.screen
    let barBottom = surface.window.frame.minY
    popupTopY = barBottom - 4
    popupAnchorX = alignLeft ? anchor.minX : anchor.maxX
    popupAlignLeft = alignLeft
    let winH = min(size.height, popupTopY - screen.frame.minY - 20)
    var x = alignLeft ? anchor.minX : anchor.maxX - size.width
    x = min(max(screen.frame.minX + 6, x), screen.frame.maxX - size.width - 6)
    let window = PopupWindow(contentRect: NSRect(x: x, y: popupTopY - winH,
                                                 width: size.width, height: winH),
                             styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
    window.isOpaque = false
    window.backgroundColor = .clear
    window.hasShadow = true
    window.level = .popUpMenu
    window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
    window.acceptsMouseMovedEvents = true
    let scroll = NSScrollView(frame: NSRect(origin: .zero, size: NSSize(width: size.width, height: winH)))
    scroll.drawsBackground = false
    scroll.hasVerticalScroller = true
    scroll.scrollerStyle = .overlay
    scroll.autohidesScrollers = true
    // no rubber-band on menus that fit: only a capped (taller-than-screen) one scrolls
    scroll.verticalScrollElasticity = winH < size.height ? .automatic : .none
    scroll.documentView = view
    scroll.wantsLayer = true
    scroll.layer?.cornerRadius = POPUP_RADIUS
    scroll.layer?.masksToBounds = true
    scroll.layer?.borderWidth = 1
    scroll.layer?.borderColor = palette.accent.cgColor
    window.contentView = scroll
    view.scroll(NSPoint(x: 0, y: max(0, size.height - winH))) // start at the top
    window.orderFrontRegardless()
    popupWindow = window
    popupView = view
    openPopup = name
}

// --- popup content ---------------------------------------------------------

func calendarRows() -> [PopupRow] {
    var rows: [PopupRow] = []
    let now = Date()
    var cal = Calendar(identifier: .gregorian)
    cal.firstWeekday = 2 // Monday, like the shell version
    let title = DateFormatter()
    title.dateFormat = "MMMM yyyy"
    rows.append(PopupRow(text: title.string(from: now).lowercased(), hero: true))
    rows.append(PopupRow(cells: ["mo", "tu", "we", "th", "fr", "sa", "su"], cellDim: Set(0..<7)))

    guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)),
          let range = cal.range(of: .day, in: .month, for: now) else { return rows }
    let today = cal.component(.day, from: now)
    // weekday index with Monday = 0
    let leading = (cal.component(.weekday, from: monthStart) + 5) % 7
    let prevDays = cal.range(of: .day, in: .month,
                             for: cal.date(byAdding: .month, value: -1, to: monthStart)!)!.count

    var cells: [(Int, Bool)] = [] // day, in-month
    for i in 0..<leading { cells.append((prevDays - leading + 1 + i, false)) }
    for d in range { cells.append((d, true)) }
    var next = 1
    while cells.count % 7 != 0 { cells.append((next, false)); next += 1 }

    for week in stride(from: 0, to: cells.count, by: 7) {
        let slice = cells[week..<min(week + 7, cells.count)]
        rows.append(PopupRow(cells: slice.map { "\($0.0)" },
                             cellDim: Set(slice.indices.filter { !cells[$0].1 }.map { $0 - week }),
                             cellMark: slice.firstIndex { $0.0 == today && $0.1 }.map { $0 - week }))
    }
    let week = cal.component(.weekOfYear, from: now)
    rows.append(PopupRow(text: "week \(week)", dim: true))
    return rows
}

func brightnessRows() -> [PopupRow] {
    var value: Float = 0
    guard DSGetBrightness(builtinDisplayID(), &value) == 0 else { return [] }
    var rows = [
        PopupRow(icon: "sf:sun.max.fill", text: "\(Int((value * 100).rounded()))%",
                 slider: Double(value),
                 onSlide: { fraction in
                     _ = DSSetBrightness(builtinDisplayID(), Float(fraction))
                     updateBrightness()
                 }),
        PopupRow(icon: "sf:moon.fill", text: "\(Int((shade * 100).rounded()))%",
                 slider: shade,
                 onSlide: { setShade($0) }),
    ]
    // read in process, every time the rows are built: the row says what
    // CoreBrightness says now, and a Mac without night shift gets no row
    // rather than a lying one
    if let ns = blueLightStatus(), ns.available.boolValue {
        let on = ns.enabled.boolValue
        rows.append(PopupRow(text: "night shift \(on ? "on" : "off")", action: {
            setNightShift(!on)
            refreshPopup()
        }))
    }
    rows.append(PopupRow(text: "display settings…", dim: true, action: {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension")!)
        closePopup()
    }))
    return rows
}

func volumeRows() -> [PopupRow] {
    guard let v = readVolume() else { return [] }
    var rows: [PopupRow] = [
        PopupRow(icon: v.muted ? "󰝟" : "󰕾", text: v.muted ? "mute" : "\(v.percent)%",
                 slider: Double(v.percent) / 100,
                 onSlide: { fraction in
                     writeVolume(Int((fraction * 100).rounded()))
                     updateVolume()
                 }),
    ]
    // output devices, current one marked
    let current = defaultOutputDevice()
    for device in audioOutputDevices() {
        rows.append(PopupRow(icon: device.id == current ? "󰄬" : " ", text: device.name,
                             highlight: device.id == current,
                             action: {
                                 setDefaultOutputDevice(device.id)
                                 updateVolume()
                                 refreshPopup()
                             }))
    }
    rows.append(PopupRow(text: "sound settings…", dim: true, action: {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Sound-Settings.extension")!)
        closePopup()
    }))
    return rows
}

// SCDynamicStore answers both in process. The popup used to fork
// ipconfig on the click path just for the address — and the router,
// the one number you actually want when the network misbehaves, was
// never shown at all.
func wifiIPv4() -> (ip: String, router: String) {
    guard let store = SCDynamicStoreCreate(nil, "statusbar-ipv4" as CFString, nil, nil)
    else { return ("", "") }
    let global = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString)
        as? [String: Any]
    let iface = SCDynamicStoreCopyValue(store,
        "State:/Network/Interface/\(wifiDevice)/IPv4" as CFString) as? [String: Any]
    return ((iface?["Addresses"] as? [String])?.first ?? "",
            global?["Router"] as? String ?? "")
}

// Name only what is certain — the generic personal/enterprise cases
// cover several generations and guessing one would be a lie.
func securityName(_ s: CWSecurity) -> String? {
    switch s {
    case .none: return "open"
    case .WEP, .dynamicWEP: return "WEP"
    case .wpaPersonal, .wpaPersonalMixed, .wpaEnterprise, .wpaEnterpriseMixed: return "WPA"
    case .wpa2Personal, .wpa2Enterprise: return "WPA2"
    case .wpa3Personal, .wpa3Enterprise, .wpa3Transition: return "WPA3"
    case .OWE, .oweTransition: return "OWE"
    default: return nil
    }
}

func wifiRows() -> [PopupRow] {
    let interface = CWWiFiClient.shared().interface()
    var rows: [PopupRow] = [
        // the SSID is location-sensitive data: it needs the Location
        // grant AND a bundled binary (measured on macOS 26.3 — an
        // unbundled build reads nil however it is authorised), which
        // is why the bar ships inside a .app. See install.sh.
        PopupRow(text: interface?.ssid() ?? "wi-fi", hero: true),
    ]
    let net = wifiIPv4()
    rows.append(PopupRow(text: "ip \(net.ip.ifEmpty("none"))"))
    if !net.router.isEmpty { rows.append(PopupRow(text: "router \(net.router)")) }
    if let rssi = interface?.rssiValue(), rssi != 0 {
        let verdict = rssi >= -55 ? "excellent" : (rssi >= -67 ? "good" : (rssi >= -75 ? "fair" : "weak"))
        rows.append(PopupRow(text: "signal \(rssi) dBm  \(verdict)"))
    }
    // how fast, and how safe — the two questions the old rows left open
    var link: [String] = []
    if let rate = interface?.transmitRate(), rate > 0 { link.append("\(Int(rate)) Mbps") }
    if let sec = interface?.security(), let name = securityName(sec) { link.append(name) }
    if !link.isEmpty { rows.append(PopupRow(text: "link " + link.joined(separator: "  "))) }
    if let channel = interface?.wlanChannel() {
        // a bare channel number means nothing to most people; the band
        // is what says "you are on the fast radio"
        var parts = ["channel \(channel.channelNumber)"]
        switch channel.channelBand {
        case .band2GHz: parts.append("2.4 GHz")
        case .band5GHz: parts.append("5 GHz")
        case .band6GHz: parts.append("6 GHz")
        default: break
        }
        switch channel.channelWidth {
        case .width20MHz: parts.append("20 MHz")
        case .width40MHz: parts.append("40 MHz")
        case .width80MHz: parts.append("80 MHz")
        case .width160MHz: parts.append("160 MHz")
        default: break
        }
        rows.append(PopupRow(text: parts.joined(separator: "  ")))
    }
    rows.append(PopupRow(text: "network settings…", dim: true, action: {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.wifi-settings-extension")!)
        closePopup()
    }))
    return rows
}

func bluetoothRows() -> [PopupRow] {
    var rows: [PopupRow] = [PopupRow(text: "bluetooth", hero: true)]
    guard CBCentralManager.authorization == .allowedAlways else {
        rows.append(PopupRow(text: "no permission in this launch context", dim: true))
        return rows
    }
    let devices = ((IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice]) ?? [])
        .sorted { ($0.isConnected() ? 0 : 1, $0.name ?? "") < ($1.isConnected() ? 0 : 1, $1.name ?? "") }
    for device in devices { // connected first, then by name
        let name = device.name ?? device.addressString ?? "device"
        rows.append(PopupRow(icon: "bt", text: name,
                             highlight: device.isConnected(),
                             action: {
                                 if device.isConnected() { device.closeConnection() } else { device.openConnection() }
                                 updateBluetooth()
                                 refreshPopup()
                             }))
    }
    rows.append(PopupRow(text: "bluetooth settings…", dim: true, action: {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings")!)
        closePopup()
    }))
    return rows
}

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
              let url = URL(string: "https://api.anthropic.com/api/oauth/usage") else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data, let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { return }
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            func window(_ key: String) -> ClaudeWindow? {
                guard let w = root[key] as? [String: Any], let used = w["utilization"] as? Double else { return nil }
                return ClaudeWindow(used: used, resets: (w["resets_at"] as? String).flatMap { iso.date(from: $0) })
            }
            guard let five = window("five_hour"), let week = window("seven_day") else {
                tlog("claude: no usage in response")
                return
            }
            DispatchQueue.main.async {
                claudeUsage = (five, week)
                let worst = max(five.used, week.used)
                set("claude") {
                    $0.icon = "donut:\(five.used / 100)"
                    $0.iconColor = worst >= 90 ? \.red : worst >= 70 ? \.yellow : \.accent
                    $0.label = "\(Int(five.used))%"
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

// --- keyboard layout (TIS publishes a distributed notification) ----------

func inputSourceProp<T>(_ src: TISInputSource, _ key: CFString) -> T? {
    guard let ptr = TISGetInputSourceProperty(src, key) else { return nil }
    return Unmanaged<AnyObject>.fromOpaque(ptr).takeUnretainedValue() as? T
}

// "EN", "RU": the source's first language, falling back to its name
func layoutShort(_ src: TISInputSource) -> String {
    let langs: [String] = inputSourceProp(src, kTISPropertyInputSourceLanguages) ?? []
    let name: String = inputSourceProp(src, kTISPropertyLocalizedName) ?? "?"
    return (langs.first ?? name).prefix(2).uppercased()
}

func updateLayout() {
    let src = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
    set("layout") { $0.icon = "key:\(layoutShort(src))"; $0.iconColor = nil; $0.label = "" }
}

func layoutRows() -> [PopupRow] {
    let filter = [kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource,
                  kTISPropertyInputSourceIsSelectCapable: true] as CFDictionary
    let sources = (TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource]) ?? []
    let current: String? = inputSourceProp(TISCopyCurrentKeyboardInputSource().takeRetainedValue(),
                                           kTISPropertyInputSourceID)
    var rows = [PopupRow(text: "keyboard", hero: true)]
    for src in sources {
        let id: String? = inputSourceProp(src, kTISPropertyInputSourceID)
        let name: String = inputSourceProp(src, kTISPropertyLocalizedName) ?? "?"
        rows.append(PopupRow(text: name, detail: layoutShort(src), highlight: id == current, action: {
            TISSelectInputSource(src)
            closePopup()
        }))
    }
    rows.append(PopupRow(text: "keyboard settings…", dim: true, action: {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension")!)
        closePopup()
    }))
    return rows
}

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
    var rows = [PopupRow(text: t.tailnet.isEmpty ? "tailscale" : t.tailnet, hero: true)]
    // the button says what a click does; the status under it is read-only
    rows.append(PopupRow(icon: "sf:power", text: t.running ? "disconnect" : "connect",
                         action: run(t.running ? ["down"] : ["up"])))
    rows.append(PopupRow(separator: true))
    rows.append(PopupRow(icon: t.running ? "sf:network" : "sf:network.slash",
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

func weatherRows() -> [PopupRow] {
    guard let w = weather else { return [] }
    var rows: [PopupRow] = [PopupRow(text: "\(w.emoji) \(w.temp)°C \(w.desc)", hero: true)]
    func kv(_ k: String, _ v: String) -> PopupRow { PopupRow(cells: [k, v], cellDim: [0], labelCol: true) }
    if w.feels != w.temp { rows.append(kv("feels", "\(w.feels)°C")) }
    rows.append(kv("wind", w.wind))
    rows.append(kv("humidity", "\(w.humidity)%"))
    if !w.uv.isEmpty { rows.append(kv("uv", uvLevel(w.uv))) }
    if !w.rain.isEmpty { rows.append(kv("rain", w.rain.replacingOccurrences(of: "☔ ", with: ""))) }
    if !w.sunrise.isEmpty { rows.append(kv("sun", "\(w.sunrise) → \(w.sunset)")) }
    if !w.moon.isEmpty { rows.append(kv("moon", w.moon)) }
    if !w.days.isEmpty {
        // the forecast: one column per day
        rows.append(PopupRow(separator: true))
        rows.append(PopupRow(cells: [""] + w.days.map(\.name), cellDim: Set(0...w.days.count), labelCol: true))
        rows.append(PopupRow(cells: [""] + w.days.map(\.emoji), labelCol: true))
        rows.append(PopupRow(cells: ["temp"] + w.days.map { "\($0.low)–\($0.high)°" }, cellDim: [0], labelCol: true))
        rows.append(PopupRow(cells: ["rain"] + w.days.map { "\($0.rain)%" }, cellDim: [0], labelCol: true))
        rows.append(PopupRow(cells: ["uv"] + w.days.map(\.uv), cellDim: [0], labelCol: true))
    }
    if !w.location.isEmpty {
        rows.append(PopupRow(separator: true))
        rows.append(PopupRow(text: w.location, dim: true))
    }
    return rows
}

// The system menu the hidden native menu bar used to carry. "Reload Bar" has no counterpart here on purpose: there
// is no config to re-read, the theme is watched, and a row that did
// nothing would be worse than a row that is absent.
func appleRows() -> [PopupRow] {
    func settings(_ pane: String) -> () -> Void {
        { NSWorkspace.shared.open(URL(string: pane)!); closePopup() }
    }
    func run(_ launch: String, _ args: [String]) -> () -> Void {
        {
            closePopup()
            DispatchQueue.global(qos: .userInitiated).async { _ = shell(launch, args) }
        }
    }
    func systemEvents(_ verb: String) -> () -> Void {
        run("/usr/bin/osascript", ["-e", "tell application \"System Events\" to \(verb)"])
    }
    return [
        PopupRow(text: "About This Mac", hero: true,
                 action: settings("x-apple.systempreferences:com.apple.SystemProfiler.AboutExtension")),
        PopupRow(text: "System Settings…", action: run("/usr/bin/open", ["-a", "System Settings"])),
        // pmset displaysleepnow only darkens the panel — whether that
        // locks depends on the screenLock delay, so it usually did not
        PopupRow(text: "Lock Screen",
                 action: systemEvents("keystroke \"q\" using {control down, command down}")),
        PopupRow(text: "Sleep", action: run("/usr/bin/pmset", ["sleepnow"])),
        PopupRow(text: "Restart…", action: systemEvents("restart")),
        PopupRow(text: "Shut Down…", action: systemEvents("shut down")),
    ]
}

func popupRows(for name: String) -> [PopupRow] {
    switch name {
    case "apple": return appleMenuRows()
    case "clock": return calendarRows()
    case "weather": return weatherRows()
    case "brightness": return brightnessRows()
    case "volume": return volumeRows()
    case "wifi": return wifiRows()
    case "bluetooth": return bluetoothRows()
    case "tailscale": return tailscaleRows()
    case "layout": return layoutRows()
    case "claude": return claudeRows()
    case "appmenu": return appMenuRows()
    default: return []
    }
}

// The focused app's menu bar, read over Accessibility and rendered
// INSIDE our popup: top level lists File/Edit/…, clicking drills into
// that menu's actual items, and clicking a leaf performs its AXPress —
// the command runs with no native menu ever appearing. A navigation
// stack lives for the popup's lifetime; "‹" walks back up.
var appMenuStack: [(title: String, element: AXUIElement)] = []

private func axChildren(_ element: AXUIElement) -> [AXUIElement] {
    var ref: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, "AXChildren" as CFString, &ref) == .success,
          let children = ref as? [AXUIElement] else { return [] }
    return children
}

private func axString(_ element: AXUIElement, _ attr: String) -> String {
    var ref: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attr as CFString, &ref) == .success else { return "" }
    return ref as? String ?? ""
}

// one menu's items as popup rows — shared by the app drill-down and the
// apple pill. A menu bar item wraps one AXMenu; the items live inside.
// AXEnabled is a lie for closed menus: apps validate items lazily when
// a menu OPENS, so unopened menus read mostly disabled (Arc's whole
// Tabs menu greyed out). Render all leaves live; a truly disabled
// item's AXPress just no-ops.
// Recent Items: AX exposes no menu-item images, but its entries are
// apps and documents whose icons Launch Services can resolve by name —
// the section headers ("Applications"/"Documents"/"Servers") say which
// strategy applies. Headers render dim, entries get real icons.
func recentItemIcon(_ title: String, section: String) -> NSImage? {
    if section == "Applications" {
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == title }),
           let icon = app.icon { return icon }
        if let path = NSWorkspace.shared.fullPath(forApplication: title) {
            return NSWorkspace.shared.icon(forFile: path)
        }
        return nil
    }
    if section == "Documents" {
        let ext = (title as NSString).pathExtension
        if !ext.isEmpty, let type = UTType(filenameExtension: ext) {
            return NSWorkspace.shared.icon(for: type)
        }
        return NSWorkspace.shared.icon(for: .data)
    }
    return nil
}

func rowsForMenu(_ element: AXUIElement, context: String = "",
                 collapseAlternates: Bool = false) -> [PopupRow] {
    let container = axChildren(element).first ?? element
    var rows: [PopupRow] = []
    var section = ""
    var prevTitle = ""
    let recents = context == "Recent Items"
    for item in axChildren(container) {
        let title = axString(item, "AXTitle")
        if title.isEmpty {
            if rows.last?.separator != true { rows.append(PopupRow(separator: true)) }
            prevTitle = ""
            continue
        }
        // the Apple menu carries hold-Option ALTERNATES ("Restart…" then
        // "Restart", "Force Quit…" then "Force Quit Arc") that the native
        // menu hides — AX enumerates them flat. An item whose title
        // extends its predecessor's (ellipsis stripped) is the alternate.
        if collapseAlternates, !prevTitle.isEmpty {
            let base = prevTitle.replacingOccurrences(of: "…", with: "")
            if title.hasPrefix(base) { continue }
        }
        prevTitle = title
        // Recent Items' own hold-Option alternates ("Show X in Finder")
        // carry a different title shape than the root menu's (English UI;
        // the pattern is locale-bound, worst case they reappear)
        if recents, title.hasPrefix("Show “"), title.hasSuffix("” in Finder") { continue }
        if recents, ["Applications", "Documents", "Servers"].contains(title) {
            section = title
            rows.append(PopupRow(text: title, dim: true))
            continue
        }
        if !axChildren(item).isEmpty {
            rows.append(PopupRow(icon: "›", text: title, action: {
                appMenuStack.append((title, item))
                refreshPopup()
            }))
        } else {
            let cmd = axString(item, "AXMenuItemCmdChar")
            rows.append(PopupRow(image: recents ? recentItemIcon(title, section: section) : nil,
                                 text: title, detail: cmd.isEmpty ? "" : "⌘\(cmd)", action: {
                closePopup()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    AXUIElementPerformAction(item, "AXPress" as CFString)
                }
            }))
        }
    }
    return rows
}

// the frontmost app's AX menu bar, resolved the popup-safe way
func frontAppAXMenuBar() -> AXUIElement? {
    guard !model.frontApp.isEmpty,
          let app = NSWorkspace.shared.runningApplications.first(where: {
              $0.localizedName == model.frontApp
                  && $0.processIdentifier != ProcessInfo.processInfo.processIdentifier
          })
    else { return nil }
    let ax = AXUIElementCreateApplication(app.processIdentifier)
    var ref: CFTypeRef?
    guard AXUIElementCopyAttributeValue(ax, "AXMenuBar" as CFString, &ref) == .success,
          let bar = ref, CFGetTypeID(bar) == AXUIElementGetTypeID() else { return nil }
    return (bar as! AXUIElement)
}

// The REAL Apple menu — child 0 of the front app's menu bar, the item
// the app drill-down skips — through the same drill machinery. Falls back to the hand-rolled rows
// when Accessibility is not granted or AX has nothing.
func appleMenuRows() -> [PopupRow] {
    guard AXIsProcessTrusted(),
          let menubar = frontAppAXMenuBar(),
          let apple = axChildren(menubar).first
    else { return appleRows() }
    if !appMenuStack.isEmpty {
        return appMenuRows()
    }
    let rows = rowsForMenu(apple, collapseAlternates: true)
    guard !rows.isEmpty else { return appleRows() }
    return rows
}

func appMenuRows() -> [PopupRow] {
    let opts = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
    guard AXIsProcessTrustedWithOptions(opts) else {
        return [PopupRow(text: "grant Accessibility to statusbar", hero: true),
                PopupRow(text: "System Settings opened the pane — toggle the bar on,", dim: true),
                PopupRow(text: "then click the app name again", dim: true)]
    }
    // drilled into a menu: its items, behind a back row
    if let top = appMenuStack.last {
        var rows = [PopupRow(icon: "‹", text: top.title, highlight: true, action: {
            appMenuStack.removeLast()
            refreshPopup()
        })]
        rows.append(contentsOf: rowsForMenu(top.element, context: top.title))
        return rows
    }
    // NOT frontmostApplication: the click that opens this popup makes
    // the bar itself frontmost for a beat, and the popup bailed empty.
    // model.frontApp tracks the real app and ignores our own pid.
    guard let menubar = frontAppAXMenuBar() else {
        tlog("appmenu: no menu bar for '\(model.frontApp)'")
        return []
    }
    // no hero title: the app's name is literally the pill this popup
    // hangs from. Index 0 is the Apple menu — our apple pill's ground.
    var rows: [PopupRow] = []
    for item in axChildren(menubar).dropFirst() {
        let title = axString(item, "AXTitle")
        guard !title.isEmpty else { continue }
        rows.append(PopupRow(icon: "›", text: title, action: {
            appMenuStack.append((title, item))
            refreshPopup()
        }))
    }
    if !rows.isEmpty { rows[0].highlight = true }
    return rows
}

extension String {
    func ifEmpty(_ fallback: String) -> String { isEmpty ? fallback : self }
}

// --- cheatsheet (Super+K) --------------------------------------------------
// Rendered from the LIVE OmniWM settings.toml, never from a list kept here: a cheatsheet
// that can disagree with the keys is worse than no cheatsheet. The
// config's own section comments become the headings, so the grouping is
// the author's rather than a second opinion about it.

struct CheatEntry {
    let group: String
    let key: String
    let action: String
}

func cheatEntries() -> [CheatEntry] { omniwmCheatEntries() }

// "Control+Option+Command+Shift+1" -> "Super+Shift+1": Super IS
// cmd-ctrl-alt here (Caps Lock sends it). The key names arrive already
// capitalised; only " Arrow" is dropped, so the arrows read "Left".
func prettyOmniKey(_ raw: String) -> String {
    var rest = raw
    var parts: [String] = []
    if rest.hasPrefix("Control+Option+Command+") {
        parts.append("Super")
        rest = String(rest.dropFirst("Control+Option+Command+".count))
    }
    for comp in rest.split(separator: "+") {
        var key = String(comp)
        if key.hasSuffix(" Arrow") { key = String(key.dropLast(" Arrow".count)) }
        parts.append(key)
    }
    return parts.joined(separator: "+")
}

// "switchWorkspace.0" -> "switch workspace 1": the raw catalog ids were
// printed verbatim once, on the theory that the config's truth beats a
// pretty lie — and read as a mess (0-based suffixes beside 1-based
// keycaps, camelCase runs). The id's meaning survives; only the casing
// and indexing are translated to match the keycap next to it.
func humanizeOmniId(_ id: String) -> String {
    func words(_ s: String) -> String {
        var out = ""
        for ch in s { out.append(ch.isUppercase ? " " + String(ch).lowercased() : String(ch)) }
        return out.trimmingCharacters(in: .whitespaces)
    }
    let parts = id.split(separator: ".", maxSplits: 1).map(String.init)
    // dwindle reality beats the catalog's niri-flavored names: moveColumn
    // is a tile SWAP there (the binding people reach for daily), and
    // plain move STACKS into the neighbor as a group
    let renamed = ["moveColumn": "swap window", "move": "stack into"]
    let head = renamed[parts[0]] ?? words(parts[0])
    guard parts.count > 1 else { return head }
    if let n = Int(parts[1]) { return "\(head) \(n + 1)" }
    switch parts[1] {
    case "decrease10Percent": return "\(head) −10%"
    case "increase10Percent": return "\(head) +10%"
    default: return "\(head) \(words(parts[1]))"
    }
}

// with the comment headings stripped by the strict-decoder rewrite, the
// sheet gets its sections from the id families instead
func omniGroup(_ id: String) -> String {
    let h = String(id.split(separator: ".").first ?? "")
    if h.lowercased().contains("workspace") { return "Workspaces" }
    if h.hasPrefix("focus") { return "Focus" }
    if h.hasPrefix("move") || h.hasPrefix("summon") { return "Move" }
    if h.contains("Span") || h.hasPrefix("resize") || h.hasPrefix("balance")
        || h.hasPrefix("cycleSize") || h.hasPrefix("set") { return "Size" }
    if h.hasPrefix("toggle") || h.contains("Layout") || h.contains("Column")
        || h.hasPrefix("preselect") || h.contains("olumn") { return "Layout & columns" }
    return "System"
}

// [[hotkeys]] tables out of OmniWM's settings.toml: a binding string and
// an action id per table, in either order.
func omniwmCheatEntries() -> [CheatEntry] {
    let path = "\(NSHomeDirectory())/.config/omniwm/settings.toml"
    guard let text = try? String(contentsOfFile: path, encoding: .utf8) else { return [] }
    var entries: [CheatEntry] = []
    var group = ""
    var lastWasComment = false
    var inHotkey = false
    var binding = ""
    var id = ""
    func flush() {
        // the canonical settings file carries EVERY catalog id — most
        // Unassigned. A cheatsheet's job is what you CAN press, so the
        // ~90 unassigned rows stay out (they made the sheet a wall).
        if inHotkey, !binding.isEmpty, binding != "Unassigned", !id.isEmpty {
            entries.append(CheatEntry(
                group: group.isEmpty ? omniGroup(id) : group,
                key: prettyOmniKey(binding), action: humanizeOmniId(id)))
        }
        binding = ""
        id = ""
    }
    for raw in text.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = raw.trimmingCharacters(in: .whitespaces)
        if line.hasPrefix("#") {
            // a comment between tables starts the NEXT group: a complete
            // pending entry belongs to the heading it was written under,
            // not the one about to be read (a half-read table keeps its
            // keys — TOML allows comments between them)
            if !binding.isEmpty, !id.isEmpty { flush() }
            // first line of a comment block is a heading — the "---" ruler
            // decoration is trimmed off
            if !lastWasComment {
                var title = String(line.dropFirst())
                    .trimmingCharacters(in: CharacterSet(charactersIn: "- "))
                if let c = title.firstIndex(where: { $0 == ":" || $0 == "." }) {
                    title = String(title[..<c])
                }
                title = title.trimmingCharacters(in: .whitespaces)
                if title.count > 34 { title = String(title.prefix(33)) + "…" }
                group = title
            }
            lastWasComment = true
            continue
        }
        lastWasComment = false
        if line.hasPrefix("[") {
            flush()
            inHotkey = line == "[[hotkeys]]"
            continue
        }
        guard inHotkey, let eq = line.firstIndex(of: "=") else { continue }
        let key = line[line.startIndex..<eq].trimmingCharacters(in: .whitespaces)
        let value = line[line.index(after: eq)...].trimmingCharacters(in: .whitespaces)
        guard let q = value.first, q == "'" || q == "\"",
            let close = value.dropFirst().firstIndex(of: q)
        else { continue }
        let v = String(value[value.index(after: value.startIndex)..<close])
        if key == "binding" { binding = v } else if key == "id" { id = v }
    }
    flush()
    // derived groups arrive interleaved (switch/move alternate per
    // workspace) — order them section by section, keeping in-group
    // order (index tiebreak kept explicit rather than leaning on
    // sort stability)
    let sectionOrder = ["Workspaces", "Focus", "Move", "Layout & columns", "Size", "System"]
    let indexed = entries.enumerated().map { ($0.offset, $0.element) }
    entries = indexed.sorted { a, b in
        let ga = sectionOrder.firstIndex(of: a.1.group) ?? 99
        let gb = sectionOrder.firstIndex(of: b.1.group) ?? 99
        return ga != gb ? ga < gb : a.0 < b.0
    }.map { $0.1 }
    // the exec chords live in Karabiner while OmniWM runs (its hotkeys
    // cannot exec) — the sheet must show them or half the muscle-memory
    // map is invisible. Read our own injected rules back by their
    // description prefix.
    return entries
}


let cheatColumns = 3
let cheatRowH: CGFloat = 20
let cheatPad: CGFloat = 18

// the sheet takes key focus while open (the overview's pattern) so it
// can be typed into; hideCheatsheet hands focus back to the app that
// had it, so the search never costs the user their window
final class CheatWindow: NSWindow {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
    override var canBecomeKey: Bool { true }
}

final class CheatsheetView: NSView {
    var entries: [CheatEntry] = []
    var filter = ""
    private var keyFont: NSFont { nerdFont("Bold", 12) }
    private var actFont: NSFont { nerdFont("Regular", 12) }
    private var headFont: NSFont { nerdFont("Bold", 13) }

    private func visibleEntries() -> [CheatEntry] {
        guard !filter.isEmpty else { return entries }
        let f = filter.lowercased()
        return entries.filter {
            $0.key.lowercased().contains(f) || $0.action.lowercased().contains(f)
                || $0.group.lowercased().contains(f)
        }
    }

    // rows are (heading?, entry?) laid into balanced columns
    private func rows() -> [(String?, CheatEntry?)] {
        var out: [(String?, CheatEntry?)] = []
        var seen = ""
        for e in visibleEntries() {
            if e.group != seen {
                if !out.isEmpty { out.append((nil, nil)) } // breathing room
                out.append((e.group, nil))
                seen = e.group
            }
            out.append((nil, e))
        }
        return out
    }

    private func columns() -> [[(String?, CheatEntry?)]] {
        let all = rows()
        guard !all.isEmpty else { return [] }
        let per = Int((Double(all.count) / Double(cheatColumns)).rounded(.up))
        return stride(from: 0, to: all.count, by: per).map {
            Array(all[$0..<min($0 + per, all.count)])
        }
    }

    private func columnWidths() -> [(key: CGFloat, total: CGFloat)] {
        columns().map { col in
            var k: CGFloat = 0, a: CGFloat = 0
            for (head, e) in col {
                if let head { k = max(k, advance(head, headFont)) }
                if let e {
                    k = max(k, advance(e.key, keyFont))
                    a = max(a, advance(e.action, actFont))
                }
            }
            return (k, k + 14 + a)
        }
    }

    func measure() -> NSSize {
        let cols = columns()
        guard !cols.isEmpty else { return NSSize(width: 320, height: 80) }
        let widths = columnWidths()
        let w = widths.reduce(0) { $0 + $1.total } + CGFloat(cols.count - 1) * 28
        let tallest = cols.map(\.count).max() ?? 0
        return NSSize(width: w + cheatPad * 2,
                      height: CGFloat(tallest) * cheatRowH + cheatPad * 2 + 26)
    }

    override func draw(_ dirtyRect: NSRect) {
        let body = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
                                xRadius: POPUP_RADIUS, yRadius: POPUP_RADIUS)
        palette.barBG.setFill()
        body.fill()
        palette.accent.setStroke()
        body.lineWidth = 1
        body.stroke()

        let title = filter.isEmpty
            ? "keybindings — Super is Caps Lock · type to search · Super+K, Esc or click to close"
            : "search: \(filter)▏ — \(visibleEntries().count) match\(visibleEntries().count == 1 ? "" : "es") · Esc clears"
        drawText(title, nerdFont("Bold", 12), palette.accent.withAlphaComponent(0.8),
                 leftAt: cheatPad, midY: bounds.maxY - cheatPad - 6)

        var x = cheatPad
        for (i, col) in columns().enumerated() {
            let width = columnWidths()[i]
            var y = bounds.maxY - cheatPad - 30
            for (head, e) in col {
                if let head {
                    drawText(head, headFont, palette.accent, leftAt: x, midY: y - cheatRowH / 2)
                } else if let e {
                    drawText(e.key, keyFont, palette.label, leftAt: x, midY: y - cheatRowH / 2)
                    drawText(e.action, actFont, palette.muted,
                             leftAt: x + width.key + 14, midY: y - cheatRowH / 2)
                }
                y -= cheatRowH
            }
            x += width.total + 28
        }
    }

    override func mouseDown(with event: NSEvent) { hideCheatsheet() }

    override var acceptsFirstResponder: Bool { true }
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: // esc — clear an active search first, close on the second
            if filter.isEmpty { hideCheatsheet() } else { filter = ""; refit() }
        case 51: // backspace
            if !filter.isEmpty { filter.removeLast(); refit() }
        case 40 where event.modifierFlags.contains([.command, .control, .option]):
            hideCheatsheet() // Super+K toggles closed even while we hold key
        default:
            guard let chars = event.charactersIgnoringModifiers,
                !chars.isEmpty,
                !event.modifierFlags.contains(.command),
                chars.rangeOfCharacter(from: .alphanumerics.union(CharacterSet(charactersIn: "+- "))) != nil
            else { return }
            filter += chars
            refit()
        }
    }

    // the sheet shrinks to its matches — re-measure and keep the centre
    private func refit() {
        guard let window = window else { needsDisplay = true; return }
        let size = measure()
        let c = NSPoint(x: window.frame.midX, y: window.frame.midY)
        frame = NSRect(origin: .zero, size: size)
        window.setFrame(NSRect(x: c.x - size.width / 2, y: c.y - size.height / 2,
                               width: size.width, height: size.height), display: true)
        needsDisplay = true
    }
}

var cheatWindow: CheatWindow?
var cheatPrevApp: NSRunningApplication?

func hideCheatsheet() {
    cheatWindow?.orderOut(nil)
    cheatWindow = nil
    // hand focus back to whoever had it before the sheet took key
    cheatPrevApp?.activate()
    cheatPrevApp = nil
}

func toggleCheatsheet() {
    if cheatWindow != nil { hideCheatsheet(); return }
    let entries = cheatEntries()
    guard !entries.isEmpty else {
        tlog("cheatsheet: no bindings parsed from omniwm settings.toml")
        return
    }
    let view = CheatsheetView(frame: .zero)
    view.entries = entries
    let size = view.measure()
    view.frame = NSRect(origin: .zero, size: size)
    // centred on the display holding the cursor, like every other
    // full-surface thing here
    let mouse = NSEvent.mouseLocation
    let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main!
    let window = CheatWindow(
        contentRect: NSRect(x: screen.frame.midX - size.width / 2,
                            y: screen.frame.midY - size.height / 2,
                            width: size.width, height: size.height),
        styleMask: .borderless, backing: .buffered, defer: false)
    window.isOpaque = false
    window.backgroundColor = .clear
    window.hasShadow = true
    window.level = .popUpMenu
    window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
    window.contentView = view
    // take key so typing filters — remember the app that had focus, the
    // close path activates it again
    cheatPrevApp = NSWorkspace.shared.frontmostApplication
    NSApp.activate(ignoringOtherApps: true)
    window.makeKeyAndOrderFront(nil)
    window.makeFirstResponder(view)
    cheatWindow = window
    tlog("cheatsheet: \(entries.count) bindings")
}

// --- view -----------------------------------------------------------------

// Text positioning, done properly.
//
// `NSString.size(withAttributes:)` returns the TYPOGRAPHIC box — advance
// width and line height — which is what you want to flow a paragraph and
// exactly wrong for centring one glyph in a pill. A glyph's ink does not
// fill its advance (Nerd Font icons carry lopsided side bearings), and a
// line box reserves descender room that digits never use. Measured on the
// live bar, that put the wifi glyph 4 px right of centre and every label
// about 1 px high.
//
// So: icons centre on their INK box, text centres on CAP HEIGHT. Cap
// height rather than ink for text because it does not move when the
// content changes — "28°C" and "8:05 PM" sit on the same baseline.
func inkBox(_ s: String, _ font: NSFont) -> CGRect {
    if s == "bt" { return CGRect(origin: .zero, size: bluetoothRune(font).size) }
    if s.hasPrefix("ts") { return CGRect(x: 0, y: 0, width: font.pointSize, height: font.pointSize) }
    if s.hasPrefix("key:") { return CGRect(origin: .zero, size: keyBadge(s, font).size) }
    if s.hasPrefix("donut:") { return CGRect(x: 0, y: 0, width: font.pointSize, height: font.pointSize) }
    if let img = sfSymbol(s, font) { return CGRect(origin: .zero, size: img.size) }
    let line = CTLineCreateWithAttributedString(
        NSAttributedString(string: s, attributes: [.font: font]))
    return CTLineGetImageBounds(line, nil) // baseline at y = 0
}

func advance(_ s: String, _ font: NSFont) -> CGFloat {
    let line = CTLineCreateWithAttributedString(
        NSAttributedString(string: s, attributes: [.font: font]))
    return CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
}

// draws with `origin` as the BASELINE origin, which is the only anchor
// that means the same thing for every string
func drawLine(_ s: String, _ font: NSFont, _ color: NSColor, baseline origin: CGPoint) {
    guard !s.isEmpty, let ctx = NSGraphicsContext.current?.cgContext else { return }
    let line = CTLineCreateWithAttributedString(NSAttributedString(
        string: s, attributes: [.font: font, .foregroundColor: color]))
    ctx.textPosition = origin
    CTLineDraw(line, ctx)
}

// one glyph, centred on its ink in both axes
// "sf:<name>" is an SF Symbol drawn at the font's point size and tinted
// like text; anything else is a font glyph
func sfSymbol(_ s: String, _ font: NSFont, _ color: NSColor? = nil) -> NSImage? {
    guard s.hasPrefix("sf:") else { return nil }
    var config = NSImage.SymbolConfiguration(pointSize: font.pointSize, weight: .medium)
    if let color { config = config.applying(.init(paletteColors: [color])) }
    return NSImage(systemSymbolName: String(s.dropFirst(3)), accessibilityDescription: nil)?
        .withSymbolConfiguration(config)
}

// SF Symbols has no Bluetooth mark, so "bt" is drawn: the rune as one
// stroke, sized and weighted to sit with the symbols around it
func bluetoothRune(_ font: NSFont) -> (path: NSBezierPath, size: NSSize) {
    let h = font.pointSize * 0.95, a = h * 0.26, b = h * 0.25
    let p = NSBezierPath()
    p.move(to: NSPoint(x: -a, y: -b))
    p.line(to: NSPoint(x: a, y: b))
    p.line(to: NSPoint(x: 0, y: h / 2))
    p.line(to: NSPoint(x: 0, y: -h / 2))
    p.line(to: NSPoint(x: a, y: -b))
    p.line(to: NSPoint(x: -a, y: b))
    p.lineWidth = max(1.4, font.pointSize / 10)
    p.lineJoinStyle = .round
    p.lineCapStyle = .round
    return (p, NSSize(width: a * 2 + p.lineWidth, height: h + p.lineWidth))
}

// "key:<text>" is a keycap: a filled rounded plate, the text in the bar's background colour
func keyBadge(_ s: String, _ font: NSFont) -> (text: String, font: NSFont, size: NSSize) {
    let text = String(s.dropFirst(4)), f = nerdFont("Bold", (font.pointSize * 0.62).rounded())
    return (text, f, NSSize(width: (advance(text, f) + 8).rounded(), height: font.pointSize))
}

// "donut:<0...1>" is a progress ring the size of a glyph
func drawIcon(_ s: String, _ font: NSFont, _ color: NSColor, centeredIn box: CGRect) {
    if s.hasPrefix("donut:"), let f = Double(s.dropFirst(6)) {
        let d = font.pointSize, lw = max(2, d / 6), r = (d - lw) / 2
        let c = NSPoint(x: box.midX.rounded(), y: box.midY.rounded())
        let track = NSBezierPath()
        track.appendArc(withCenter: c, radius: r, startAngle: 0, endAngle: 360)
        track.lineWidth = lw
        palette.label.withAlphaComponent(0.2).setStroke()
        track.stroke()
        let arc = NSBezierPath()
        arc.appendArc(withCenter: c, radius: r, startAngle: 90,
                      endAngle: 90 - 360 * CGFloat(min(max(f, 0), 1)), clockwise: true)
        arc.lineWidth = lw
        arc.lineCapStyle = .round
        color.setStroke()
        if f > 0 { arc.stroke() }
        return
    }
    if s.hasPrefix("key:") {
        let k = keyBadge(s, font)
        let r = NSRect(x: (box.midX - k.size.width / 2).rounded(), y: (box.midY - k.size.height / 2).rounded(),
                       width: k.size.width, height: k.size.height)
        color.setFill()
        NSBezierPath(roundedRect: r, xRadius: 3.5, yRadius: 3.5).fill()
        drawText(k.text, k.font, palette.barBG, centeredIn: r)
        return
    }
    // "ts" is the Tailscale mark: a 3x3 dot grid, the T lit; "ts:off" is all dim
    if s.hasPrefix("ts") {
        let step = font.pointSize * 0.34, r = font.pointSize * 0.12
        for row in -1...1 {
            for col in -1...1 {
                let lit = s == "ts" && (row == 0 || (row == -1 && col == 0))
                color.withAlphaComponent(lit ? 1 : 0.3).setFill()
                NSBezierPath(ovalIn: NSRect(x: box.midX.rounded() + CGFloat(col) * step - r,
                                            y: box.midY.rounded() + CGFloat(row) * step - r,
                                            width: r * 2, height: r * 2)).fill()
            }
        }
        return
    }
    if s == "bt" {
        let rune = bluetoothRune(font)
        rune.path.transform(using: AffineTransform(translationByX: box.midX.rounded(), byY: box.midY.rounded()))
        color.setStroke()
        rune.path.stroke()
        return
    }
    if let img = sfSymbol(s, font, color) {
        img.draw(in: NSRect(x: (box.midX - img.size.width / 2).rounded(),
                            y: (box.midY - img.size.height / 2).rounded(),
                            width: img.size.width, height: img.size.height))
        return
    }
    let ink = inkBox(s, font)
    drawLine(s, font, color,
             baseline: CGPoint(x: box.midX - ink.midX, y: box.midY - ink.midY))
}

// a text run: advance-centred across, cap-height-centred down
func drawText(_ s: String, _ font: NSFont, _ color: NSColor, centeredIn box: CGRect) {
    drawLine(s, font, color,
             baseline: CGPoint(x: box.midX - advance(s, font) / 2,
                               y: box.midY - font.capHeight / 2))
}

func drawText(_ s: String, _ font: NSFont, _ color: NSColor, leftAt x: CGFloat, midY: CGFloat) {
    drawLine(s, font, color, baseline: CGPoint(x: x, y: midY - font.capHeight / 2))
}

// Icons come from the running app and are cached by name: a redraw must
// not walk the process list.
var iconCache: [String: NSImage] = [:]
func appIcon(_ name: String) -> NSImage? {
    if let cached = iconCache[name] { return cached }
    guard let icon = NSWorkspace.shared.runningApplications
        .first(where: { $0.localizedName == name })?.icon else { return nil }
    iconCache[name] = icon
    return icon
}

// The terminal the activity pill opens btop in. install.sh writes the
// RESOLVED choice (apps.local.conf overrides already applied) next to the
// other daemon configs, because a launchd agent cannot read the repo when
// the clone sits under ~/Documents — which is exactly where this one is.
let terminalApp: String = {
    let config = URL(fileURLWithPath: NSHomeDirectory())
        .appendingPathComponent(".config/statusbar/apps.conf")
    guard let text = try? String(contentsOf: config, encoding: .utf8) else { return "Ghostty" }
    for line in text.split(separator: "\n") where line.hasPrefix("TERMINAL=") {
        return line.dropFirst("TERMINAL=".count)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\" "))
    }
    return "Ghostty"
}()

final class BarView: NSView {
    weak var surface: BarSurface?
    var chipRects: [(String, NSRect)] = []
    var winRects: [(String, NSRect)] = [] // window id -> its icon, checked before chips
    var itemRects: [(String, NSRect)] = []
    var mediaRects: [(String, NSRect)] = []
    var appleRect: NSRect = .zero

    override var isFlipped: Bool { false }

    // the media capsule: transport glyphs then the title, one pill. Its
    // width is measured, not cached — sketchybar needs an md5-keyed width
    // cache here only because it cannot measure text before laying out.
    // The capsule was measured from a glyph string with spaces in it and
    // then drawn glyph-by-glyph with different spacing, so the pill came
    // out 7 px wider than its contents. One layout, used by both.
    private func mediaGlyphs() -> [(String, String)] {
        [("prev", "󰒮"), ("play", model.media.playing ? "󰏤" : "󰐊"), ("next", "󰒭")]
    }

    // Positions first, size second: the pill is as wide as what it holds
    // plus equal padding, so the two can never disagree. Both ends measure
    // INK, so the trailing edge is not padded by a character's unused
    // advance the way the leading edge is not.
    private func mediaLayout(_ titleFont: NSFont, _ iconFont: NSFont)
        -> (width: CGFloat, glyphs: [(String, String, CGFloat, CGFloat)], titleX: CGFloat) {
        var x: CGFloat = 10
        var placed: [(String, String, CGFloat, CGFloat)] = []
        for (name, glyph) in mediaGlyphs() {
            let w = inkBox(glyph, iconFont).width
            placed.append((name, glyph, x, w))
            x += w + 6
        }
        x += 6 // transport-to-title gap, on top of the 6 already added
        let titleX = x
        let ink = inkBox(clippedTitle, titleFont)
        return (titleX + ink.maxX + 10, placed, titleX)
    }

    private func mediaSize(_ titleFont: NSFont, _ iconFont: NSFont) -> CGFloat {
        guard model.media.running, !model.media.title.isEmpty else { return 0 }
        return mediaLayout(titleFont, iconFont).width
    }

    private var clippedTitle: String {
        let limit = (surface?.notched ?? false) ? 20 : 28
        let title = model.media.title
        return title.count <= limit ? title : String(title.prefix(limit - 1)) + "…"
    }

    private func drawMedia(at origin: CGFloat, _ titleFont: NSFont, _ iconFont: NSFont) {
        guard model.media.running, !model.media.title.isEmpty else { return }
        let width = mediaSize(titleFont, iconFont)
        let pill = NSRect(x: origin, y: (BAR_HEIGHT - PILL_HEIGHT) / 2, width: width, height: PILL_HEIGHT)

        let layout = mediaLayout(titleFont, iconFont)
        for (name, glyph, dx, w) in layout.glyphs {
            drawIcon(glyph, iconFont, palette.label,
                     centeredIn: NSRect(x: pill.minX + dx, y: pill.minY, width: w, height: pill.height))
            mediaRects.append((name, NSRect(x: pill.minX + dx - 4, y: 0, width: w + 8, height: BAR_HEIGHT)))
        }
        drawText(clippedTitle, titleFont, palette.label,
                 leftAt: pill.minX + layout.titleX, midY: pill.midY)
        mediaRects.append(("title", NSRect(x: pill.minX + layout.titleX, y: 0,
                                           width: advance(clippedTitle, titleFont), height: BAR_HEIGHT)))
    }

    private func draw(_ s: String, _ font: NSFont, _ color: NSColor, centeredIn box: NSRect) {
        drawText(s, font, color, centeredIn: box)
    }

    // focus progress per window, 0...1, eased towards its target a frame
    // at a time: the focused icon grows and brightens instead of snapping
    private var winAnim: [String: CGFloat] = [:]

    override func draw(_ dirtyRect: NSRect) {
        var nextAnim: [String: CGFloat] = [:]
        var animating = false
        chipRects.removeAll()
        winRects.removeAll()
        itemRects.removeAll()
        mediaRects.removeAll()
        let chipFont = nerdFont("SemiBold", 13)
        let iconFont = nerdFont("Bold", ICON_SIZE)
        guard let surface else { return }
        // one solid strip, no per-item islands
        palette.barBG.setFill()
        bounds.fill()

        // workspace chips, in one bracket — this display's set only.
        // Undocked, force-assignment parks the GUEST set (11-19) on the
        // single display, where its empty slots would render as
        // duplicate digits — so they are hidden and an empty primary
        // keeps its slot to hold the row at 1..9. Docked, this
        // surface's list IS its own set: every slot belongs on the row,
        // and filtering left the laptop showing two lonely icons.
        let shown = surfaces.count > 1 ? surface.workspaces
            : surface.workspaces.filter {
                $0.count == 1 || model.occupied.contains($0) || $0 == model.focused
            }
        // apple pill: the system menu the hidden native menu bar carried
        let appleGlyph = "sf:apple.logo"
        let appleFont = nerdFont("Bold", 15)
        // A square, like the icon-only pills at the other end. The left
        // edge stays at PAD_LEFT, so only the inner edge moves.
        let appleW = PILL_HEIGHT
        let apple = NSRect(x: PAD_LEFT, y: (BAR_HEIGHT - PILL_HEIGHT) / 2, width: appleW, height: PILL_HEIGHT)
        drawIcon(appleGlyph, appleFont, palette.accent, centeredIn: apple)
        appleRect = NSRect(x: apple.minX, y: 0, width: appleW, height: BAR_HEIGHT)

        // one pill per workspace, like OmniWM's own bar: label, then an
        // icon per window. Floating windows and OmniWM's excluded apps are
        // already dropped by the time names reach model.apps.
        var x = apple.maxX + 10
        let chipsStart = x
        for ws in shown {
            let apps = model.apps[ws] ?? []
            let iconsW = apps.isEmpty ? 0 : CGFloat(apps.count) * (APP_ICON_SIZE + APP_ICON_GAP) + 4
            let chip = NSRect(x: x, y: (BAR_HEIGHT - PILL_HEIGHT) / 2,
                              width: CHIP_BOX + iconsW + CHIP_PAD * 2, height: PILL_HEIGHT)
            // each display marks the workspace IT is showing, not the
            // globally focused one
            let active = ws == surface.visible
            // OmniWM-bar style: the active workspace is outlined, not
            // filled, and everything outside it sits back at half strength
            if active {
                let plate = NSBezierPath(roundedRect: chip.insetBy(dx: 0.5, dy: 0.5), xRadius: RADIUS, yRadius: RADIUS)
                palette.accent.withAlphaComponent(0.12).setFill()
                plate.fill()
                palette.accent.setStroke()
                plate.stroke()
            }
            let tint: NSColor = active ? palette.accent : palette.muted
            let fade: CGFloat = active ? 1 : 0.5
            let labelBox = NSRect(x: chip.minX + CHIP_PAD, y: 0, width: CHIP_BOX, height: BAR_HEIGHT)
            switch workspaceIconConfig.icon(for: ws) {
            case .some(.glyph(let glyph)):
                drawIcon(glyph, iconFont, tint, centeredIn: labelBox)
            case .some(.image(let icon)):
                icon.draw(in: NSRect(x: labelBox.midX - 9, y: BAR_HEIGHT / 2 - 9, width: 18, height: 18),
                          from: .zero, operation: .sourceOver, fraction: fade)
            case .some(.unavailable), .none:
                draw(String(ws.suffix(1)), chipFont, tint, centeredIn: labelBox)
            }
            var ix = labelBox.maxX + 2
            for win in apps {
                let r = NSRect(x: ix, y: (BAR_HEIGHT - APP_ICON_SIZE) / 2, width: APP_ICON_SIZE, height: APP_ICON_SIZE)
                // only the focused window's icon is at full strength, and 1.1x
                let target: CGFloat = win.focused ? 1 : 0
                var t = winAnim[win.id] ?? target
                if t != target {
                    t = target > t ? min(target, t + 2.0 / 9) : max(target, t - 2.0 / 9) // ~75 ms at 60 fps
                    animating = animating || t != target
                }
                nextAnim[win.id] = t
                let e = t * t * (3 - 2 * t) // smoothstep
                let grow = APP_ICON_SIZE * 0.05 * e
                appIcon(win.app)?.draw(in: r.insetBy(dx: -grow, dy: -grow), from: .zero,
                                       operation: .sourceOver, fraction: 0.5 + 0.5 * e)
                winRects.append((win.id, NSRect(x: r.minX - APP_ICON_GAP / 2, y: 0,
                                                width: APP_ICON_SIZE + APP_ICON_GAP, height: BAR_HEIGHT)))
                ix += APP_ICON_SIZE + APP_ICON_GAP
            }
            chipRects.append((ws, NSRect(x: chip.minX, y: 0, width: chip.width, height: BAR_HEIGHT)))
            x = chip.maxX + CHIP_GAP
        }
        winAnim = nextAnim
        if animating {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 / 60) { [weak self] in self?.needsDisplay = true }
        }
        let bracket = NSRect(x: chipsStart, y: 0, width: max(0, x - CHIP_GAP - chipsStart), height: BAR_HEIGHT)

        // no front-app pill: the native menu bar (auto-hide, over the bar)
        // already names the app and carries its menus
        let leftEdge = bracket.maxX
        appPillRect = .zero

        // media: centred where there is room, in the left cluster where a
        // notch owns the middle
        let mediaW = mediaSize(chipFont, iconFont)
        if mediaW > 0 {
            drawMedia(at: surface.notched ? leftEdge + GAP : (bounds.width - mediaW) / 2,
                      chipFont, iconFont)
        }

        // right cluster: laid out from the right edge inwards, so a pill
        // changing width never shifts the ones outside it
        var cursor = bounds.maxX - PAD_LEFT
        for name in RIGHT_ITEMS.reversed() {
            guard let item = rightItems[name], item.drawing,
                  !(item.icon.isEmpty && item.label.isEmpty) else { continue }
            let labelFont = chipFont
            let iconColor = item.iconColor.map { palette[keyPath: $0] } ?? palette.label
            let hasIcon = !item.icon.isEmpty
            let hasLabel = !item.label.isEmpty
            // An icon-only pill centres the glyph on its INK, with the same
            // side padding as the rest — as a fixed square, two neighbouring
            // icons sat 9 pt apart against 22 everywhere else. A pill with a label flows
            // icon-then-text, and the gap between them exists
            // only when both do — the weather pill has no icon (its glyph
            // lives in the label) and inherited the gap anyway, which is the
            // 7 px it sat right of centre by.
            let iconInk = hasIcon ? inkBox(item.icon, iconFont).width : 0
            let labelAdv = hasLabel ? advance(item.label, labelFont) : 0
            let innerGap: CGFloat = hasIcon && hasLabel ? ICON_GAP : 0
            let square = hasIcon && !hasLabel
            let width = ITEM_PAD + iconInk + innerGap + labelAdv + ITEM_PAD
            let pill = NSRect(x: cursor - width, y: (BAR_HEIGHT - PILL_HEIGHT) / 2,
                              width: width, height: PILL_HEIGHT)
            if hasIcon {
                drawIcon(item.icon, iconFont, iconColor,
                         centeredIn: square ? pill
                             : NSRect(x: pill.minX + ITEM_PAD, y: pill.minY,
                                      width: iconInk, height: pill.height))
            }
            if hasLabel {
                drawText(item.label, labelFont, palette.label,
                         leftAt: pill.minX + ITEM_PAD + iconInk + innerGap, midY: pill.midY)
            }
            itemRects.append((name, NSRect(x: pill.minX, y: 0, width: width, height: BAR_HEIGHT)))
            cursor = pill.minX - ITEM_GAP
        }
    }


    // Tracking areas, not a poll and not a global monitor: a global
    // monitor stops delivering once this app is itself active, which is
    // exactly what clicking the bar makes it.
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: bounds,
                                       options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                       owner: self))
    }

    override func mouseExited(with event: NSEvent) { scheduleHullCheck() }

    private func hit(_ event: NSEvent) -> String? {
        let p = convert(event.locationInWindow, from: nil)
        return itemRects.first(where: { $0.1.contains(p) })?.0
    }

    var appPillRect = NSRect.zero

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        if appPillRect != .zero, appPillRect.contains(p), let surface {
            appMenuStack.removeAll()
            // clicking the bar deactivated the app, which makes its menu
            // items read disabled and presses land nowhere — hand focus
            // straight back while our popup (never key) stays up
            NSWorkspace.shared.runningApplications
                .first { $0.localizedName == model.frontApp }?
                .activate()
            showPopup("appmenu", under: window?.convertToScreen(convert(appPillRect, to: nil)) ?? appPillRect,
                      on: surface, alignLeft: true)
            return
        }
        if appleRect.contains(p), let surface {
            appMenuStack.removeAll()
            NSWorkspace.shared.runningApplications
                .first { $0.localizedName == model.frontApp }?
                .activate()
            // aligned to its LEFT edge: it is the leftmost thing on the bar,
            // so a right-aligned popup would hang off the screen
            showPopup("apple", under: window?.convertToScreen(convert(appleRect, to: nil)) ?? appleRect,
                      on: surface, alignLeft: true)
            return
        }
        if let id = winRects.first(where: { $0.1.contains(p) })?.0 {
            DispatchQueue.global(qos: .userInitiated).async { focusWindow(id) }
            return
        }
        if let ws = chipRects.first(where: { $0.1.contains(p) })?.0 {
            DispatchQueue.global(qos: .userInitiated).async { focusWorkspace(ws) }
            return
        }
        if let part = mediaRects.first(where: { $0.1.contains(p) })?.0 {
            closePopup()
            switch part {
            case "prev": spotify("previous track")
            case "play": spotify("playpause")
            case "next": spotify("next track")
            default:
                if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: spotifyBundleID) {
                    NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
                }
            }
            return
        }
        guard let name = hit(event), let rect = itemRects.first(where: { $0.0 == name })?.1 else {
            closePopup()
            return
        }
        // an item with a popup toggles it; the rest still act directly
        if !popupRows(for: name).isEmpty, let surface {
            let anchor = window?.convertToScreen(convert(rect, to: nil)) ?? rect
            showPopup(name, under: anchor, on: surface)
            return
        }
        closePopup()
        switch name {
        case "battery":
            NSWorkspace.shared.open(
                URL(string: "x-apple.systempreferences:com.apple.Battery-Settings.extension")!)
        case "activity":
            DispatchQueue.global(qos: .userInitiated).async {
                _ = shell("/usr/bin/open", ["-na", terminalApp, "--args", "--title=statusbar-activity", "-e", "btop"])
            }
        default: break
        }
    }

    // A trackpad flick delivers dozens of precise events plus a momentum
    // tail; stepping 5% on each raced through the whole range. Momentum is
    // dropped and precise deltas accumulate until a notch's worth of finger
    // travel has passed — a clicky wheel already arrives one notch at a time.
    private var scrollAccum: CGFloat = 0

    override func scrollWheel(with event: NSEvent) {
        guard let name = hit(event) else { return }
        if !event.momentumPhase.isEmpty { return }
        if event.phase == .began { scrollAccum = 0 }
        scrollAccum += event.scrollingDeltaY
        let notch: CGFloat = event.hasPreciseScrollingDeltas ? 20 : 1
        if abs(scrollAccum) < notch { return }
        let step = scrollAccum > 0 ? 5 : -5
        scrollAccum = 0
        switch name {
        case "volume":
            guard let v = readVolume() else { return }
            writeVolume(v.percent + step) // the CoreAudio listener repaints
        case "brightness":
            var value: Float = 0
            guard DSGetBrightness(builtinDisplayID(), &value) == 0 else { return }
            // one continuous scale: the backlight down to 0, then shade
            if step < 0, value <= 0.001 {
                setShade(shade + 0.08)
            } else if step > 0, shade > 0.001 {
                setShade(shade - 0.08) // come out of shade before raising the backlight
            } else {
                _ = DSSetBrightness(builtinDisplayID(), min(1, max(0, value + Float(step) / 100)))
                updateBrightness()
            }
        default: break
        }
    }
}

// --- window ---------------------------------------------------------------

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

// AppKit pushes an ordinary window down out of the menu-bar strip, which
// is exactly where a bar belongs — 32 px lower than asked for, measured.
// Opting out of the constraint is the supported way to sit in it.
// An NSPanel with .nonactivatingPanel: a click on the bar reaches the view
// without activating this app, so the focused app keeps focus.
final class BarWindow: NSPanel {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
}

// The bar owns the top strip. STATUSBAR_STACK=1 drops it one bar-height
// so it can run alongside another bar for comparison, which is how this
// was built.
let stackOffset: CGFloat = ProcessInfo.processInfo.environment["STATUSBAR_STACK"] == nil ? 0 : BAR_HEIGHT

// One surface per display. Each owns its screen's workspace set and its
// own window; everything else it reads from the shared model.
final class BarSurface {
    var screen: NSScreen
    var monitorID: String
    var workspaces: [String] = []
    var mine: Set<String> = []
    var visible = ""
    let window: BarWindow
    let view: BarView

    // A notched display has no usable centre, so the media capsule joins
    // the left cluster there — the same rule the shell bar applies, but
    // read from the screen itself instead of asked of a helper.
    var notched: Bool { screen.safeAreaInsets.top > 0 }

    init(screen: NSScreen, monitorID: String) {
        self.screen = screen
        self.monitorID = monitorID
        let frame = NSRect(x: screen.frame.minX, y: screen.frame.maxY - BAR_HEIGHT - stackOffset,
                           width: screen.frame.width, height: BAR_HEIGHT)
        window = BarWindow(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel],
                           backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = BAR_LEVEL
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.acceptsMouseMovedEvents = true // tracking areas need the moves
        view = BarView(frame: NSRect(origin: .zero, size: frame.size))
        window.contentView = view
        view.surface = self
        if !fullscreenDisplays().contains(screenID(screen)) { window.orderFrontRegardless() }
    }

    func place() {
        let frame = NSRect(x: screen.frame.minX, y: screen.frame.maxY - BAR_HEIGHT - stackOffset,
                           width: screen.frame.width, height: BAR_HEIGHT)
        window.setFrame(frame, display: true)
        view.frame = NSRect(origin: .zero, size: frame.size)
    }
}

var surfaces: [BarSurface] = []

func screenID(_ screen: NSScreen) -> CGDirectDisplayID {
    (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
}

// Display ids are resolved by NAME every time the screens change.
func monitorIDs() -> [String: String] { // display name -> WM monitor id
    // OmniWM names monitors with NSScreen.localizedName (Monitor.current()
    // in its source), so the name join works; its ids stay opaque
    // ("display:…") and only ever meet the query payloads they came from.
    guard omniwmActive() else { return [:] }
    var map: [String: String] = [:]
    if let list = omniQuery("displays", ["--fields", "id,name"])?["displays"] as? [[String: Any]] {
        for d in list {
            if let id = d["id"] as? String, let name = d["name"] as? String { map[name] = id }
        }
    }
    return map
}

// A label no window manager gave: unique per display, and it matches no
// WM id, so the display's workspace pills stay empty until one answers.
func unresolvedID(_ screen: NSScreen) -> String { "unresolved:\(screenID(screen))" }

// One bar per display, always; the window manager only labels them. A
// display the manager does not list (not up yet, a login, a switch) is
// unresolved: its workspace pills stay empty rather than show another
// manager's state. reconcile() below asks again.
func rebuildSurfaces(_ ids: [String: String]) {
    var kept: [BarSurface] = []
    for screen in NSScreen.screens {
        let existing = surfaces.first(where: { screenID($0.screen) == screenID(screen) })
        let id = ids[screen.localizedName] ?? unresolvedID(screen)
        let label = id.hasPrefix("unresolved:") ? "no window manager yet" : "omniwm monitor \(id)"
        if let existing {
            if existing.monitorID != id {
                tlog("monitor: \(screen.localizedName) is now \(label) (was \(existing.monitorID))")
                existing.monitorID = id
                // the old manager's workspaces name nothing now, and apply()
                // keeps a list it is not given: clear them for the placeholder
                if id.hasPrefix("unresolved:") {
                    existing.workspaces = []
                    existing.mine = []
                    existing.visible = ""
                }
            }
            existing.screen = screen
            existing.place()
            kept.append(existing)
        } else {
            tlog("surface: \(screen.localizedName) -> \(label)\(screen.safeAreaInsets.top > 0 ? " (notched)" : "")")
            kept.append(BarSurface(screen: screen, monitorID: id))
        }
    }
    for gone in surfaces where !kept.contains(where: { $0 === gone }) {
        tlog("surface: \(gone.screen.localizedName) went away")
        gone.window.orderOut(nil)
    }
    surfaces = kept
}

func repaint() {
    // every caller is already on the main queue; display() is synchronous
    // so the timings below cover real drawing, not just invalidation
    MainActor.assumeIsolated {
        for surface in surfaces {
            surface.view.needsDisplay = true
            surface.view.display()
        }
    }
}

// --- fullscreen ------------------------------------------------------------
// A display is "fullscreen" when some app window spans its full width and
// reaches its top edge — tiled windows never do, the WM's outer gap keeps
// them under the bar. Covers native fullscreen (starts below the notch,
// hence the safe-area slack) and OmniWM's own toggle-fullscreen.
func fullscreenDisplays() -> Set<CGDirectDisplayID> {
    var covered: Set<CGDirectDisplayID> = []
    guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements],
                                                kCGNullWindowID) as? [[String: Any]] else { return covered }
    let me = Int(ProcessInfo.processInfo.processIdentifier)
    let primaryH = NSScreen.screens.first?.frame.height ?? 0
    for screen in NSScreen.screens {
        // CG space: origin top-left of the primary display
        let top = primaryH - screen.frame.maxY
        let slack = screen.safeAreaInsets.top + 2
        for w in list where (w[kCGWindowLayer as String] as? Int) == 0
            && (w[kCGWindowOwnerPID as String] as? Int) != me
            && ((w[kCGWindowAlpha as String] as? Double) ?? 1) > 0 {
            guard let b = w[kCGWindowBounds as String] as? [String: CGFloat],
                  let x = b["X"], let y = b["Y"], let width = b["Width"] else { continue }
            if abs(x - screen.frame.minX) < 2, width >= screen.frame.width - 2,
               y >= top - 2, y <= top + slack {
                covered.insert(screenID(screen))
                break
            }
        }
    }
    return covered
}

func updateBarVisibility() {
    let covered = fullscreenDisplays()
    for surface in surfaces {
        if covered.contains(screenID(surface.screen)) {
            surface.window.orderOut(nil)
            if openPopup != nil { closePopup() }
        } else {
            surface.window.orderFrontRegardless()
        }
    }
}

// a window-list read, not a subprocess: cheap enough to run on a short
// debounce after any window event
var visibilityPending: DispatchWorkItem?
func kickVisibility() {
    visibilityPending?.cancel()
    let work = DispatchWorkItem { updateBarVisibility() }
    visibilityPending = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
}

// --- signals --------------------------------------------------------------

// File watcher: .attrib catches a symlink swap
// that .write alone misses, and a delete/rename re-arms instead of going
// deaf for the rest of the daemon's life.
func watch(_ path: String, create: Bool, handler: @escaping () -> Void) {
    if create, !FileManager.default.fileExists(atPath: path) {
        FileManager.default.createFile(atPath: path, contents: nil)
    }
    let fd = open(path, O_EVTONLY)
    guard fd >= 0 else {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { watch(path, create: create, handler: handler) }
        return
    }
    let src = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd,
        eventMask: [.write, .attrib, .delete, .rename], queue: .main)
    src.setEventHandler {
        let ev = src.data
        handler()
        if ev.contains(.delete) || ev.contains(.rename) { src.cancel() }
    }
    src.setCancelHandler {
        close(fd)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { watch(path, create: create, handler: handler) }
    }
    src.resume()
}

// Super+K writes this; the bar has no key tap and should not grow one
let cheatPath = "/tmp/statusbar-cheatsheet"
watch(cheatPath, create: true) { toggleCheatsheet() }


// --- omniwm fast path -------------------------------------------------------
// A switch between two EMPTY workspaces moves no windows, so SkyLight
// says nothing. OmniWM publishes instead: its active-workspace
// channel emits one event per change. `watch … --exec /bin/cat` rather
// than `subscribe` because subscribe pretty-prints multi-line JSON while
// watch hands its child exactly one NDJSON line per event, and the child
// inherits this pipe (OmniWM docs/IPC-CLI.md, "watch") — so the stream
// arrives line-delimited and the bar's side never forks anything.

var omniWatch: Process?
var omniWatchBuffer = Data()

func omniWorkspaceBarEvent(_ line: Data) {
    // The workspace-bar channel, not active-workspace: measured 2026-08-29,
    // active-workspace (and focus) only fire when the FOCUSED WINDOW
    // changes, so every switch to or from an EMPTY workspace is silent —
    // OmniWM's own Super+8/9 left the pill frozen. Their bar highlights
    // empties, so its scene channel fires on every switch, and carries
    // per-monitor active flags plus each workspace's windows (occupancy
    // and the sole-app icon come free, no windows query).
    guard let root = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
          root["channel"] as? String == "workspace-bar",
          let payload = (root["result"] as? [String: Any])?["payload"] as? [String: Any],
          let monitors = payload["monitors"] as? [[String: Any]]
    else { return }
    let current = payload["interactionMonitorId"] as? String ?? ""
    let t0 = DispatchTime.now().uptimeNanoseconds
    var changed = false
    var occupied = Set<String>()
    var apps: [String: [BarWin]] = [:]
    var focusedNow = ""
    for m in monitors {
        guard let id = m["id"] as? String,
              let list = m["workspaces"] as? [[String: Any]] else { continue }
        var active = ""
        for w in list {
            guard let name = w["rawName"] as? String else { continue }
            if (w["isFocused"] as? Bool) == true { active = name }
            let wins = ((w["windows"] as? [[String: Any]]) ?? [])
                .filter { ($0["appName"] as? String)?.hasPrefix("statusbar") != true }
            if !wins.isEmpty {
                occupied.insert(name)
                apps[name] = wins.compactMap { w in
                    guard let app = w["appName"] as? String, let id = w["id"] as? String else { return nil }
                    return BarWin(app: app, id: id, focused: (w["isFocused"] as? Bool) == true)
                }
            }
        }
        guard !active.isEmpty else { continue }
        if id == current { focusedNow = active }
        for surface in surfaces where surface.monitorID == id && surface.visible != active {
            surface.visible = active
            changed = true
        }
    }
    if !focusedNow.isEmpty, model.focused != focusedNow { model.focused = focusedNow; changed = true }
    if model.occupied != occupied { model.occupied = occupied; changed = true }
    if model.apps != apps { model.apps = apps; changed = true }
    guard changed else { return }
    repaint()
    tlog(String(format: "switch %@ %.2f ms (omniwm)", focusedNow,
                Double(DispatchTime.now().uptimeNanoseconds - t0) / 1_000_000))
}

var omniWatchStarting = false
func startOmniWatch() {
    guard omniWatch == nil, !omniWatchStarting, omniwmActive() else { return }
    omniWatchStarting = true
    // a bar killed by launchd (kickstart -k is SIGKILL) leaves its
    // stream child alive under pid 1, one per restart — reap orphans
    // before spawning ours; -P 1 cannot touch a living bar's child.
    // pkill is waited for, so off the main thread.
    DispatchQueue.global(qos: .utility).async {
        let reap = Process()
        reap.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        reap.arguments = ["-P", "1", "-f", "omniwmctl watch workspace-bar"]
        try? reap.run()
        reap.waitUntilExit()
        DispatchQueue.main.async {
            omniWatchStarting = false
            guard omniWatch == nil, omniwmActive() else { return }
            spawnOmniWatch()
        }
    }
}

func spawnOmniWatch() {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: omniwmctlBin)
    p.arguments = ["watch", "workspace-bar", "--exec", "/bin/cat"]
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = FileHandle.nullDevice
    pipe.fileHandleForReading.readabilityHandler = { handle in
        let chunk = handle.availableData
        guard !chunk.isEmpty else { return }
        DispatchQueue.main.async {
            omniWatchBuffer.append(chunk)
            while let nl = omniWatchBuffer.firstIndex(of: 0x0A) {
                let line = Data(omniWatchBuffer[omniWatchBuffer.startIndex..<nl])
                omniWatchBuffer = Data(omniWatchBuffer[omniWatchBuffer.index(after: nl)...])
                omniWorkspaceBarEvent(line)
            }
        }
    }
    p.terminationHandler = { proc in
        DispatchQueue.main.async {
            pipe.fileHandleForReading.readabilityHandler = nil
            guard omniWatch === proc else { return } // a newer watch took over
            omniWatch = nil
            // OmniWM restarting, or its IPC server not up yet, drops the
            // stream: keep knocking while OmniWM is the one running
            guard omniwmActive() else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { startOmniWatch() }
        }
    }
    guard (try? p.run()) != nil else { return }
    omniWatch = p
    tlog("omniwm: watching workspace-bar")
}

func stopOmniWatch() {
    guard let p = omniWatch else { return }
    omniWatch = nil // before terminate, so the handler cannot restart it
    p.terminate()
}

// ONE routine tracks OmniWM coming and going. It is LSUIElement, so
// NSWorkspace posts no launch or quit for it; the list of running apps is
// KVO-observable and does change, which is the event. It starts or stops
// the OmniWM watch, drops stale labels when it goes away, asks it for
// display ids and its focused workspace off the main thread, and while a display is unresolved
// or the focused workspace is not yet confirmed retries with backoff
// (1, 2, 4, 8, 15, 30 s, then stops). An app switch, a screen change or
// OmniWM starting or stopping start it again from the first step.
var labelsFromOmniWM = omniwmActive()
let reconcileBackoff: [Double] = [1, 2, 4, 8, 15, 30]
var reconcileStep = 0
var reconcileRetry: DispatchWorkItem?
func anyUnresolved() -> Bool { surfaces.contains { $0.monitorID.hasPrefix("unresolved:") } }
// the focused workspace as OmniWM itself reports it (blocking: off-main)
func managerFocused() -> String {
    (omniQuery("workspaces", ["--focused", "--fields", "raw-name"])?["workspaces"]
        as? [[String: Any]])?.first?["rawName"] as? String ?? ""
}
// After a switch the ring shows what the OLD manager had focused, and the
// new one's stream can start before it answers at all. So reconcile asks the
// new manager directly, off the main thread, and keeps asking on its own
// backoff until two answers in a row agree with the ring. An empty answer
// (still starting, or a missed reply) does not count.
var refocusAgreed = 2   // 2 = nothing to confirm
func reconcile(_ why: String, restart: Bool = true) {
    let omni = omniwmActive()
    if omni { startOmniWatch() } else { stopOmniWatch() }
    // after a switch, or once a display resolves, the ring still shows the
    // workspace the OLD manager had focused: ask the new one
    if omni != labelsFromOmniWM || anyUnresolved() { refocusAgreed = 0 }
    let refocus = refocusAgreed < 2
    if omni != labelsFromOmniWM {
        labelsFromOmniWM = omni
        tlog("wm: omniwm \(omni ? "up" : "down") (\(why)), relabelling the bar")
        rebuildSurfaces([:])
        repaint()
    }
    if restart { reconcileStep = 0 }
    reconcileRetry?.cancel()
    reconcileRetry = nil
    rebuildQueue.async {
        let ids = monitorIDs()
        let focused = refocus && omni ? managerFocused() : ""
        DispatchQueue.main.async {
            guard omniwmActive() == omni else { return } // a newer call owns it
            rebuildSurfaces(ids)
            if refocus, !focused.isEmpty {
                if focused == model.focused {
                    refocusAgreed += 1
                } else {
                    setFocused(focused)
                    repaint()
                    tlog("wm: focused workspace \(focused), from the manager")
                    refocusAgreed = 0
                }
            }
            kickRebuild()
            let unresolved = anyUnresolved()
            guard unresolved || refocusAgreed < 2, reconcileStep < reconcileBackoff.count else { return }
            let delay = reconcileBackoff[reconcileStep]
            reconcileStep += 1
            tlog("wm: \(unresolved ? "display unresolved" : "focus not confirmed"), asking again in \(Int(delay)) s")
            let retry = DispatchWorkItem { reconcile("retry", restart: false) }
            // two calls in flight both land here: keep only the newest retry
            reconcileRetry?.cancel()
            reconcileRetry = retry
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: retry)
        }
    }
}
let wmAppsWatch = NSWorkspace.shared.observe(\.runningApplications, options: []) { _, _ in
    DispatchQueue.main.async {
        guard omniwmActive() != labelsFromOmniWM else { return }
        reconcile("wm-apps")
    }
}

// native fullscreen lives on its own Space: switching to it is the event
NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main
) { _ in kickVisibility() }

// front app: a notification, not a poll and not a script
NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
) { note in
    let t0 = DispatchTime.now().uptimeNanoseconds
    guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
          let name = app.localizedName, name != model.frontApp,
          app.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return }
    // someone is using the Mac: an unresolved display is worth asking about now
    if anyUnresolved() { reconcile("activation") }
    kickVisibility()
    model.frontApp = name
    repaint()
    let ms = Double(DispatchTime.now().uptimeNanoseconds - t0) / 1_000_000
    tlog(String(format: "frontapp %@ %.2f ms", name, ms))
}


// Displays come and go: re-resolve which OmniWM display this screen is
// now, move the window onto it, and rebuild. Screen parameters arrive
// before the arrangement settles, so give it a beat (borders.swift learnt
// the same lesson with a stale CG-to-Cocoa flip after a replug).
NotificationCenter.default.addObserver(
    forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
) { _ in
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        closePopup() // its anchor may not exist any more
        var known: [String: String] = [:] // two identical monitors share a name
        for surface in surfaces { known[surface.screen.localizedName] = surface.monitorID }
        rebuildSurfaces(known)
        applyShade() // a new display arrives at full output
        // the WM can adopt the new display after this grace: reconcile asks
        // again until it answers, with its own backoff
        reconcile("screens")
    }
}


// window create/destroy: the only thing that needs the slow path, and it
// is debounced off the critical path
var pending: DispatchWorkItem?
func kickRebuild() {
    pending?.cancel()
    let w = DispatchWorkItem {
        rebuildQueue.async {
            let t0 = DispatchTime.now().uptimeNanoseconds
            let snapshot = fetchSnapshot()
            let fetched = Double(DispatchTime.now().uptimeNanoseconds - t0) / 1_000_000
            DispatchQueue.main.async {
                let t1 = DispatchTime.now().uptimeNanoseconds
                guard apply(snapshot) else { return } // nothing moved
                repaint()
                let drawn = Double(DispatchTime.now().uptimeNanoseconds - t1) / 1_000_000
                tlog(String(format: "rebuild fetch %.2f ms (off-main) + paint %.2f ms", fetched, drawn))
            }
        }
    }
    pending = w
    // 0.3s was priced against a snapshot that cost four subprocesses;
    // one call later the coalescing window can be the part a person
    // actually waits through
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: w)
}

let cid = SLSMainConnectionID()
// move and resize only fire for SUBSCRIBED windows, and going fullscreen
// is a resize — so the subscription set is kept equal to every normal
// window, refreshed whenever one is created or destroyed (borders.swift's
// recipe, and its reason).
var subscribed: Set<UInt32> = []
func rebuildSubscriptions() {
    guard let list = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]]
    else { return }
    var wids: [UInt32] = []
    for w in list where (w[kCGWindowLayer as String] as? Int) == 0 {
        if let n = w[kCGWindowNumber as String] as? Int { wids.append(UInt32(n)) }
    }
    let set = Set(wids)
    guard set != subscribed, !wids.isEmpty else { return }
    subscribed = set
    _ = wids.withUnsafeBufferPointer {
        SLSRequestNotificationsForWindows(cid, $0.baseAddress!, Int32(wids.count))
    }
}

let notify: NotifyProc = { event, _, _, _ in
    DispatchQueue.main.async {
        if event == EVENT_WINDOW_CREATE || event == EVENT_WINDOW_DESTROY {
            kickRebuild()
            rebuildSubscriptions()
        } else if event == EVENT_WINDOW_ORDER || event == EVENT_WINDOW_VISIBILITY {
            // the chips are only as fresh as this: a window changing
            // workspace shows up here and nowhere else. A plain
            // workspace switch lands here too and fetches a snapshot
            // that changed nothing, which apply() reports so the
            // repaint is skipped.
            kickRebuild()
        }
        kickVisibility()
    }
}
_ = SLSRegisterNotifyProc(notify, EVENT_WINDOW_CREATE, nil)
_ = SLSRegisterNotifyProc(notify, EVENT_WINDOW_DESTROY, nil)
_ = SLSRegisterNotifyProc(notify, EVENT_WINDOW_MOVE, nil)
_ = SLSRegisterNotifyProc(notify, EVENT_WINDOW_RESIZE, nil)
_ = SLSRegisterNotifyProc(notify, EVENT_WINDOW_ORDER, nil)
_ = SLSRegisterNotifyProc(notify, EVENT_WINDOW_VISIBILITY, nil)
rebuildSubscriptions()
var eventPort: mach_port_t = 0
if SLSGetEventPort(cid, &eventPort).rawValue == 0, eventPort != 0 {
    let drain = DispatchSource.makeMachReceiveSource(port: eventPort, queue: .main)
    drain.setEventHandler { while let e = SLEventCreateNextEvent(SLSMainConnectionID()) { e.release() } }
    drain.resume()
}

// theme switches: repaint, never rebuild. `theme set` rewrites this
// directory's contents, which fires the watch on the directory itself.
watch(FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".config/theme").path, create: false) {
    let t0 = DispatchTime.now().uptimeNanoseconds
    palette = loadPalette()
    iconCache.removeAll()
    repaint()
    if cheatWindow != nil { hideCheatsheet(); toggleCheatsheet() } // repaint in the new palette
    let ms = Double(DispatchTime.now().uptimeNanoseconds - t0) / 1_000_000
    tlog(String(format: "theme %.2f ms", ms))
}

// --- popup guard -----------------------------------------------------------
// popup_guard.sh polls the cursor on a loop and greps item names to decide
// whether a popup should still be open. Here the cursor is a published
// event and the geometry is already known, so the rule is exact: a popup
// closes when the pointer is in neither the bar nor the popup — which is
// what "don't close it while I'm still in the bar" actually means.
// The check runs a beat after the pointer leaves either surface, because
// travelling from the bar to its popup crosses the gap between them and
// must not read as leaving.
func scheduleHullCheck() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
        if popupWindow != nil, pointerLeftTheHull() { closePopup() }
    }
}

func pointerLeftTheHull() -> Bool {
    guard let popup = popupWindow else { return false }
    let p = NSEvent.mouseLocation
    let slack: CGFloat = 6 // the gap between a bar and its popup
    if popup.frame.insetBy(dx: -slack, dy: -slack).contains(p) { return false }
    for surface in surfaces where surface.window.frame.insetBy(dx: 0, dy: -slack).contains(p) {
        return false
    }
    return true
}

// the monitor must be RETAINED — dropping the returned token deregisters
// it immediately, and the popup then never closes on its own
var popupGuardToken: Any?

popupGuardToken = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { _ in
    // a click that lands in another app dismisses the popup; hover-exit
    // is the tracking areas' job
    if popupWindow != nil, pointerLeftTheHull() { closePopup() }
}

// --- right-cluster publishers ---------------------------------------------

// battery: IOPS fires on capacity ticks too
let powerCallback: IOPowerSourceCallbackType = { _ in DispatchQueue.main.async { updateBattery() } }
if let src = IOPSNotificationCreateRunLoopSource(powerCallback, nil)?.takeRetainedValue() {
    CFRunLoopAddSource(CFRunLoopGetCurrent(), src, .defaultMode)
} else {
    tlog("IOPSNotificationCreateRunLoopSource failed — battery pill will not update")
}

// volume: listen on the current default output device, and re-attach when
// the default changes (plugging in headphones is a different device)
var volumeListeners: [(AudioObjectID, AudioObjectPropertyAddress, AudioObjectPropertyListenerBlock)] = []

func attachVolumeListeners() {
    for (object, address, block) in volumeListeners {
        var a = address
        AudioObjectRemovePropertyListenerBlock(object, &a, DispatchQueue.main, block)
    }
    volumeListeners.removeAll()

    let dev = defaultOutputDevice()
    guard dev != 0 else { return }
    let block: AudioObjectPropertyListenerBlock = { _, _ in updateVolume() }
    for selector in [kAudioDevicePropertyVolumeScalar, kAudioDevicePropertyMute] {
        var addr = AudioObjectPropertyAddress(mSelector: selector,
                                              mScope: kAudioDevicePropertyScopeOutput,
                                              mElement: kAudioObjectPropertyElementMain)
        if AudioObjectAddPropertyListenerBlock(dev, &addr, DispatchQueue.main, block) == noErr {
            volumeListeners.append((dev, addr, block))
        }
    }
    updateVolume()
}

var defaultDeviceAddress = AudioObjectPropertyAddress(
    mSelector: kAudioHardwarePropertyDefaultOutputDevice,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain)
AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject),
                                    &defaultDeviceAddress, DispatchQueue.main) { _, _ in
    attachVolumeListeners()
}
attachVolumeListeners()

// brightness: DisplayServices publishes, so the keyboard keys land here
// without the bar being told about them by anyone else
let brightnessProc: DSBrightnessProc = { _, _, _, _ in
    DispatchQueue.main.async { updateBrightness() }
}
if DSRegisterBrightnessNotifications(builtinDisplayID(), nil, brightnessProc) != 0 {
    tlog("brightness notifications unavailable — pill updates on scroll only")
}

// night shift: same idea one layer up — the schedule flipping it is a
// change nobody else would tell an open popup about
watchNightShift()

// network: the same SCDynamicStore keys the watcher uses
var storeContext = SCDynamicStoreContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
if let store = SCDynamicStoreCreate(nil, "statusbar" as CFString,
                                    { _, _, _ in DispatchQueue.main.async { updateWifi() } }, &storeContext) {
    SCDynamicStoreSetNotificationKeys(store, nil, [
        "State:/Network/Global/IPv4",
        "State:/Network/Interface/en.*/Link",
        "State:/Network/Interface/en.*/AirPort",
    ] as CFArray)
    if let src = SCDynamicStoreCreateRunLoopSource(nil, store, 0) {
        CFRunLoopAddSource(CFRunLoopGetCurrent(), src, .defaultMode)
    }
} else {
    tlog("SCDynamicStoreCreate failed — wifi pill will not update")
}

// location: the network name's price, same responsible-process rules
locationGate.start()

// bluetooth: gated on the privacy grant, which the watcher above also needs
bluetoothWatcher.start()

// waking clears the gamma table, so the shade has to be reasserted.
NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
) { _ in
    applyShade()
}

// media: Spotify broadcasts every state change itself, and the payload
// already carries the track — so the pill repaints without asking anyone
// anything. Launch and quit are the one pair it cannot announce.
DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name("\(spotifyBundleID).PlaybackStateChanged"), object: nil, queue: .main
) { note in updateMedia(from: note.userInfo) }

for event in [NSWorkspace.didLaunchApplicationNotification,
              NSWorkspace.didTerminateApplicationNotification] {
    NSWorkspace.shared.notificationCenter.addObserver(forName: event, object: nil, queue: .main) { note in
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == spotifyBundleID else { return }
        if event == NSWorkspace.didLaunchApplicationNotification { primeMedia() } else { updateMedia() }
    }
}

// clock and weather have no publisher to listen to. The clock ticks on
// the minute boundary rather than every 60 s from launch, so it never
// shows a stale minute.
func scheduleClock() {
    updateClock()
    let now = Date()
    let nextMinute = Calendar.current.nextDate(after: now, matching: DateComponents(second: 0),
                                               matchingPolicy: .nextTime) ?? now.addingTimeInterval(60)
    DispatchQueue.main.asyncAfter(deadline: .now() + max(1, nextMinute.timeIntervalSinceNow)) { scheduleClock() }
}
scheduleClock()

Timer.scheduledTimer(withTimeInterval: WEATHER_POLL, repeats: true) { _ in locationGate.refresh() }
// ponytail: 15 s poll; `tailscale debug watch-ipn` streams changes if this lags
Timer.scheduledTimer(withTimeInterval: TAILSCALE_POLL, repeats: true) { _ in updateTailscale() }
Timer.scheduledTimer(withTimeInterval: CLAUDE_POLL, repeats: true) { _ in updateClaude() }

// --- go -------------------------------------------------------------------

model.frontApp = NSWorkspace.shared.frontmostApplication?.localizedName ?? ""
// startup only: from here the OmniWM watch stream keeps it
model.focused = omniwmActive() ? managerFocused() : ""
rebuildSurfaces(monitorIDs())
guard !surfaces.isEmpty else {
    FileHandle.standardError.write("statusbar: no display\n".data(using: .utf8)!)
    exit(1)
}
apply(fetchSnapshot()) // blocking is fine here: the run loop has not started
rightItems["activity"] = BarItem(icon: "sf:cpu", iconColor: \.accent)
applyShade() // restore the level this machine was left at
updateBattery()
updateBrightness()
updateWifi()
updateWeather()
updateTailscale()
updateLayout()
updateClaude()
DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
    object: nil, queue: .main) { _ in updateLayout() }
repaint()
primeMedia()
reconcile("startup") // the OmniWM watch, and retries for a manager not up yet
tlog("statusbar up on " + surfaces.map { "\($0.screen.localizedName)=m\($0.monitorID)\($0.notched ? " (notched)" : "")" }.joined(separator: ", "))
app.run()
