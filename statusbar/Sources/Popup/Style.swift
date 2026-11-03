import AppKit
import SwiftUI

// --- popup style -----------------------------------------------------------
// Every popup is drawn from the pieces below: change a size, a colour or a
// control here and every item's popup follows. The controls are native,
// tinted with the palette's accent.

let ROW_HEIGHT: CGFloat = 26      // text rows, table cells
let BUTTON_HEIGHT: CGFloat = 30   // clickable rows: actions, switches
let HEADER_HEIGHT: CGFloat = 24   // section titles, text sitting on the bottom
let POPUP_PAD: CGFloat = 6        // popup edge
let ROW_PAD: CGFloat = 4          // inside a row, each side
let ROW_SPACING: CGFloat = 8      // between a row's pieces
let PLATE_RADIUS: CGFloat = 6     // hover / highlight plate
let CELL_PAD: CGFloat = 14        // table cells: added to the widest cell of a column
let POPUP_ICON_SIZE = ICON_SIZE   // leading icons, the bar's own size
let SLIDER_ICON_SIZE: CGFloat = 20 // a slider row's icon

extension PopupRow {
    var font: NSFont { header ? nerdFont("Bold", 11) : nerdFont(hero ? "Bold" : "Regular", dim ? 12 : 13) }
    // accent stays for tints and marks: as text on clear glass it washes out
    var color: Color { dim || header ? .secondary : .primary }
}

// hover is a menu selection: accent plate, ink in the bar colour, the pair
// the calendar's today already uses
func popupInk(_ selected: Bool) -> NSColor? { selected ? palette.barBG : nil }

struct PopupPlate: View {
    var selected = false
    var highlight = false // a quiet plate: the meeting on now, the menu you're in

    var body: some View {
        RoundedRectangle(cornerRadius: PLATE_RADIUS)
            .fill(selected ? Color(nsColor: palette.accent) : highlight ? Color.primary.opacity(0.1) : .clear)
            .padding(.horizontal, -2).padding(.vertical, 2)
    }
}

// a whole row as a button: taller, selected on hover; the label gets the
// hover state to pick its ink. A quiet one (a switch row) only gets the
// soft plate: on the accent selection the switch's own accent would vanish.
struct PopupButton<Label: View>: View {
    var highlight = false
    var quiet = false
    let action: () -> Void
    @ViewBuilder let label: (_ selected: Bool) -> Label
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            label(hovered && !quiet)
                .frame(height: BUTTON_HEIGHT)
                .background(PopupPlate(selected: hovered && !quiet, highlight: highlight || hovered))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}

// inset to the row text, so it reads as a break inside the list rather than a frame
struct PopupSeparator: View {
    var body: some View { Divider().padding(.horizontal, ROW_PAD).padding(.vertical, 4) }
}

// a palette as one strip: the chips touch, the strip is rounded
struct PopupSwatches: View {
    let colors: [NSColor]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, c in
                Rectangle().fill(Color(nsColor: c)).frame(width: 11)
            }
        }
        .frame(height: 12)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(.primary.opacity(0.15), lineWidth: 0.5))
    }
}

// one of a set, NSMenu-style; the column stays when unchecked so labels line up
struct PopupCheck: View {
    let on: Bool
    var ink: NSColor? = nil

    var body: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(ink.map { Color(nsColor: $0) } ?? .primary)
            .opacity(on ? 1 : 0)
            .frame(width: 12)
    }
}

// native, tinted with the bar's accent; a click on the switch flips it, and
// so does one anywhere else on its row (the row is a button)
struct PopupSwitch: View {
    let on: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        Toggle("", isOn: Binding(get: { on }, set: onToggle))
            .toggleStyle(.switch).controlSize(.mini).labelsHidden()
            .tint(Color(nsColor: palette.accent))
    }
}

struct PopupSlider: View {
    let value: Double // 0...1
    let onChange: (Double) -> Void

    var body: some View {
        Slider(value: Binding(get: { value }, set: onChange))
            .controlSize(.small)
            .tint(Color(nsColor: palette.accent))
    }
}
