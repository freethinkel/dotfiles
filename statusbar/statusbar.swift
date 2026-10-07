// statusbar — a native menu bar replacement for OmniWM, in ONE process.
//
// Left: workspace chips with one icon per window, fed by OmniWM's
// workspace-bar stream (fast path, no subprocess) and SkyLight window
// events (slow path, a snapshot off the main queue). Right: pills whose
// sources are read in process and publish — IOPS, CoreAudio,
// DisplayServices, EventKit, TIS — so only the clock and the network
// services (weather, tailscale, claude, home assistant) are polled.
//
// Timings land in /tmp/statusbar.log as `switch <ws> <ms>`.
import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
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
let DEFAULT_ORDER = ["claude", "weather", "home", "tailscale", "caffeinate", "theme", "more", "agents", "layout", "brightness", "volume", "battery", "clock", "activity"]

// Dragged order, kept in UserDefaults. Items added to DEFAULT_ORDER later
// slot in at their default index; ones removed from it drop out.
var rightOrder: [String] = {
    var order = (UserDefaults.standard.stringArray(forKey: "rightOrder") ?? [])
        .filter(DEFAULT_ORDER.contains)
    for (i, name) in DEFAULT_ORDER.enumerated() where !order.contains(name) {
        order.insert(name, at: min(i, order.count))
    }
    return order
}()
// whatever sits left of the "more" chevron hides behind it until clicked
var collapsed = true
var dragName: String? // the pill being dragged, if any
var collapsible: ArraySlice<String> { rightOrder.prefix { $0 != "more" } }

// above app windows, one below the native menu bar: with the menu bar on
// auto-hide it slides in OVER the bar when the pointer hits the top edge
let BAR_LEVEL = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue - 1)

// polling (s) — only for sources with no publisher
let WEATHER_POLL: TimeInterval = 1800
let TAILSCALE_POLL: TimeInterval = 15
let TAILSCALE_CLI = "/usr/local/bin/tailscale"
let CLAUDE_POLL: TimeInterval = 300
let HOME_POLL: TimeInterval = 15
let AGENTS_POLL: TimeInterval = 5
let ACTIVITY_POLL: TimeInterval = 60 // also the cpu averaging window
let ACTIVITY_CPU_HOT = 0.8
let HOME_DOMAINS: Set<String> = ["climate", "light", "switch", "fan"]

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
    var orange = NSColor.systemOrange // not themed: bar.sh has no orange
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
// Cached: draw() asks for the same few faces every frame, and a descriptor
// match per call was a good part of a 25-40 ms repaint.
var fontCache: [String: NSFont] = [:]
func nerdFont(_ face: String, _ size: CGFloat) -> NSFont {
    let key = "\(face)|\(size)"
    if let f = fontCache[key] { return f }
    let f = loadNerdFont(face, size)
    fontCache[key] = f
    return f
}

func loadNerdFont(_ face: String, _ size: CGFloat) -> NSFont {
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
    // floating windows stay off the chips. Only the windows QUERY says
    // which are floating; the workspace-bar stream does not, so the
    // snapshot keeps the set and the stream filters by it.
    var floating: Set<String> = []
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
    var floating: Set<String> = []
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
            guard (w["mode"] as? String) != "floating" else { s.floating.insert(id); continue }
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
    model.floating = s.floating
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

// --- media (Spotifast, polled) ----------------------------------------------
// Spotifast posts no distributed notification and MediaRemote is closed
// to third parties, so the pill asks its CLI. One call is ~10 ms and
// runs only while Spotifast does.
// ponytail: 2 s poll, a track change shows up to 2 s late; switch to a
// push source if Spotifast ever grows one

let spotifastBundleID = "rocks.spotifast.Spotifast"
let SPOTIFAST_CLI = "/Applications/Spotifast.app/Contents/MacOS/Spotifast"
let MEDIA_POLL: TimeInterval = 2

func spotifastRunning() -> Bool {
    !NSRunningApplication.runningApplications(withBundleIdentifier: spotifastBundleID).isEmpty
}

func setMedia(_ next: Media) {
    guard next != model.media else { return }
    model.media = next
    repaint()
    tlog("media \(next.playing ? "play" : "pause") \(next.title)")
}

func updateMedia() {
    guard spotifastRunning() else { return setMedia(Media()) }
    DispatchQueue.global(qos: .utility).async {
        // state, title, artists, album, … tab-separated
        let f = shell(SPOTIFAST_CLI, ["now-playing", "--raw"])
            .trimmingCharacters(in: .newlines)
            .split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        let next = f.count < 3 ? Media(running: true)
            : Media(running: true, playing: f[0] == "playing",
                    title: f[2].isEmpty ? f[1] : "\(f[2]) — \(f[1])")
        DispatchQueue.main.async { setMedia(next) }
    }
}

func spotifast(_ command: String) {
    DispatchQueue.global(qos: .userInitiated).async {
        _ = shell(SPOTIFAST_CLI, [command])
        DispatchQueue.main.async { updateMedia() }
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
    var badge = false // dot on the icon's top-right corner
    var badgeColor: KeyPath<Palette, NSColor> = \.red
    var stale = false // last good fetch is 2+ polls old: drawn muted
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

// A failed fetch keeps the last value on the pill, dimmed once the last
// good one is two polls old: a stale number should not pass for a live one.
var lastFetch: [String: Date] = [:]
func fetchFailed(_ name: String, poll: TimeInterval) {
    let age = Date().timeIntervalSince(lastFetch[name] ?? .distantPast)
    tlog("\(name): fetch failed, last good \(Int(min(age, 1e9)))s ago")
    set(name) { $0.stale = age > 2 * poll }
}

func shell(_ launch: String, _ args: [String], stdin input: String? = nil) -> String {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: launch)
    p.arguments = args
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = FileHandle.nullDevice
    let inPipe = Pipe()
    if input != nil { p.standardInput = inPipe }
    guard (try? p.run()) != nil else { return "" }
    if let input { // ponytail: small inputs only — written whole before reading
        inPipe.fileHandleForWriting.write(input.data(using: .utf8)!)
        try? inPipe.fileHandleForWriting.close()
    }
    let out = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return String(data: out, encoding: .utf8) ?? ""
}

// --- clock (no publisher: the one honest timer, aligned to the minute)
func updateClock() {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "dd MMM HH:mm"
    set("clock") { $0.icon = "sf:calendar"; $0.label = f.string(from: Date()) }
}

// --- calendar events (EventKit publishes EKEventStoreChanged; "now"
// moving past an event is the clock's minute tick)
let eventStore = EKEventStore()
var todayEvents: [EKEvent] = []

func updateEvents() {
    guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { return }
    let now = Date()
    let cal = Calendar.current
    let end = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) ?? now
    // all-day ones (birthdays, holidays) would keep the dot lit all day
    todayEvents = eventStore.events(matching: eventStore.predicateForEvents(withStart: now, end: end, calendars: nil))
        .filter { e in
            !e.isAllDay && e.status != .canceled && e.endDate > now
                && e.attendees?.first(where: \.isCurrentUser)?.participantStatus != .declined
        }
        .sorted { $0.startDate < $1.startDate }
    set("clock") { $0.badge = !todayEvents.isEmpty }
    if openPopup == "clock" { refreshPopup() }
}

// ponytail: a host list, add one when a call link opens Calendar instead
let MEETING_HOSTS = ["zoom.us", "meet.google.com", "teams.microsoft.com", "teams.live.com",
                     "telemost", "webex.com", "whereby.com", "meet.jit.si", "facetime.apple.com"]

func meetingLink(_ e: EKEvent) -> URL? {
    let text = [e.url?.absoluteString, e.location, e.notes].compactMap { $0 }.joined(separator: "\n")
    let links = (try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue))?
        .matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap(\.url) ?? []
    return links.first { u in MEETING_HOSTS.contains { u.host?.contains($0) == true } }
}

// --- caffeinate: the CLI as a child, `-w` tied to our pid so a crashed
// bar never leaves the Mac awake; `-t` ends it on its own.
// A closed lid sleeps through any assertion (unless clamshell with an
// external display), so "lid" also flips pmset's disablesleep, which
// needs root, and flips it back only if it was off before.
let CAFF_MODES: [(flags: String, text: String)] = [
    ("-di", "stay awake"),
    ("-i", "screen off, ssh up"),
    ("lid", "lid closed"),
]
var caffProc: Process?
var caffFlags = "-di"
var caffUntil: Date?
// on disk, so a crash in lid mode is undone at the next start
let lidFile = "\(NSHomeDirectory())/.local/state/statusbar/lid"
var lidSetByUs = FileManager.default.fileExists(atPath: lidFile) {
    didSet {
        guard lidSetByUs != oldValue else { return }
        if lidSetByUs {
            try? FileManager.default.createDirectory(atPath: (lidFile as NSString).deletingLastPathComponent,
                                                     withIntermediateDirectories: true)
            FileManager.default.createFile(atPath: lidFile, contents: nil)
        } else {
            try? FileManager.default.removeItem(atPath: lidFile)
        }
    }
}

func sleepDisabled() -> Bool {
    shell("/usr/bin/pmset", ["-g"]).split(separator: "\n")
        .contains { $0.contains("SleepDisabled") && $0.hasSuffix("1") }
}

let pmsetQueue = DispatchQueue(label: "com.freethinkel.statusbar.pmset") // serial: on/off land in order

// Flips only when the setting is not there already, so a disablesleep the
// user set themselves is never undone — and `lidSetByUs` records exactly
// the flips that were ours. The pmset read and write both run off main.
func setDisableSleep(_ on: Bool) {
    let cmd = "/usr/bin/pmset -a disablesleep \(on ? 1 : 0)"
    pmsetQueue.async {
        guard sleepDisabled() != on else { return }
        DispatchQueue.main.async { lidSetByUs = on }
        // a NOPASSWD sudoers line for pmset skips the prompt; without one, the admin dialog
        let sudo = Process()
        sudo.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        sudo.arguments = ["-n"] + cmd.split(separator: " ").map(String.init)
        sudo.standardError = FileHandle.nullDevice
        var ok = false
        if (try? sudo.run()) != nil { sudo.waitUntilExit(); ok = sudo.terminationStatus == 0 }
        if !ok {
            _ = shell("/usr/bin/osascript", ["-e", "do shell script \"\(cmd)\" with administrator privileges"])
        }
    }
}

func startCaffeinate(_ flags: String, until: Date? = nil) {
    // lid -> lid (a new deadline) keeps disablesleep as is, no off/on round trip
    let keepLid = flags == "lid" && lidSetByUs
    lidSetByUs = lidSetByUs && !keepLid
    stopCaffeinate()
    if keepLid {
        lidSetByUs = true
    } else if flags == "lid" {
        setDisableSleep(true)
    }
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
    p.arguments = [flags == "lid" ? "-i" : flags, "-w", "\(getpid())"]
        + (until.map { ["-t", "\(max(1, Int($0.timeIntervalSinceNow)))"] } ?? [])
    p.terminationHandler = { done in
        DispatchQueue.main.async {
            guard caffProc === done else { return } // a restart already replaced it
            stopCaffeinate()
        }
    }
    guard (try? p.run()) != nil else { return }
    caffProc = p
    caffFlags = flags
    caffUntil = until
    updateCaffeinate()
}

func stopCaffeinate() {
    caffProc?.terminate()
    caffProc = nil
    caffUntil = nil
    if lidSetByUs { lidSetByUs = false; setDisableSleep(false) }
    updateCaffeinate()
}

func updateCaffeinate() {
    var left = ""
    if let until = caffUntil {
        let m = Int((until.timeIntervalSinceNow / 60).rounded(.up))
        left = m >= 60 ? "\(m / 60)h\(m % 60 > 0 ? "\(m % 60)m" : "")" : "\(m)m"
    }
    set("caffeinate") {
        $0.icon = caffProc == nil ? "sf:cup.and.saucer" : "sf:cup.and.saucer.fill"
        $0.iconColor = caffProc == nil ? nil : \.yellow
        $0.label = left
        // night shift has no pill of its own: an orange dot here says it is on
        $0.badge = blueLightStatus()?.enabled.boolValue == true
        $0.badgeColor = \.orange
    }
}

func caffeinateRows() -> [PopupRow] {
    var rows = [PopupRow(text: caffProc == nil ? "awake: off" : "awake: on", hero: true)]
    for m in CAFF_MODES {
        rows.append(PopupRow(text: m.text, detail: m.flags == "lid" ? "-i + pmset" : m.flags,
                             highlight: m.flags == caffFlags, action: {
            // a running one switches mode and keeps its deadline
            if caffProc != nil { startCaffeinate(m.flags, until: caffUntil) } else { caffFlags = m.flags }
            refreshPopup()
        }))
    }
    rows.append(PopupRow(separator: true))
    let spans: [(String, TimeInterval?)] = [("30 min", 1800), ("1 hour", 3600), ("2 hours", 7200),
                                            ("4 hours", 14400), ("until stopped", nil)]
    for (text, span) in spans {
        rows.append(PopupRow(text: text, action: {
            startCaffeinate(caffFlags, until: span.map { Date().addingTimeInterval($0) })
            closePopup()
        }))
    }
    if caffProc != nil {
        rows.append(PopupRow(text: "stop", dim: true, action: { stopCaffeinate(); closePopup() }))
    }
    // night shift lives here rather than in a pill of its own
    if blueLightStatus()?.available.boolValue == true { rows.append(PopupRow(separator: true)) }
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
    return rows
}

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

// --- battery (IOPS publishes, capacity ticks included)
var battery = (pct: 0, charging: false, minutes: -1)

func batteryRows() -> [PopupRow] {
    let b = battery
    let time = b.minutes > 0 ? "\(b.minutes / 60):\(String(format: "%02d", b.minutes % 60))" : "—"
    return [
        PopupRow(text: "battery", hero: true),
        PopupRow(text: "\(b.pct)%", detail: b.charging ? (b.pct >= 100 ? "charged" : "charging") : "on battery", dim: true),
        PopupRow(text: b.charging ? "until full" : "time left", detail: b.pct >= 100 && b.charging ? "—" : time, dim: true),
        PopupRow(separator: true),
        PopupRow(text: "battery settings…", dim: true, action: {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Battery-Settings.extension")!)
            closePopup()
        }),
    ]
}

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
        // minutes; IOPS reports -1 while it is still estimating
        let toEmpty = d[kIOPSTimeToEmptyKey] as? Int ?? -1, toFull = d[kIOPSTimeToFullChargeKey] as? Int ?? -1
        battery = (pct, charging, charging ? toFull : toEmpty)
        if openPopup == "battery" { refreshPopup() }
        set("battery") { $0.icon = icon; $0.iconColor = color; $0.label = charging && pct >= 100 ? "" : "\(pct)%" }
        return
    }
}

// --- activity: the cpu pill stays a quiet glyph and only speaks up when
// the machine is struggling — cpu busy over the last poll, memory
// pressure (critical only, red without a word), thermal throttling. Click still opens btop for the culprit.
let hostPort = mach_host_self()
var lastTicks: host_cpu_load_info?

func cpuBusy() -> Double? { // share of ticks since the previous call, nil on the first
    var info = host_cpu_load_info()
    var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
    let kr = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { host_statistics(hostPort, HOST_CPU_LOAD_INFO, $0, &count) }
    }
    guard kr == KERN_SUCCESS else { return nil }
    defer { lastTicks = info }
    guard let prev = lastTicks else { return nil }
    let t = info.cpu_ticks, p = prev.cpu_ticks // user, system, idle, nice
    let busy = Double(t.0 &- p.0) + Double(t.1 &- p.1) + Double(t.3 &- p.3)
    let total = busy + Double(t.2 &- p.2)
    return total > 0 ? busy / total : nil
}

func updateActivity() {
    var level: Int32 = 1, size = MemoryLayout<Int32>.size // 1 normal, 2 warn, 4 critical
    sysctlbyname("kern.memorystatus_vm_pressure_level", &level, &size, nil, 0)
    let thermal = ProcessInfo.processInfo.thermalState
    var flags: [String] = [], color: KeyPath<Palette, NSColor> = \.accent
    if let cpu = cpuBusy(), cpu >= ACTIVITY_CPU_HOT { flags.append("\(Int(cpu * 100))%"); color = \.yellow }
    if thermal.rawValue >= ProcessInfo.ThermalState.serious.rawValue { flags.append("hot"); color = \.yellow }
    if level >= 4 || thermal == .critical { color = \.red }
    set("activity") { $0.icon = "sf:cpu"; $0.iconColor = color; $0.label = flags.joined(separator: " ") }
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

        guard let name = audioDeviceName(id) else { continue }
        result.append((id, name))
    }
    return result
}

func audioDeviceName(_ id: AudioDeviceID) -> String? {
    var nameAddr = AudioObjectPropertyAddress(mSelector: kAudioObjectPropertyName,
                                              mScope: kAudioObjectPropertyScopeGlobal,
                                              mElement: kAudioObjectPropertyElementMain)
    var name: CFString = "" as CFString
    var nameSize = UInt32(MemoryLayout<CFString>.size)
    var ok = false
    withUnsafeMutablePointer(to: &name) { ptr in
        ok = AudioObjectGetPropertyData(id, &nameAddr, 0, nil, &nameSize, ptr) == noErr
    }
    return ok ? name as String : nil
}

// What the output IS, when it is worn: AirPods by their model's symbol,
// any other Bluetooth device or the headphone jack as headphones, nil for
// speakers. Only the name tells AirPods models apart — gen 3/4 have no
// distinct name, so they share the plain glyph.
func headphonesIcon(_ dev: AudioDeviceID) -> String? {
    let name = audioDeviceName(dev) ?? ""
    if name.contains("AirPods Max") { return "sf:airpods.max" }
    if name.contains("AirPods Pro") { return "sf:airpods.pro" }
    if name.contains("AirPods") { return "sf:airpods" }
    func u32(_ selector: AudioObjectPropertySelector, _ scope: AudioObjectPropertyScope) -> UInt32 {
        var addr = AudioObjectPropertyAddress(mSelector: selector, mScope: scope,
                                              mElement: kAudioObjectPropertyElementMain)
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        AudioObjectGetPropertyData(dev, &addr, 0, nil, &size, &value)
        return value
    }
    let transport = u32(kAudioDevicePropertyTransportType, kAudioObjectPropertyScopeGlobal)
    if transport == kAudioDeviceTransportTypeBluetooth || transport == kAudioDeviceTransportTypeBluetoothLE
        || u32(kAudioDevicePropertyDataSource, kAudioDevicePropertyScopeOutput) == 0x6864_706e // 'hdpn'
        || name.localizedCaseInsensitiveContains("headphone") {
        return "sf:headphones"
    }
    return nil
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
    if let worn = headphonesIcon(defaultOutputDevice()) {
        icon = worn // no level variants; the label carries the level and "mute"
    } else if v.muted || v.percent == 0 {
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

// --- location (one coordinate, for the weather) ---------------------------
// wttr.in's IP geolocation lands wherever the VPN exit node is, so the
// weather asks CoreLocation where the machine really is.
//
// TCC judges the RESPONSIBLE process, so only the launchd-started bar may
// prompt and running it by hand stays quiet.
final class LocationGate: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var managed: Bool { ProcessInfo.processInfo.environment["STATUSBAR_MANAGED"] != nil }

    func start() {
        manager.delegate = self
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorized:
            manager.requestLocation()
        case .denied, .restricted:
            tlog("location: denied — weather falls back to the timezone city")
        default:
            guard managed else {
                tlog("location: not launchd-managed, so not prompting")
                return
            }
            manager.requestWhenInUseAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        tlog("location: authorization now \(m.authorizationStatus.rawValue)")
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
            updateCaffeinate()
            guard let s = blueLightStatus() else { return }
            // which field a schedule boundary actually moves is worth
            // having in the log the morning after
            tlog("night shift changed: enabled=\(s.enabled.boolValue) "
                + "active=\(s.active.boolValue) mode=\(s.mode)")
            if openPopup == "caffeinate" { refreshPopup() }
        }
    }
    nightShiftBlock = block
    typealias SetFn = @convention(c) (AnyObject, Selector, Any) -> Void
    unsafeBitCast(method_getImplementation(m), to: SetFn.self)(bl.client, sel, block)
}

// --- weather (no publisher; wttr.in, refreshed on a long timer)
// One j1 fetch feeds both the pill and its popup — weather.sh does the
// same, via a cache file it writes atomically because a click can read it
// mid-write. In one process the struct IS the cache and that race cannot
// be expressed.

struct Weather {
    var symbol = "", temp = "", desc = "", feels = ""
    var wind = "", humidity = "", pressure = "", visibility = "", uv = "", rain = ""
    var sunrise = "", sunset = "", moon = "", location = ""
    var fetched = Date()
    var hours: [(time: String, symbol: String, temp: String, rain: Int)] = []
    var days: [(name: String, symbol: String, low: String, high: String, rain: Int, wind: String, uv: String)] = []
}

func uvLevel(_ uv: String) -> String {
    guard let n = Int(uv) else { return uv }
    let level = n <= 2 ? "low" : n <= 5 ? "moderate" : n <= 7 ? "high" : n <= 10 ? "very high" : "extreme"
    return "\(n) \(level)"
}

var weather: Weather?

// WWO condition code -> SF Symbol, night-aware for the clear/partly pair
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

// wttr's "06:45 AM" -> minutes since midnight
func clockMinutes(_ s: String) -> Int? {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "hh:mm a"
    guard let d = f.date(from: s) else { return nil }
    let c = Calendar.current.dateComponents([.hour, .minute], from: d)
    return (c.hour ?? 0) * 60 + (c.minute ?? 0)
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
              let days = root["weather"] as? [[String: Any]],
              let today = days.first
        else { return DispatchQueue.main.async { fetchFailed("weather", poll: WEATHER_POLL) } }

        func text(_ d: [String: Any], _ key: String) -> String { d[key] as? String ?? "" }
        func int(_ d: [String: Any], _ key: String) -> Int { Int(text(d, key)) ?? 0 }
        func nested(_ d: [String: Any], _ key: String) -> String {
            ((d[key] as? [[String: Any]])?.first?["value"] as? String) ?? ""
        }

        var w = Weather()
        // night by the real sun, not a fixed 7-20: a winter 17:00 is dark
        let astro = (today["astronomy"] as? [[String: Any]])?.first ?? [:]
        let sunrise = clockMinutes(text(astro, "sunrise")), sunset = clockMinutes(text(astro, "sunset"))
        func night(_ minute: Int) -> Bool {
            guard let sunrise, let sunset else { return minute < 7 * 60 || minute >= 20 * 60 }
            return minute < sunrise || minute >= sunset
        }
        func hhmm(_ minute: Int) -> String { String(format: "%02d:%02d", minute / 60, minute % 60) }
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let nowMin = (now.hour ?? 0) * 60 + (now.minute ?? 0)

        w.symbol = weatherSymbol(int(current, "weatherCode"), night: night(nowMin))
        w.temp = text(current, "temp_C")
        w.desc = nested(current, "weatherDesc").lowercased()
        w.feels = text(current, "FeelsLikeC")
        w.humidity = text(current, "humidity")
        w.pressure = text(current, "pressure")
        w.visibility = text(current, "visibility")
        w.uv = text(current, "uvIndex")
        if let sunrise, let sunset { w.sunrise = hhmm(sunrise); w.sunset = hhmm(sunset) }
        let phase = text(astro, "moon_phase")
        if !phase.isEmpty { w.moon = "\(moonEmoji(phase)) \(phase.lowercased())" }

        let arrows = ["↓", "↙", "←", "↖", "↑", "↗", "→", "↘"]
        func arrow(_ degrees: Int) -> String { arrows[((degrees + 180) / 45) % 8] }
        let speed = int(current, "windspeedKmph"), gust = int(current, "WindGustKmph")
        w.wind = "\(arrow(int(current, "winddirDegree"))) \(speed) km/h"
        if gust >= speed * 3 / 2, gust > speed + 10 { w.wind += " · gusts \(gust)" }

        // rain earns a row only with real signal: falling now, or likely today
        let precip = Double(text(current, "precipMM")) ?? 0
        let todayHours = (today["hourly"] as? [[String: Any]]) ?? []
        let chance = todayHours.map { int($0, "chanceofrain") }.max() ?? 0
        var rain: [String] = []
        if precip > 0 { rain.append("\(text(current, "precipMM")) mm now") }
        if chance >= 30 { rain.append("\(chance)% today") }
        w.rain = rain.joined(separator: " · ")

        // the next six 3-hour slots, today's remainder then tomorrow's start
        for (i, day) in days.prefix(2).enumerated() {
            for h in (day["hourly"] as? [[String: Any]]) ?? [] where w.hours.count < 6 {
                let minute = int(h, "time") / 100 * 60
                // today: the slot that holds now, and later ones
                guard i > 0 || minute + 180 > nowMin else { continue }
                w.hours.append((hhmm(minute), weatherSymbol(int(h, "weatherCode"), night: night(minute)),
                                text(h, "tempC"), int(h, "chanceofrain")))
            }
        }

        let iso = DateFormatter()
        iso.dateFormat = "yyyy-MM-dd"
        let short = DateFormatter()
        short.dateFormat = "EEE"
        for (i, day) in days.enumerated() {
            let hourly = (day["hourly"] as? [[String: Any]]) ?? []
            let noon = hourly.count > 4 ? hourly[4] : hourly.first ?? [:]
            let name = i == 0 ? "today"
                : iso.date(from: text(day, "date")).map { short.string(from: $0).lowercased() } ?? text(day, "date")
            w.days.append((name, weatherSymbol(int(noon, "weatherCode"), night: false),
                           text(day, "mintempC"), text(day, "maxtempC"),
                           hourly.map { int($0, "chanceofrain") }.max() ?? 0,
                           "\(hourly.map { int($0, "windspeedKmph") }.max() ?? 0) km/h",
                           text(day, "uvIndex")))
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
            lastFetch["weather"] = Date()
            set("weather") { $0.icon = w.symbol; $0.label = "\(w.temp)°"; $0.stale = false }
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
    var swatches: [NSColor] = [] // right-aligned colour chips — theme previews
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
    var cellRing: Int? // accent outline — the picked day
    var cellDots: [[NSColor]] = [] // per cell, up to 3 dots under the text
    var onCell: ((Int) -> Void)?
    var labelCol = false // first cell is a left-aligned label, the rest centred
    var bar: NSColor? // leading colour stripe — an event's calendar
    var strike = false // declined / cancelled
    var pager: ((Int) -> Void)? // ‹ title ›, a click on either half pages by ∓1
    var minWidth: CGFloat = 0 // content width floor, so the popup keeps its size between pages
}


final class PopupView: NSView {
    var rows: [PopupRow] = []
    private var rowRects: [(Int, NSRect)] = []
    private var cellRects: [(Int, Int, NSRect)] = [] // row, cell, box
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

    // a cell is text, or an "sf:" symbol drawn at the row's point size
    func cellWidth(_ c: String, _ f: NSFont) -> CGFloat { c.hasPrefix("sf:") ? inkBox(c, f).width : advance(c, f) }

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
                for (k, c) in r.cells.enumerated() { w[k] = max(w[k], cellWidth(c, font(r))) }
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
            if row.bar != nil { w += 10 }
            if row.pager != nil { w += 40 }
            w = max(w, row.minWidth)
            if !row.swatches.isEmpty { w += CGFloat(row.swatches.count) * 14 + 16 }
            if row.slider != nil { w = max(w, 150) }
            width = max(width, w)
            height += rowH(row)
        }
        return NSSize(width: width + POPUP_PAD * 2 + 20, height: height)
    }

    override func draw(_ dirtyRect: NSRect) {
        rowRects.removeAll()
        cellRects.removeAll()
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
                // label tables hug the left edge; a bare grid (the calendar) centres
                var cx = row.labelCol ? rect.minX : rect.midX - tables[index].reduce(0, +) / 2
                // dotted rows lift the text to make room underneath
                let textY = row.cellDots.isEmpty ? rect.midY : rect.midY + 3
                for (k, cell) in row.cells.enumerated() {
                    let cw = tables[index][k]
                    let box = NSRect(x: cx, y: rect.minY, width: cw, height: rect.height)
                    let marked = k == row.cellMark
                    if marked {
                        palette.accent.setFill()
                        NSBezierPath(roundedRect: box.insetBy(dx: 1, dy: 2), xRadius: RADIUS, yRadius: RADIUS).fill()
                    } else if k == row.cellRing {
                        palette.accent.setStroke()
                        let ring = NSBezierPath(roundedRect: box.insetBy(dx: 1.5, dy: 2.5), xRadius: RADIUS, yRadius: RADIUS)
                        ring.lineWidth = 1
                        ring.stroke()
                    }
                    let tint = marked ? palette.barBG
                        : row.cellDim.contains(k) ? palette.label.withAlphaComponent(0.4) : color(row)
                    // a 2-cell label row is key/value: the value reads left-aligned
                    let left = row.labelCol && (k == 0 || row.cells.count == 2)
                    if cell.hasPrefix("sf:") {
                        drawIcon(cell, f, tint, centeredIn: box)
                    } else {
                        let tx = left ? cx + 4 : cx + (cw - advance(cell, f)) / 2
                        drawText(cell, f, tint, leftAt: tx, midY: textY)
                    }
                    if k < row.cellDots.count {
                        let dots = row.cellDots[k].prefix(3)
                        var dx = box.midX - CGFloat(dots.count) * 5 / 2
                        for dot in dots {
                            (marked ? palette.barBG : dot).setFill()
                            NSBezierPath(ovalIn: NSRect(x: dx + 1, y: rect.minY + 5, width: 3, height: 3)).fill()
                            dx += 5
                        }
                    }
                    cellRects.append((index, k, box))
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
            if row.pager != nil {
                let f = font(row)
                drawText(row.text, f, color(row), leftAt: rect.midX - advance(row.text, f) / 2, midY: rect.midY)
                drawText("‹", f, color(row), leftAt: x, midY: rect.midY)
                drawText("›", f, color(row), leftAt: rect.maxX - advance("›", f) - 4, midY: rect.midY)
                rowRects.append((index, rect))
                continue
            }
            if let bar = row.bar {
                bar.withAlphaComponent(row.strike || row.dim ? 0.4 : 1).setFill()
                NSBezierPath(roundedRect: NSRect(x: x, y: rect.minY + 5, width: 3, height: rect.height - 10),
                             xRadius: 1.5, yRadius: 1.5).fill()
                x += 10
            }
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
                if row.strike {
                    tint.setFill()
                    NSRect(x: x, y: rect.midY - 0.5, width: advance(row.text, font(row)), height: 1).fill()
                }
                var sx = rect.maxX - 4
                for chip in row.swatches.reversed() {
                    sx -= 10
                    let box = NSRect(x: sx, y: rect.midY - 5, width: 10, height: 10)
                    chip.setFill()
                    let path = NSBezierPath(roundedRect: box, xRadius: 3, yRadius: 3)
                    path.fill()
                    // a bg-coloured chip vanishes against a similar popup: outline it
                    palette.label.withAlphaComponent(0.2).setStroke()
                    path.lineWidth = 0.5
                    path.stroke()
                    sx -= 4
                }
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

    override func mouseDragged(with event: NSEvent) { slide(event) }
    override func mouseDown(with event: NSEvent) { slide(event) }
    override func mouseUp(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        if let (index, k, _) = cellRects.first(where: { $0.2.contains(p) }), let onCell = rows[index].onCell {
            onCell(k)
            return
        }
        guard let (index, rect) = rowRects.first(where: { $0.1.contains(p) }) else { return }
        if let pager = rows[index].pager { pager(p.x < rect.midX ? -1 : 1); return }
        guard rows[index].slider == nil, let action = rows[index].action else { return }
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
    calDay = nil // the calendar reopens on today
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

// false when the item has no popup to show (rows are built once, here)
@discardableResult
func showPopup(_ name: String, under anchor: NSRect, on surface: BarSurface, alignLeft: Bool = false) -> Bool {
    if openPopup == name { closePopup(); return true }
    closePopup()
    let rows = popupRows(for: name)
    guard !rows.isEmpty else { return false }

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
    return true
}

// --- popup content ---------------------------------------------------------

var calDay: Date? // the picked day, nil = today

func calendarRows() -> [PopupRow] {
    var rows: [PopupRow] = []
    let now = Date()
    var cal = Calendar(identifier: .gregorian)
    cal.firstWeekday = 2 // Monday, like the shell version
    cal.minimumDaysInFirstWeek = 4 // ISO week numbers
    let picked = cal.startOfDay(for: calDay ?? now)
    // the grid's own width: 8 columns, the font is mono and every cell is two glyphs.
    // Fixed so a long title or agenda never resizes the popup on a pick
    let width = 8 * (advance("00", nerdFont("Regular", 13)) + CELL_PAD)
    let title = DateFormatter()
    title.dateFormat = "MMMM yyyy"
    rows.append(PopupRow(text: title.string(from: picked).lowercased(), hero: true, pager: { step in
        calDay = cal.date(byAdding: .month, value: step, to: picked)
        refreshPopup()
    }, minWidth: width))
    rows.append(PopupRow(cells: ["w", "mo", "tu", "we", "th", "fr", "sa", "su"], cellDim: Set(0..<8)))

    guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: picked)) else { return rows }
    // weekday index with Monday = 0
    let leading = (cal.component(.weekday, from: monthStart) + 5) % 7
    let gridStart = cal.date(byAdding: .day, value: -leading, to: monthStart)!
    let weeks = Int(ceil(Double(leading + cal.range(of: .day, in: .month, for: picked)!.count) / 7))
    let days = (0..<weeks * 7).map { cal.date(byAdding: .day, value: $0, to: gridStart)! }
    let gridEnd = cal.date(byAdding: .day, value: 1, to: days.last!)!

    let access = EKEventStore.authorizationStatus(for: .event) == .fullAccess
    let events = access ? eventStore.events(matching: eventStore.predicateForEvents(
        withStart: gridStart, end: gridEnd, calendars: nil)) : []
    func declined(_ e: EKEvent) -> Bool {
        e.status == .canceled || e.attendees?.first(where: \.isCurrentUser)?.participantStatus == .declined
    }
    func on(_ day: Date) -> [EKEvent] {
        let end = cal.date(byAdding: .day, value: 1, to: day)!
        return events.filter { $0.startDate < end && $0.endDate > day }
    }

    for w in 0..<weeks {
        let week = Array(days[w * 7..<w * 7 + 7])
        var dots: [[NSColor]] = [[]]
        for day in week {
            var colors: [NSColor] = []
            for e in on(day) where !declined(e) && !colors.contains(e.calendar.color) { colors.append(e.calendar.color) }
            dots.append(colors)
        }
        let inMonth = { (d: Date) in cal.isDate(d, equalTo: monthStart, toGranularity: .month) }
        rows.append(PopupRow(cells: ["\(cal.component(.weekOfYear, from: week[0]))"] + week.map { "\(cal.component(.day, from: $0))" },
                             cellDim: Set([0] + week.indices.filter { !inMonth(week[$0]) }.map { $0 + 1 }),
                             cellMark: week.firstIndex { cal.isDateInToday($0) }.map { $0 + 1 },
                             cellRing: week.firstIndex { $0 == picked && !cal.isDateInToday($0) }.map { $0 + 1 },
                             cellDots: dots,
                             onCell: { k in
                                 guard k > 0 else { return }
                                 calDay = week[k - 1]
                                 refreshPopup()
                             }))
    }

    // the picked day's agenda: a call opens its link, anything else opens Calendar
    rows.append(PopupRow(separator: true))
    let head = DateFormatter()
    head.dateFormat = "EEEE d MMMM"
    rows.append(PopupRow(text: cal.isDateInToday(picked) ? "today" : head.string(from: picked).lowercased(), dim: true))
    let agenda = on(picked).sorted { ($0.isAllDay ? 0 : 1, $0.startDate) < ($1.isAllDay ? 0 : 1, $1.startDate) }
    if agenda.isEmpty { rows.append(PopupRow(text: access ? "no events" : "no calendar access", dim: true)) }
    let hm = DateFormatter()
    hm.dateFormat = "HH:mm"
    for e in agenda {
        let link = meetingLink(e)
        // ponytail: relative time only inside the hour, the clock covers the rest
        let mins = Int(ceil(e.startDate.timeIntervalSince(now) / 60))
        let when = e.isAllDay || e.endDate <= now ? nil
            : mins <= 0 ? "now" : mins <= 60 ? "in \(mins)m" : nil
        // "all day" is 7 wide; the font is mono, so padding lines the titles up
        let time = e.isAllDay ? "all day" : hm.string(from: e.startDate).padding(toLength: 7, withPad: " ", startingAt: 0)
        let detail = [when, link != nil && e.endDate > now ? "join" : nil].compactMap { $0 }.joined(separator: " · ")
        // the same sums PopupView.measure does: stripe + text + detail
        let room = width - 10 - (detail.isEmpty ? 0 : advance(detail, nerdFont("Regular", 11)) + 24)
        // only the title gives way: the time always stays
        let f = nerdFont("Regular", 13)
        var name = e.title ?? ""
        if advance("\(time) \(name)", f) > room {
            while !name.isEmpty && advance("\(time) \(name)…", f) > room { name.removeLast() }
            name += "…"
        }
        let text = "\(time) \(name)"
        rows.append(PopupRow(text: text,
                             detail: detail,
                             dim: !e.isAllDay && e.endDate <= now,
                             highlight: when == "now",
                             action: {
                                 closePopup()
                                 NSWorkspace.shared.open(link ?? URL(fileURLWithPath: "/System/Applications/Calendar.app"))
                             },
                             bar: e.calendar.color,
                             strike: declined(e)))
    }
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
        PopupRow(text: name, highlight: name == orchestrator, action: { orchestrator = name; closePopup() })
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
                    e.temp = a["current_temperature"] as? Double
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
                                     detail: temp + e.state, highlight: on,
                                     action: { haCall(e, on ? "turn_off" : "turn_on") }))
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
                rows.append(PopupRow(icon: icon, text: e.name, detail: e.state, highlight: on,
                                     action: { haCall(e, "toggle") }))
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

func weatherRows() -> [PopupRow] {
    guard let w = weather else { return [] }
    func kv(_ k: String, _ v: String) -> PopupRow { PopupRow(cells: [k, v], cellDim: [0], labelCol: true) }
    // a label column, then one column per slot; cells under 10% rain read dim
    func head(_ label: String, _ cols: [String]) -> PopupRow {
        PopupRow(cells: [label] + cols, cellDim: Set(0...cols.count), labelCol: true)
    }
    func line(_ label: String, _ cols: [String], dim: [Bool] = []) -> PopupRow {
        PopupRow(cells: [label] + cols, cellDim: Set([0] + dim.indices.filter { dim[$0] }.map { $0 + 1 }), labelCol: true)
    }
    var rows: [PopupRow] = [PopupRow(icon: w.symbol, text: "\(w.temp)°C \(w.desc)", hero: true)]
    if w.feels != w.temp { rows.append(kv("feels", "\(w.feels)°C")) }
    rows.append(kv("wind", w.wind))
    rows.append(kv("humidity", "\(w.humidity)%"))
    if !w.pressure.isEmpty { rows.append(kv("pressure", "\(w.pressure) hPa")) }
    if !w.visibility.isEmpty { rows.append(kv("visibility", "\(w.visibility) km")) }
    if !w.uv.isEmpty { rows.append(kv("uv", uvLevel(w.uv))) }
    if !w.rain.isEmpty { rows.append(kv("rain", w.rain)) }
    if !w.sunrise.isEmpty { rows.append(kv("sun", "\(w.sunrise) → \(w.sunset)")) }
    if !w.moon.isEmpty { rows.append(kv("moon", w.moon)) }
    if !w.hours.isEmpty {
        rows.append(PopupRow(separator: true))
        rows.append(head("", w.hours.map(\.time)))
        rows.append(line("", w.hours.map(\.symbol)))
        rows.append(line("temp", w.hours.map { "\($0.temp)°" }))
        rows.append(line("rain", w.hours.map { "\($0.rain)%" }, dim: w.hours.map { $0.rain < 10 }))
    }
    if !w.days.isEmpty {
        rows.append(PopupRow(separator: true))
        rows.append(head("", w.days.map(\.name)))
        rows.append(line("", w.days.map(\.symbol)))
        rows.append(line("temp", w.days.map { "\($0.low)–\($0.high)°" }))
        rows.append(line("rain", w.days.map { "\($0.rain)%" }, dim: w.days.map { $0.rain < 10 }))
        rows.append(line("wind", w.days.map(\.wind)))
        rows.append(line("uv", w.days.map(\.uv)))
    }
    rows.append(PopupRow(separator: true))
    let at = DateFormatter()
    at.dateFormat = "HH:mm"
    rows.append(PopupRow(text: w.location.isEmpty ? "wttr.in" : w.location,
                         detail: "updated \(at.string(from: w.fetched))", dim: true))
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
    case "battery": return batteryRows()
    case "tailscale": return tailscaleRows()
    case "home": return homeRows()
    case "layout": return layoutRows()
    case "claude": return claudeRows()
    case "agents": return agentRows()
    case "agents:pick": return orchestratorRows()
    case "caffeinate": return caffeinateRows()
    case "theme": return themeRows()
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

// The REAL Apple menu — child 0 of the front app's menu bar — with
// submenus drilled into behind a back row. Falls back to the hand-rolled
// rows when Accessibility is not granted or AX has nothing.
func appleMenuRows() -> [PopupRow] {
    guard AXIsProcessTrusted(),
          let menubar = frontAppAXMenuBar(),
          let apple = axChildren(menubar).first
    else { return appleRows() }
    if let top = appMenuStack.last {
        var rows = [PopupRow(icon: "‹", text: top.title, highlight: true, action: {
            appMenuStack.removeLast()
            refreshPopup()
        })]
        rows.append(contentsOf: rowsForMenu(top.element, context: top.title))
        return rows
    }
    let rows = rowsForMenu(apple, collapseAlternates: true)
    guard !rows.isEmpty else { return appleRows() }
    return rows
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
    if s.hasPrefix("ts") { return CGRect(x: 0, y: 0, width: font.pointSize, height: font.pointSize) }
    if s.hasPrefix("key:") { return CGRect(origin: .zero, size: keyBadge(s, font).size) }
    if s.hasPrefix("donut:") { return CGRect(x: 0, y: 0, width: font.pointSize, height: font.pointSize) }
    if s.hasPrefix("agents:") {
        let m = agentMark(font)
        return CGRect(x: 0, y: 0, width: CGFloat(s.count - 7) * m.step - m.gap, height: font.pointSize)
    }
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
    // cached by name, size and tint; a theme switch only adds keys
    let key = "\(s)|\(font.pointSize)|\(color?.description ?? "")"
    if let img = symbolCache[key] { return img }
    let img = loadSymbol(s, font, color)
    symbolCache[key] = img
    return img
}

var symbolCache: [String: NSImage?] = [:]
func loadSymbol(_ s: String, _ font: NSFont, _ color: NSColor?) -> NSImage? {
    var config = NSImage.SymbolConfiguration(pointSize: font.pointSize, weight: .medium)
    if let color { config = config.applying(.init(paletteColors: [color])) }
    return NSImage(systemSymbolName: String(s.dropFirst(3)), accessibilityDescription: nil)?
        .withSymbolConfiguration(config)
}

// "key:<text>" is a keycap: a filled rounded plate, the text in the bar's background colour
func keyBadge(_ s: String, _ font: NSFont) -> (text: String, font: NSFont, size: NSSize) {
    // Heavy: knocked-out text reads a weight lighter than the bar's Bold
    let text = String(s.dropFirst(4)), f = nerdFont("Heavy", (font.pointSize * 0.62).rounded())
    return (text, f, NSSize(width: (advance(text, f) + 8).rounded(), height: font.pointSize + 1))
}

// "agents:<states>" is a row of status marks, one digit (AgentState) each
func agentMark(_ font: NSFont) -> (d: CGFloat, gap: CGFloat, step: CGFloat) {
    let d = (font.pointSize * 0.55).rounded(), gap: CGFloat = 5
    return (d, gap, d + gap)
}

// "donut:<0...1>" is a progress ring the size of a glyph
func drawIcon(_ s: String, _ font: NSFont, _ color: NSColor, centeredIn box: CGRect) {
    if s.hasPrefix("agents:") {
        let m = agentMark(font), lw: CGFloat = 1.5, r = m.d / 2 - lw / 2
        let marks = s.dropFirst(7)
        var x = box.midX - CGFloat(marks.count - 1) * m.step / 2
        for ch in marks {
            guard let st = ch.wholeNumberValue.flatMap({ AgentState(rawValue: $0) }) else { continue }
            let c = NSPoint(x: x.rounded(), y: box.midY.rounded())
            func circle(_ radius: CGFloat) -> NSBezierPath {
                let p = NSBezierPath(ovalIn: NSRect(x: c.x - radius, y: c.y - radius, width: radius * 2, height: radius * 2))
                p.lineWidth = lw
                return p
            }
            st.color.setStroke()
            st.color.setFill()
            switch st {
            case .idle: circle(r).stroke()
            case .done: circle(r + lw / 2).fill()
            case .working: // the right half filled, like a moon
                circle(r).stroke()
                let half = NSBezierPath()
                half.move(to: c)
                half.appendArc(withCenter: c, radius: r, startAngle: 90, endAngle: -90, clockwise: true)
                half.close()
                half.fill()
            case .blocked: // a dot inside a ring: the one that wants you
                circle(r).stroke()
                circle(max(1, r - lw - 1)).fill()
            }
            x += m.step
        }
        return
    }
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

let terminalApp = "Ghostty" // the activity pill opens btop here

let barItemType = NSPasteboard.PasteboardType("dev.freethinkel.statusbar.item")

final class BarView: NSView, NSDraggingSource {
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
        [("prev", "sf:backward.end.fill"), ("play", model.media.playing ? "sf:pause.fill" : "sf:play.fill"),
         ("next", "sf:forward.end.fill")]
    }

    // Positions first, size second: the pill is as wide as what it holds
    // plus equal padding, so the two can never disagree. Both ends measure
    // INK, so the trailing edge is not padded by a character's unused
    // advance the way the leading edge is not.
    private func mediaLayout(_ titleFont: NSFont, _ iconFont: NSFont)
        -> (width: CGFloat, glyphs: [(String, String, CGFloat, CGFloat)], titleX: CGFloat) {
        // square PILL_HEIGHT buttons, like the apple one: hover fills a
        // square and the glyph sits in its centre
        var x: CGFloat = 0
        var placed: [(String, String, CGFloat, CGFloat)] = []
        for (name, glyph) in mediaGlyphs() {
            placed.append((name, glyph, x, PILL_HEIGHT))
            x += PILL_HEIGHT
        }
        x += 4 // transport-to-title gap
        let titleX = x
        return (titleX + titleWidth(titleFont) + 10, placed, titleX)
    }

    private func mediaSize(_ titleFont: NSFont, _ iconFont: NSFont) -> CGFloat {
        guard model.media.running, !model.media.title.isEmpty else { return 0 }
        return mediaLayout(titleFont, iconFont).width
    }

    private var titleLimit: Int { (surface?.notched ?? false) ? 20 : 28 }
    private var titleScrolls: Bool { model.media.title.count > titleLimit }

    // a long title keeps the width of `limit` characters and scrolls
    // through it instead of being cut with an ellipsis
    private func titleWidth(_ font: NSFont) -> CGFloat {
        let title = model.media.title
        return titleScrolls ? advance(String(title.prefix(titleLimit)), font) : inkBox(title, font).maxX
    }

    // ponytail: redraws the whole bar at 30 fps while a title scrolls;
    // cache the bar into a layer and move only the title if CPU shows up
    private var marqueeScheduled = false
    // right-click on the title: still, showing the start of the title
    var marqueeOn: Bool {
        get { !UserDefaults.standard.bool(forKey: "marqueeOff") }
        set { UserDefaults.standard.set(!newValue, forKey: "marqueeOff") }
    }
    private func drawMarquee(_ font: NSFont, in box: NSRect, midY: CGFloat) {
        let title = model.media.title
        let cycle = advance(title, font) + 40 // 40 px gap before the repeat
        // a paused track holds still: scrolling redraws the whole bar at 30 fps
        let scrolling = marqueeOn && model.media.playing
        let offset = scrolling ? CGFloat(CACurrentMediaTime() * 30).truncatingRemainder(dividingBy: cycle) : 0
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()
        ctx.clip(to: box)
        // text in its own layer, then the edges erased with a gradient:
        // a fade mask that works over any pill background
        ctx.beginTransparencyLayer(auxiliaryInfo: nil)
        drawText(title, font, palette.label, leftAt: box.minX - offset, midY: midY)
        drawText(title, font, palette.label, leftAt: box.minX - offset + cycle, midY: midY)
        ctx.setBlendMode(.destinationOut)
        let fade: CGFloat = 12
        let erase = CGGradient(colorsSpace: nil, colors: [NSColor.black.cgColor, NSColor.clear.cgColor] as CFArray,
                               locations: [0, 1])!
        if scrolling {
            ctx.drawLinearGradient(erase, start: CGPoint(x: box.minX, y: 0), end: CGPoint(x: box.minX + fade, y: 0), options: [])
        }
        ctx.drawLinearGradient(erase, start: CGPoint(x: box.maxX, y: 0), end: CGPoint(x: box.maxX - fade, y: 0), options: [])
        ctx.endTransparencyLayer()
        ctx.restoreGState()
        guard scrolling, !marqueeScheduled else { return }
        marqueeScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 / 30) { [weak self] in
            self?.marqueeScheduled = false
            self?.needsDisplay = true
        }
    }

    private func drawMedia(at origin: CGFloat, _ titleFont: NSFont, _ iconFont: NSFont) {
        guard model.media.running, !model.media.title.isEmpty else { return }
        let width = mediaSize(titleFont, iconFont)
        let pill = NSRect(x: origin, y: (bounds.height - PILL_HEIGHT) / 2, width: width, height: PILL_HEIGHT)

        let layout = mediaLayout(titleFont, iconFont)
        for (name, glyph, dx, w) in layout.glyphs {
            let hit = NSRect(x: pill.minX + dx, y: 0, width: w, height: bounds.height)
            pressing(hit) {
                drawIcon(glyph, iconFont, palette.label,
                         centeredIn: NSRect(x: pill.minX + dx, y: pill.minY, width: w, height: pill.height))
            }
            mediaRects.append((name, hit))
        }
        let titleHit = NSRect(x: pill.minX + layout.titleX, y: 0,
                              width: titleWidth(titleFont), height: bounds.height)
        pressing(titleHit) {
            if titleScrolls {
                drawMarquee(titleFont, in: titleHit, midY: pill.midY)
            } else {
                drawText(model.media.title, titleFont, palette.label,
                         leftAt: titleHit.minX, midY: pill.midY)
            }
        }
        mediaRects.append(("title", titleHit))
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
        // press eases in, release eases back out
        let pressTarget: CGFloat = pressedRect != nil ? 1 : 0
        pressAnim += (pressTarget - pressAnim) * 0.58 // 1 - 0.65², twice the old 0.35
        if abs(pressTarget - pressAnim) < 0.01 { pressAnim = pressTarget } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 / 60) { [weak self] in self?.needsDisplay = true }
        }
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
        let apple = NSRect(x: PAD_LEFT, y: (bounds.height - PILL_HEIGHT) / 2, width: appleW, height: PILL_HEIGHT)
        appleRect = NSRect(x: apple.minX, y: 0, width: appleW, height: bounds.height)
        pressing(appleRect) { drawIcon(appleGlyph, appleFont, palette.accent, centeredIn: apple) }

        // one pill per workspace, like OmniWM's own bar: label, then an
        // icon per window. Floating windows and OmniWM's excluded apps are
        // already dropped by the time names reach model.apps.
        var x = apple.maxX + 10
        for ws in shown {
            let apps = model.apps[ws] ?? []
            let iconsW = apps.isEmpty ? 0 : CGFloat(apps.count) * (APP_ICON_SIZE + APP_ICON_GAP) + 4
            let chip = NSRect(x: x, y: (bounds.height - PILL_HEIGHT) / 2,
                              width: CHIP_BOX + iconsW + CHIP_PAD * 2, height: PILL_HEIGHT)
            // each display marks the workspace IT is showing, not the
            // globally focused one
            let active = ws == surface.visible
            let chipHit = NSRect(x: chip.minX, y: 0, width: chip.width, height: bounds.height)
            pressing(chipHit) {
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
            let labelBox = NSRect(x: chip.minX + CHIP_PAD, y: 0, width: CHIP_BOX, height: bounds.height)
            switch workspaceIcon(ws) {
            case .glyph(let glyph)?:
                drawIcon(glyph, iconFont, tint, centeredIn: labelBox)
            case .image(let icon)?:
                icon.draw(in: NSRect(x: labelBox.midX - 9, y: bounds.height / 2 - 9, width: 18, height: 18),
                          from: .zero, operation: .sourceOver, fraction: fade)
            case nil:
                draw(String(ws.suffix(1)), chipFont, tint, centeredIn: labelBox)
            }
            var ix = labelBox.maxX + 2
            for win in apps {
                let r = NSRect(x: ix, y: (bounds.height - APP_ICON_SIZE) / 2, width: APP_ICON_SIZE, height: APP_ICON_SIZE)
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
                let winHit = NSRect(x: r.minX - APP_ICON_GAP / 2, y: 0,
                                    width: APP_ICON_SIZE + APP_ICON_GAP, height: bounds.height)
                pressing(winHit) {
                    appIcon(win.app)?.draw(in: r.insetBy(dx: -grow, dy: -grow), from: .zero,
                                           operation: .sourceOver, fraction: 0.5 + 0.5 * e)
                }
                winRects.append((win.id, winHit))
                ix += APP_ICON_SIZE + APP_ICON_GAP
            }
            }
            chipRects.append((ws, chipHit))
            x = chip.maxX + CHIP_GAP
        }
        winAnim = nextAnim
        if animating {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 / 60) { [weak self] in self?.needsDisplay = true }
        }

        // media: centred where there is room; where a notch owns the
        // middle it joins the right cluster, after it is laid out
        let mediaIconFont = nerdFont("Bold", 12) // SF transport glyphs; 16 pt read heavier than the title
        let mediaW = mediaSize(chipFont, mediaIconFont)
        if mediaW > 0, !surface.notched {
            drawMedia(at: (bounds.width - mediaW) / 2, chipFont, mediaIconFont)
        }

        // right cluster: laid out from the right edge inwards, so a pill
        // changing width never shifts the ones outside it
        var cursor = bounds.maxX - PAD_LEFT
        for name in rightOrder.reversed() {
            guard var item = rightItems[name], item.drawing,
                  !(item.icon.isEmpty && item.label.isEmpty),
                  dragName != nil || !(collapsed && collapsible.contains(name)) else { continue }
            // a hidden pill's red dot moves onto the chevron, so it is not lost
            if name == "more" {
                item.badge = collapsed && collapsible.contains { rightItems[$0]?.badge == true && rightItems[$0]?.drawing == true }
            }
            let labelFont = chipFont
            let iconColor = item.stale ? palette.muted : item.iconColor.map { palette[keyPath: $0] } ?? palette.label
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
            let pill = NSRect(x: cursor - width, y: (bounds.height - PILL_HEIGHT) / 2,
                              width: width, height: PILL_HEIGHT)
            let hit = NSRect(x: pill.minX, y: 0, width: width, height: bounds.height)
            // the dragged pill's slot: an empty outline where it will land
            if name == dragName {
                let slot = NSBezierPath(roundedRect: pill.insetBy(dx: 1, dy: 1), xRadius: 6, yRadius: 6)
                slot.lineWidth = 1
                slot.setLineDash([3, 3], count: 2, phase: 0)
                palette.muted.setStroke()
                slot.stroke()
                itemRects.append((name, hit))
                cursor = pill.minX - ITEM_GAP
                continue
            }
            pressing(hit) {
            if hasIcon {
                let box = square ? pill
                    : NSRect(x: pill.minX + ITEM_PAD, y: pill.minY, width: iconInk, height: pill.height)
                drawIcon(item.icon, iconFont, iconColor, centeredIn: box)
                if item.badge {
                    let ink = inkBox(item.icon, iconFont)
                    let c = NSPoint(x: box.midX + ink.width / 2, y: box.midY + ink.height / 2)
                    palette[keyPath: item.badgeColor].setFill()
                    NSBezierPath(ovalIn: NSRect(x: c.x - 3, y: c.y - 3, width: 6, height: 6)).fill()
                }
            }
            if hasLabel {
                drawText(item.label, labelFont, item.stale ? palette.muted : palette.label,
                         leftAt: pill.minX + ITEM_PAD + iconInk + innerGap, midY: pill.midY)
            }
            }
            itemRects.append((name, hit))
            cursor = pill.minX - ITEM_GAP
        }
        // left of the right cluster, unless that runs under the notch:
        // hidden beats half-drawn
        let notchRight = surface.screen.auxiliaryTopRightArea.map { $0.minX - surface.screen.frame.minX } ?? 0
        if mediaW > 0, surface.notched, cursor - GAP - mediaW >= notchRight {
            drawMedia(at: cursor - GAP - mediaW, chipFont, mediaIconFont)
        }
        // hover/press feedback for whatever the pointer is over: one tint
        // laid over the clickable rect, so every target reacts the same way
        if let p = hoverPoint, let r = clickRect(at: p) {
            let box = NSRect(x: r.minX, y: (bounds.height - PILL_HEIGHT) / 2, width: r.width, height: PILL_HEIGHT)
            pressing(r) {
                palette.label.withAlphaComponent(0.1 + 0.12 * (r == scaleRect ? pressAnim : 0)).setFill()
                NSBezierPath(roundedRect: box, xRadius: 6, yRadius: 6).fill()
            }
        }
    }

    // Draws a target shrunk around its centre while it is (or was just)
    // pressed. Hit rects are rebuilt each frame from the same layout, so
    // equality finds the target again; a chip wraps its window icons, so a
    // pressed chip shrinks with them.
    private func pressing(_ hit: NSRect, _ body: () -> Void) {
        guard pressAnim > 0, hit == scaleRect else { return body() }
        // Rasterise at full size, then scale the bitmap. Drawing text and
        // glyphs under a scaled CTM re-lays them out per frame and snaps
        // each to the pixel grid, so they jitter; a bitmap shrinks smoothly.
        let scale = window?.backingScaleFactor ?? 2
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                         pixelsWide: Int((hit.width * scale).rounded(.up)),
                                         pixelsHigh: Int((hit.height * scale).rounded(.up)),
                                         bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                         colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
              let ctx = NSGraphicsContext(bitmapImageRep: rep)
        else { return body() }
        rep.size = hit.size
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        ctx.cgContext.scaleBy(x: scale, y: scale)
        ctx.cgContext.translateBy(x: -hit.minX, y: -hit.minY)
        body()
        NSGraphicsContext.restoreGraphicsState()

        let k = 1 - 0.08 * pressAnim
        let dst = hit.insetBy(dx: hit.width * (1 - k) / 2, dy: hit.height * (1 - k) / 2)
        rep.draw(in: dst, from: .zero, operation: .sourceOver, fraction: 1,
                 respectFlipped: true, hints: [.interpolation: NSNumber(value: NSImageInterpolation.high.rawValue)])
    }

    private var hoverPoint: NSPoint?
    private var pressedRect: NSRect?
    private var pressAnim: CGFloat = 0
    private var scaleRect: NSRect? // the pressed target, kept while release eases out

    // same priority as mouseDown, so the lit rect is the one a click hits
    private func clickRect(at p: NSPoint) -> NSRect? {
        if appleRect.contains(p) { return appleRect }
        return (winRects + chipRects + mediaRects + itemRects).first { $0.1.contains(p) }?.1
    }

    override func mouseMoved(with event: NSEvent) {
        hoverPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    // Right-cluster pills act on mouseUp, not mouseDown, so a press can
    // turn into a drag instead. Dragging reorders live, with the hidden
    // pills shown; dropping one left of the chevron hides it.
    private var downName: String?
    private var downX: CGFloat = 0

    // Native drag: AppKit flies a snapshot of the pill, every bar is a
    // drop target (so pills cross displays), and the slot it would land in
    // is drawn as an outline that moves as the pointer does.
    override func mouseDragged(with event: NSEvent) {
        guard dragName == nil, let name = downName,
              let rect = itemRects.first(where: { $0.0 == name })?.1,
              abs(convert(event.locationInWindow, from: nil).x - downX) > 4 else { return }
        closePopup()
        // snapshot without the press shrink or hover tint
        pressedRect = nil; scaleRect = nil; pressAnim = 0; hoverPoint = nil
        let pill = NSRect(x: rect.minX, y: (bounds.height - PILL_HEIGHT) / 2, width: rect.width, height: PILL_HEIGHT)
        guard let rep = bitmapImageRepForCachingDisplay(in: pill) else { return }
        cacheDisplay(in: pill, to: rep)
        // clipped and tinted like the hover plate, not a square cut of the bar
        let image = NSImage(size: pill.size, flipped: false) { r in
            NSBezierPath(roundedRect: r, xRadius: 6, yRadius: 6).addClip()
            rep.draw(in: r)
            palette.label.withAlphaComponent(0.1).setFill()
            r.fill()
            return true
        }

        let pb = NSPasteboardItem()
        pb.setString(name, forType: barItemType)
        let item = NSDraggingItem(pasteboardWriter: pb)
        item.setDraggingFrame(pill, contents: image)
        dragName = name
        downName = nil
        repaint()
        beginDraggingSession(with: [item], event: event, source: self)
    }

    func draggingSession(_ session: NSDraggingSession,
                         sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation { .move }

    // dropped anywhere — on a bar or not — the live order is the result;
    // AppKit slides the image back itself when it lands outside a bar
    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        dragName = nil
        UserDefaults.standard.set(rightOrder, forKey: "rightOrder")
        repaint()
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { draggingUpdated(sender) }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let name = dragName else { return [] }
        let x = convert(sender.draggingLocation, from: nil).x
        // ponytail: swaps with whichever pill the pointer is over; fine at a dozen pills
        if let over = itemRects.first(where: { $0.0 != name && $0.1.minX <= x && x < $0.1.maxX })?.0,
           let from = rightOrder.firstIndex(of: name), let to = rightOrder.firstIndex(of: over) {
            rightOrder.remove(at: from)
            rightOrder.insert(name, at: to)
            repaint()
        }
        return .move
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool { dragName != nil }

    override func mouseUp(with event: NSEvent) {
        pressedRect = nil
        needsDisplay = true
        defer { downName = nil }
        guard let name = downName, let rect = itemRects.first(where: { $0.0 == name })?.1 else { return }
        activate(name, rect)
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

    override func mouseExited(with event: NSEvent) {
        hoverPoint = nil
        pressedRect = nil
        needsDisplay = true
        scheduleHullCheck()
    }

    private func hit(_ event: NSEvent) -> String? {
        let p = convert(event.locationInWindow, from: nil)
        return itemRects.first(where: { $0.1.contains(p) })?.0
    }

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        hoverPoint = p
        pressedRect = clickRect(at: p)
        scaleRect = pressedRect
        needsDisplay = true
        if appleRect.contains(p), let surface {
            appMenuStack.removeAll()
            // clicking the bar deactivated the app, which makes its menu
            // items read disabled and presses land nowhere — hand focus
            // straight back while our popup (never key) stays up
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
            case "prev": spotifast("previous")
            case "play": spotifast("play-pause")
            case "next": spotifast("next")
            default: spotifast("show")
            }
            return
        }
        guard let name = hit(event) else {
            closePopup()
            return
        }
        downName = name
        downX = p.x
    }

    private func activate(_ name: String, _ rect: NSRect) {
        // left click toggles with the last mode; its menu is on the right button
        if name == "caffeinate" {
            closePopup()
            caffProc == nil ? startCaffeinate(caffFlags) : stopCaffeinate()
            return
        }
        // an item with a popup toggles it; the rest still act directly
        if let surface, showPopup(name, under: window?.convertToScreen(convert(rect, to: nil)) ?? rect, on: surface) {
            return
        }
        closePopup()
        switch name {
        case "more":
            collapsed.toggle()
            set("more") { $0.icon = collapsed ? "sf:chevron.left" : "sf:chevron.right" }
        case "activity":
            DispatchQueue.global(qos: .userInitiated).async {
                // login zsh: a launchd agent's PATH lacks /opt/homebrew/bin
                _ = shell("/usr/bin/open", ["-na", terminalApp, "--args", "--title=statusbar-activity", "-e", "/bin/zsh", "-lc", "btop"])
            }
        default: break
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        if mediaRects.contains(where: { $0.0 == "title" && $0.1.contains(p) }) {
            marqueeOn.toggle()
            repaint()
            return
        }
        guard let name = hit(event), name == "caffeinate" || name == "agents", let surface,
              let rect = itemRects.first(where: { $0.0 == name })?.1 else { return }
        // the agents pill picks its orchestrator on the right button
        showPopup(name == "agents" ? "agents:pick" : name,
                  under: window?.convertToScreen(convert(rect, to: nil)) ?? rect, on: surface)
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

// On a notched display safeAreaInsets.top is the native menu bar's height
// (38 on a 14"/16"), and it holds while that menu bar is auto-hidden.
func barHeight(_ screen: NSScreen) -> CGFloat {
    screen.safeAreaInsets.top > 0 ? screen.safeAreaInsets.top : BAR_HEIGHT
}

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
    // the right cluster there — the same rule the shell bar applies, but
    // read from the screen itself instead of asked of a helper.
    var notched: Bool { screen.safeAreaInsets.top > 0 }

    var height: CGFloat { barHeight(screen) }

    init(screen: NSScreen, monitorID: String) {
        self.screen = screen
        self.monitorID = monitorID
        let frame = NSRect(x: screen.frame.minX, y: screen.frame.maxY - barHeight(screen) - stackOffset,
                           width: screen.frame.width, height: barHeight(screen))
        window = BarWindow(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel],
                           backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = BAR_LEVEL
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.acceptsMouseMovedEvents = true // tracking areas need the moves
        view = BarView(frame: NSRect(origin: .zero, size: frame.size))
        view.registerForDraggedTypes([barItemType])
        window.contentView = view
        view.surface = self
        if !fullscreenDisplays().contains(screenID(screen)) { window.orderFrontRegardless() }
    }

    func place() {
        let frame = NSRect(x: screen.frame.minX, y: screen.frame.maxY - height - stackOffset,
                           width: screen.frame.width, height: height)
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
            // the stream groups windows by APP (one entry, allWindows
            // inside); the snapshot is per window. Same shape here, or the
            // two paths disagree on every rebuild and the chips flicker.
            var wins: [BarWin] = []
            for group in (w["windows"] as? [[String: Any]]) ?? [] {
                guard let app = group["appName"] as? String, !app.hasPrefix("statusbar") else { continue }
                for win in (group["allWindows"] as? [[String: Any]]) ?? [group] {
                    guard let id = win["id"] as? String, !model.floating.contains(id) else { continue }
                    wins.append(BarWin(app: app, id: id, focused: (win["isFocused"] as? Bool) == true))
                }
            }
            if !wins.isEmpty {
                occupied.insert(name)
                apps[name] = wins
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

// location: one coordinate for the weather, same responsible-process rules
locationGate.start()

// waking clears the gamma table, so the shade has to be reasserted.
NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
) { _ in
    applyShade()
}

// Polls pause while nobody can see the bar: screens asleep, screen locked,
// user switched out. Each would otherwise spawn a CLI every few seconds.
var pauseReasons: Set<String> = []
func pausePolls(_ why: String, _ on: Bool) {
    let wasPaused = !pauseReasons.isEmpty
    if on { pauseReasons.insert(why) } else { pauseReasons.remove(why) }
    tlog("polls: \(why) \(on ? "pause" : "resume") -> \(pauseReasons.isEmpty ? "running" : "paused")")
    guard wasPaused, pauseReasons.isEmpty else { return }
    // back in view: catch up now rather than at the next tick (weather is
    // 30 min out). ponytail: 5 s for the network to come back after a wake
    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
        guard pauseReasons.isEmpty else { return }
        updateMedia(); locationGate.refresh(); updateTailscale(); updateClaude(); updateHome(); updateAgents()
    }
}
for (name, why, on): (NSNotification.Name, String, Bool) in [
    (NSWorkspace.screensDidSleepNotification, "screens", true),
    (NSWorkspace.screensDidWakeNotification, "screens", false),
    (NSWorkspace.sessionDidResignActiveNotification, "session", true),
    (NSWorkspace.sessionDidBecomeActiveNotification, "session", false),
] {
    NSWorkspace.shared.notificationCenter.addObserver(forName: name, object: nil, queue: .main) { _ in
        pausePolls(why, on)
    }
}
for (name, on) in [("com.apple.screenIsLocked", true), ("com.apple.screenIsUnlocked", false)] {
    DistributedNotificationCenter.default().addObserver(forName: .init(name), object: nil, queue: .main) { _ in
        pausePolls("locked", on)
    }
}

// 10% tolerance lets the system coalesce the wakeups
func poll(_ interval: TimeInterval, _ body: @escaping () -> Void) {
    let t = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
        if pauseReasons.isEmpty { body() }
    }
    t.tolerance = interval / 10
}

// media: launch and quit repaint at once, the track itself is polled
for event in [NSWorkspace.didLaunchApplicationNotification,
              NSWorkspace.didTerminateApplicationNotification] {
    NSWorkspace.shared.notificationCenter.addObserver(forName: event, object: nil, queue: .main) { note in
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == spotifastBundleID else { return }
        updateMedia()
    }
}
poll(MEDIA_POLL) { updateMedia() }

// clock and weather have no publisher to listen to. The clock ticks on
// the minute boundary rather than every 60 s from launch, so it never
// shows a stale minute.
func scheduleClock() {
    updateClock()
    updateEvents()
    updateCaffeinate() // the minutes-left label
    let now = Date()
    let nextMinute = Calendar.current.nextDate(after: now, matching: DateComponents(second: 0),
                                               matchingPolicy: .nextTime) ?? now.addingTimeInterval(60)
    DispatchQueue.main.asyncAfter(deadline: .now() + max(1, nextMinute.timeIntervalSinceNow)) { scheduleClock() }
}
scheduleClock()

poll(WEATHER_POLL) { locationGate.refresh() }
// ponytail: 15 s poll; `tailscale debug watch-ipn` streams changes if this lags
poll(TAILSCALE_POLL) { updateTailscale() }
poll(CLAUDE_POLL) { updateClaude() }
poll(HOME_POLL) { updateHome() }
poll(AGENTS_POLL) { updateAgents() }
poll(ACTIVITY_POLL) { updateActivity() }
NotificationCenter.default.addObserver(forName: ProcessInfo.thermalStateDidChangeNotification, object: nil,
                                       queue: .main) { _ in updateActivity() }

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
updateActivity() // primes the cpu ticks; the first busy figure comes a poll later
rightItems["more"] = BarItem(icon: "sf:chevron.left", iconColor: \.muted)
applyShade() // restore the level this machine was left at
// a flag left on disk means we died in lid mode: put disablesleep back
if lidSetByUs { tlog("lid: undoing disablesleep left by a crash"); lidSetByUs = false; setDisableSleep(false) }
updateBattery()
updateBrightness()
updateTheme()
updateWeather()
updateTailscale()
updateLayout()
updateClaude()
updateHome()
updateAgents()
NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: eventStore,
                                       queue: .main) { _ in updateEvents() }
eventStore.requestFullAccessToEvents { granted, _ in
    if granted { DispatchQueue.main.async { updateEvents() } }
}
DistributedNotificationCenter.default().addObserver(
    forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
    object: nil, queue: .main) { _ in updateLayout() }
repaint()
updateMedia()
reconcile("startup") // the OmniWM watch, and retries for a manager not up yet
tlog("statusbar up on " + surfaces.map { "\($0.screen.localizedName)=m\($0.monitorID)\($0.notched ? " (notched)" : "")" }.joined(separator: ", "))
app.run()
