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

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

var labelsFromOmniWM = omniwmActive()

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
