import AppKit

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
    // the key SkyLight files this display's Spaces under
    var monitorID: String { displayUUID(screen) }
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

    init(screen: NSScreen) {
        self.screen = screen
        let frame = barFrame(screen, height: barHeight(screen))
        window = BarWindow(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel],
                           backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = BAR_LEVEL
        window.collectionBehavior = [.canJoinAllSpaces]
        window.acceptsMouseMovedEvents = true // tracking areas need the moves
        view = BarView(frame: NSRect(origin: .zero, size: frame.size))
        view.registerForDraggedTypes([barItemType])
        window.contentView = view
        view.surface = self
        if !fullscreenDisplays().contains(screenID(screen)) { window.orderFrontRegardless() }
    }

    func place() {
        let frame = barFrame(screen, height: height)
        window.setFrame(frame, display: true)
        view.frame = NSRect(origin: .zero, size: frame.size)
    }
}

// 1 pt past both sides of the screen: a window spanning the top edge from side to side is hidden by WindowServer
// for the whole of Dock's Space switch, whatever its level (measured in nori, docs/WINDOWSERVER.md there).
func barFrame(_ screen: NSScreen, height: CGFloat) -> NSRect {
    NSRect(x: screen.frame.minX - 1, y: screen.frame.maxY - height - stackOffset, width: screen.frame.width + 2, height: height)
}

var surfaces: [BarSurface] = []

func screenID(_ screen: NSScreen) -> CGDirectDisplayID {
    (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
}

func displayUUID(_ screen: NSScreen) -> String {
    guard let uuid = CGDisplayCreateUUIDFromDisplayID(screenID(screen))?.takeRetainedValue() else { return "" }
    return CFUUIDCreateString(nil, uuid) as String
}

// One bar per display; a display's Spaces come from SkyLight by its UUID.
func rebuildSurfaces() {
    var kept: [BarSurface] = []
    for screen in NSScreen.screens {
        if let existing = surfaces.first(where: { screenID($0.screen) == screenID(screen) }) {
            existing.screen = screen
            existing.place()
            kept.append(existing)
        } else {
            tlog("surface: \(screen.localizedName) -> \(displayUUID(screen))\(screen.safeAreaInsets.top > 0 ? " (notched)" : "")")
            kept.append(BarSurface(screen: screen))
        }
    }
    for gone in surfaces where !kept.contains(where: { $0 === gone }) {
        tlog("surface: \(gone.screen.localizedName) went away")
        gone.window.orderOut(nil)
    }
    surfaces = kept
}

// Drops a bar-height BEFORE the pointer reaches the bar: dropped only on
// arrival, the menu bar began its reveal under ours and showed up late,
// already open, or not at all.
// ponytail: a Space slide while the pointer is that close takes the bar along
func updateBarLevel() {
    let p = NSEvent.mouseLocation
    for surface in surfaces {
        let f = surface.window.frame
        // +1: at the very top the pointer sits ON maxY, which contains() leaves out
        let near = NSRect(x: f.minX, y: f.minY - f.height, width: f.width, height: f.height * 2 + 1)
        let level = near.contains(p) ? BAR_LEVEL_HOVER : BAR_LEVEL
        if surface.window.level != level { surface.window.level = level }
    }
}

// Invalidation only: AppKit draws once at the end of the run-loop pass,
// so a burst (the minute tick sets clock, events and caffeinate) is one
// frame, not three. BarView.draw logs the slow ones itself.
func repaint() {
    MainActor.assumeIsolated {
        for surface in surfaces { surface.view.needsDisplay = true }
    }
}
