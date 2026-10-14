import AppKit
import SwiftUI

// --- popups ----------------------------------------------------------------
// A popup is a list of rows in an NSPopover: the system draws the glass,
// the arrow and the native controls (switches, sliders), the rows say
// what goes in it. Rows are plain data, rebuilt on every refresh.

struct PopupRow {
    var icon = ""
    var image: NSImage? // 16pt leading icon — Recent Items entries
    var text = ""
    var detail = "" // right-aligned, dim — menu shortcuts live here
    var swatches: [NSColor] = [] // right-aligned colour chips — theme previews
    var separator = false // a thin rule instead of content
    var hero = false // accent, bold — the title row
    var dim = false // the quiet action footer
    var highlight = false // a quiet plate: the meeting on now, the menu you're in
    var checked: Bool? // one of a set: ✓ when true, nil when the row is no choice
    var slider: Double? // 0...1, a native slider; the text is its readout
    var onSlide: ((Double) -> Void)?
    var toggle: Bool? // a trailing switch
    var onToggle: ((Bool) -> Void)?
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
    var pager: ((Int) -> Void)? // ‹ title ›, either arrow pages by ∓1
    var minWidth: CGFloat = 0 // content width floor, so the popup keeps its size between pages
}

// every icon kind the bar knows (sf:, nerd glyphs, ts, agents:, keycaps)
// goes through the bar's own drawIcon, so the popup can't drift from it
func iconImage(_ s: String, _ font: NSFont, _ color: NSColor) -> NSImage {
    NSImage(size: NSSize(width: ceil(inkBox(s, font).width), height: ROW_HEIGHT), flipped: false) { r in
        drawIcon(s, font, color, centeredIn: r)
        return true
    }
}

extension PopupRow {
    var font: NSFont { nerdFont(hero ? "Bold" : "Regular", dim ? 12 : 13) }
    // accent stays for tints and marks: as text on clear glass it washes out
    var color: Color { dim ? .secondary : .primary }
}

struct PopupRowView: View {
    let row: PopupRow
    var checkColumn = false // the popup has a choice somewhere: every row keeps the ✓ column, like NSMenu
    @State private var hovered = false
    // hover is a menu selection: accent plate, text in the bar colour, the
    // pair the calendar's today already uses
    private var ink: NSColor? { hovered ? palette.barBG : nil }

    var body: some View {
        if row.separator {
            Divider().padding(.vertical, 4)
        } else if let pager = row.pager {
            HStack {
                arrow("‹") { pager(-1) }
                Spacer()
                Text(verbatim: row.text).font(Font(row.font)).foregroundStyle(row.color)
                Spacer()
                arrow("›") { pager(1) }
            }
            .frame(minWidth: row.minWidth, minHeight: ROW_HEIGHT)
        } else if let value = row.slider {
            HStack(spacing: 8) {
                leading
                Slider(value: Binding(get: { value }, set: { row.onSlide?($0) }))
                    .controlSize(.small)
                    .frame(minWidth: 150)
                Text(verbatim: row.text).font(Font(row.font)).monospacedDigit()
                    .frame(minWidth: 40, alignment: .trailing)
            }
            .padding(.horizontal, 4)
            .frame(height: ROW_HEIGHT)
        } else if let action = row.action {
            Button(action: action) { content }
                .buttonStyle(.plain)
                .onHover { hovered = $0 }
        } else {
            content
        }
    }

    private func arrow(_ s: String, _ step: @escaping () -> Void) -> some View {
        Button(action: step) {
            Text(verbatim: s).font(Font(row.font)).foregroundStyle(row.color)
                .frame(width: 28, height: ROW_HEIGHT).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var leading: some View {
        if checkColumn {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ink.map { Color(nsColor: $0) } ?? .primary)
                .opacity(row.checked == true ? 1 : 0)
                .frame(width: 12)
        }
        if let bar = row.bar {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color(nsColor: bar).opacity(row.strike || row.dim ? 0.4 : 1))
                .frame(width: 3).padding(.vertical, 5)
        }
        if let image = row.image {
            Image(nsImage: image).resizable().frame(width: 16, height: 16)
        }
        if !row.icon.isEmpty {
            Image(nsImage: iconImage(row.icon, nerdFont("Bold", 13), ink ?? palette.accent))
        }
    }

    private var content: some View {
        HStack(spacing: 8) {
            leading
            Text(verbatim: row.text)
                .font(Font(row.font))
                .strikethrough(row.strike)
                .foregroundStyle(ink.map { Color(nsColor: $0) } ?? row.color)
            Spacer(minLength: 16)
            if !row.swatches.isEmpty {
                HStack(spacing: 4) {
                    ForEach(Array(row.swatches.enumerated()), id: \.offset) { _, chip in
                        RoundedRectangle(cornerRadius: 3).fill(Color(nsColor: chip))
                            .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(.primary.opacity(0.2), lineWidth: 0.5))
                            .frame(width: 10, height: 10)
                    }
                }
            }
            if !row.detail.isEmpty {
                Text(verbatim: row.detail).font(Font(nerdFont("Regular", 11)))
                    .foregroundStyle(ink.map { Color(nsColor: $0).opacity(0.7) } ?? .secondary)
            }
            if let on = row.toggle {
                Toggle("", isOn: Binding(get: { on }, set: { row.onToggle?($0) }))
                    .toggleStyle(.switch).controlSize(.mini).labelsHidden()
            }
        }
        .padding(.horizontal, 4)
        .frame(height: ROW_HEIGHT)
        .background(RoundedRectangle(cornerRadius: 6)
            .fill(hovered ? Color(nsColor: palette.accent) : row.highlight ? Color.primary.opacity(0.1) : .clear)
            .padding(.horizontal, -2).padding(.vertical, 2))
        .contentShape(Rectangle())
    }
}

// consecutive rows with the same cell count share a Grid, so their columns line up
struct PopupTable: View {
    let rows: [PopupRow]

    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            // ponytail: positional identity, rows carry no ids and are rebuilt whole
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(Array(row.cells.enumerated()), id: \.offset) { k, cell in
                        self.cell(row, k, cell)
                    }
                }
            }
        }
    }

    @ViewBuilder private func cell(_ row: PopupRow, _ k: Int, _ cell: String) -> some View {
        let marked = k == row.cellMark
        let dots = k < row.cellDots.count ? Array(row.cellDots[k].prefix(3)) : []
        // a 2-cell label row is key/value: the value reads left-aligned
        let left = row.labelCol && (k == 0 || row.cells.count == 2)
        let tint: Color = marked ? Color(nsColor: palette.barBG)
            : row.cellDim.contains(k) ? .primary.opacity(0.4) : row.color
        let face = Group {
            if cell.hasPrefix("sf:") {
                Image(nsImage: iconImage(cell, row.font, marked ? palette.barBG : palette.label))
            } else {
                Text(verbatim: cell).font(Font(row.font)).foregroundStyle(tint)
            }
        }
        .offset(y: row.cellDots.isEmpty ? 0 : -3)
        .padding(.horizontal, CELL_PAD / 2)
        .frame(height: ROW_HEIGHT)
        .background {
            let plate = RoundedRectangle(cornerRadius: RADIUS)
            if marked { plate.fill(Color(nsColor: palette.accent)).padding(.horizontal, 1).padding(.vertical, 2) }
            else if k == row.cellRing { plate.strokeBorder(Color(nsColor: palette.accent)).padding(.horizontal, 1).padding(.vertical, 2) }
        }
        .overlay(alignment: .bottom) {
            HStack(spacing: 2) {
                ForEach(Array(dots.enumerated()), id: \.offset) { _, dot in
                    Circle().fill(marked ? Color(nsColor: palette.barBG) : Color(nsColor: dot)).frame(width: 3, height: 3)
                }
            }
            .padding(.bottom, 5)
        }
        .gridCellAnchor(left ? .leading : .center)
        if let onCell = row.onCell {
            Button { onCell(k) } label: { face.contentShape(Rectangle()) }.buttonStyle(.plain)
        } else {
            face
        }
    }
}

struct PopupContent: View {
    let rows: [PopupRow]

    // runs of table rows become one block, everything else is a row
    private var blocks: [Range<Int>] {
        var out: [Range<Int>] = []
        var i = 0
        while i < rows.count {
            var j = i + 1
            let n = rows[i].cells.count
            if n > 0 { while j < rows.count && rows[j].cells.count == n { j += 1 } }
            out.append(i..<j)
            i = j
        }
        return out
    }

    private var checkColumn: Bool { rows.contains { $0.checked != nil } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(blocks, id: \.lowerBound) { block in
                if rows[block.lowerBound].cells.isEmpty {
                    PopupRowView(row: rows[block.lowerBound], checkColumn: checkColumn)
                } else {
                    let table = PopupTable(rows: Array(rows[block]))
                    // label tables hug the left edge; a bare grid (the calendar) centres
                    if rows[block.lowerBound].labelCol { table } else { table.frame(maxWidth: .infinity) }
                }
            }
        }
        .padding(POPUP_PAD)
        .tint(Color(nsColor: palette.accent))
        .onHover { if !$0 { scheduleHullCheck() } }
    }
}

var popover: NSPopover?
var popupHost: NSHostingController<AnyView>?
var openPopup: String? // which bar item owns it
var popupMaxH: CGFloat = 800 // the anchor screen's room under the bar

func popupFrame() -> NSRect? { popover?.contentViewController?.view.window?.frame }

func closePopup() {
    calDay = nil // the calendar reopens on today
    popover?.close()
    popover = nil
    popupHost = nil
    openPopup = nil
}

// taller-than-screen content (Recent Items) scrolls inside a capped popover
func popupRoot(_ rows: [PopupRow]) -> (AnyView, NSSize) {
    let content = PopupContent(rows: rows).fixedSize()
    let fit = NSHostingView(rootView: content).fittingSize
    guard fit.height > popupMaxH else { return (AnyView(content), fit) }
    let size = NSSize(width: fit.width + 12, height: popupMaxH)
    return (AnyView(ScrollView { content }.frame(width: size.width, height: size.height)), size)
}

// rows are rebuilt, not patched: the content is cheap to regenerate and a
// stale row is worse than a redrawn one
func refreshPopup() {
    guard let name = openPopup, let host = popupHost, let popover else { return }
    let (root, size) = popupRoot(popupRows(for: name))
    host.rootView = root
    popover.contentSize = size
}

// false when the item has no popup to show
@discardableResult
func showPopup(_ name: String, of view: NSView, at rect: NSRect) -> Bool {
    if openPopup == name { closePopup(); return true }
    closePopup()
    let rows = popupRows(for: name)
    guard !rows.isEmpty else { return false }
    popupMaxH = (view.window?.screen?.visibleFrame.height ?? 800) - 40
    let (root, size) = popupRoot(rows)
    let host = NSHostingController(rootView: root)
    host.sizingOptions = [] // contentSize is ours, set on every refresh
    let p = NSPopover()
    // closing is the hull check's job: .transient would need this app active
    p.behavior = .applicationDefined
    p.contentViewController = host
    p.contentSize = size
    let bg = palette.barBG.usingColorSpace(.sRGB) ?? palette.barBG
    let light = bg.redComponent * 0.299 + bg.greenComponent * 0.587 + bg.blueComponent * 0.114 > 0.5
    p.appearance = NSAppearance(named: light ? .aqua : .darkAqua)
    p.show(relativeTo: rect, of: view, preferredEdge: .minY)
    // non-activating, like the bar: a click on a switch must not pull focus
    // off the front app. The style bit alone does nothing on a window that
    // already exists (WindowServer keeps the tag it was created with), the
    // private setter is what re-tags it.
    if let w = host.view.window as? NSPanel {
        w.styleMask.insert(.nonactivatingPanel)
        let sel = NSSelectorFromString("_setPreventsActivation:")
        if let m = class_getInstanceMethod(type(of: w), sel) {
            typealias SetBool = @convention(c) (AnyObject, Selector, Bool) -> Void
            unsafeBitCast(method_getImplementation(m), to: SetBool.self)(w, sel, true)
        }
    }
    popover = p
    popupHost = host
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
        if popover != nil, pointerLeftTheHull() { closePopup() }
    }
}

func pointerLeftTheHull() -> Bool {
    guard let frame = popupFrame() else { return false }
    let p = NSEvent.mouseLocation
    let slack: CGFloat = 6 // the gap between a bar and its popup
    if frame.insetBy(dx: -slack, dy: -slack).contains(p) { return false }
    for surface in surfaces where surface.window.frame.insetBy(dx: 0, dy: -slack).contains(p) {
        return false
    }
    return true
}
