import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

// --- window ---------------------------------------------------------------



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
