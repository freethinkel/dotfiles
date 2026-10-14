import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

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
