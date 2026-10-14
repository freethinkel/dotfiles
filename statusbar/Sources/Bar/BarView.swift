import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

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
        if appleRect.contains(p) {
            appMenuStack.removeAll()
            // clicking the bar deactivated the app, which makes its menu
            // items read disabled and presses land nowhere — hand focus
            // straight back while our popup (never key) stays up
            NSWorkspace.shared.runningApplications
                .first { $0.localizedName == model.frontApp }?
                .activate()
            showPopup("apple", of: self, at: appleRect)
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
        if showPopup(name, of: self, at: rect) {
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
        guard let name = hit(event), name == "caffeinate" || name == "agents",
              let rect = itemRects.first(where: { $0.0 == name })?.1 else { return }
        // the agents pill picks its orchestrator on the right button
        showPopup(name == "agents" ? "agents:pick" : name, of: self, at: rect)
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
