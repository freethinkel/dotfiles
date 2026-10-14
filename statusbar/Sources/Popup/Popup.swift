import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

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
