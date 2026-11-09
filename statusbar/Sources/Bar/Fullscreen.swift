import AppKit

// --- fullscreen ------------------------------------------------------------
// A display is "fullscreen" when some app window spans its full width and
// reaches its top edge — tiled windows never do, the WM's outer gap keeps
// them under the bar. Covers native fullscreen (starts below the notch,
// hence the safe-area slack).
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
        for w in list where (w[kCGWindowOwnerPID as String] as? Int) != me
            && ((w[kCGWindowAlpha as String] as? Double) ?? 1) > 0 {
            guard let b = w[kCGWindowBounds as String] as? [String: CGFloat],
                  let x = b["X"], let y = b["Y"], let width = b["Width"], let height = b["Height"]
            else { continue }
            // GLFW games (Minecraft) go fullscreen at main-menu level + 1 (25),
            // not as a native fullscreen Space. Only whole-screen windows there:
            // status items share the level. Not any layer: Dock and Snap keep
            // transparent whole-screen overlays at 20.
            let layer = w[kCGWindowLayer as String] as? Int ?? 0
            guard layer == 0 || (layer == 25 && height >= screen.frame.height - 2) else { continue }
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
            if surface.window.isVisible { tlog("fullscreen: hiding on \(surface.screen.localizedName)") }
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
