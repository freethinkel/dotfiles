import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

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
    var rows = [PopupRow(text: "awake", hero: true, toggle: caffProc != nil, onToggle: { on in
        on ? startCaffeinate(caffFlags) : stopCaffeinate()
        refreshPopup()
    })]
    for m in CAFF_MODES {
        rows.append(PopupRow(text: m.text, detail: m.flags == "lid" ? "-i + pmset" : m.flags,
                             checked: m.flags == caffFlags, action: {
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
    // night shift lives here rather than in a pill of its own
    if blueLightStatus()?.available.boolValue == true { rows.append(PopupRow(separator: true)) }
    // read in process, every time the rows are built: the row says what
    // CoreBrightness says now, and a Mac without night shift gets no row
    // rather than a lying one
    if let ns = blueLightStatus(), ns.available.boolValue {
        let on = ns.enabled.boolValue
        rows.append(PopupRow(text: "night shift", toggle: on, onToggle: { on in
            setNightShift(on)
            refreshPopup()
        }))
    }
    return rows
}
