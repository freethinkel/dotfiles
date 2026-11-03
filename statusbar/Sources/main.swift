// statusbar — a native menu bar for nori, in ONE process.
//
// Left: Space chips with one icon per window, fed by nori's subscribe
// stream over its socket, no subprocess. Right: pills whose
// sources are read in process and publish — IOPS, CoreAudio,
// EventKit, TIS — so only the clock and the network
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
    kickVisibility()
    model.frontApp = name
    repaint()
    let ms = Double(DispatchTime.now().uptimeNanoseconds - t0) / 1_000_000
    tlog(String(format: "frontapp %@ %.2f ms", name, ms))
}


// Displays come and go: move the windows onto them, and rebuild. Screen parameters arrive
// before the arrangement settles, so give it a beat (borders.swift learnt
// the same lesson with a stale CG-to-Cocoa flip after a replug).
NotificationCenter.default.addObserver(
    forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
) { _ in
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        closePopup() // its anchor may not exist any more
        rebuildSurfaces()
        apply(noriState)
        repaint()
    }
}


let notify: NotifyProc = { event, _, _, _ in
    DispatchQueue.main.async {
        // the chips come from nori; these only keep the bar out of fullscreen
        if event == EVENT_WINDOW_CREATE || event == EVENT_WINDOW_DESTROY { rebuildSubscriptions() }
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
    if popover != nil, pointerLeftTheHull() { closePopup() }
}

// the bar's own moves drop its level (BarView.mouseMoved); these raise it
// again, including when the pointer leaves through the native menu bar
// that slid in over it
let barLevelToken = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { _ in updateBarLevel() }

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

// night shift: same idea one layer up — the schedule flipping it is a
// change nobody else would tell an open popup about
watchNightShift()

// location: one coordinate for the weather, same responsible-process rules
locationGate.start()

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
        updateMedia(); locationGate.refresh(); updateTailscale(); updateClaude(); updateHome()
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
poll(ACTIVITY_POLL) { updateActivity() }
NotificationCenter.default.addObserver(forName: ProcessInfo.thermalStateDidChangeNotification, object: nil,
                                       queue: .main) { _ in updateActivity() }

// --- go -------------------------------------------------------------------

model.frontApp = NSWorkspace.shared.frontmostApplication?.localizedName ?? ""
rebuildSurfaces()
guard !surfaces.isEmpty else {
    FileHandle.standardError.write("statusbar: no display\n".data(using: .utf8)!)
    exit(1)
}
startNoriStream()
updateActivity() // primes the cpu ticks; the first busy figure comes a poll later
rightItems["more"] = BarItem(icon: "sf:chevron.left", iconColor: \.muted)
// a flag left on disk means we died in lid mode: put disablesleep back
if lidSetByUs { tlog("lid: undoing disablesleep left by a crash"); lidSetByUs = false; setDisableSleep(false) }
updateBattery()
updateTheme()
updateWeather()
updateTailscale()
updateLayout()
updateClaude()
updateHome()
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
tlog("statusbar up on " + surfaces.map { "\($0.screen.localizedName)=\($0.monitorID)\($0.notched ? " (notched)" : "")" }.joined(separator: ", "))
app.run()
