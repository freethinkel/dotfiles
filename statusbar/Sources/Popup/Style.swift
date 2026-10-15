import AppKit
import SwiftUI

// --- popup style -----------------------------------------------------------
// Every popup is drawn from the pieces below: change a size, a colour or a
// control here and every item's popup follows. The controls are drawn, not
// native: the bar's app is never active, so NSSwitch / NSSlider render in
// their inactive grey instead of the accent.

let ROW_HEIGHT: CGFloat = 26      // text rows, table cells
let BUTTON_HEIGHT: CGFloat = 30   // clickable rows: actions, switches
let POPUP_PAD: CGFloat = 6        // popup edge
let ROW_PAD: CGFloat = 4          // inside a row, each side
let ROW_SPACING: CGFloat = 8      // between a row's pieces
let PLATE_RADIUS: CGFloat = 6     // hover / highlight plate
let CELL_PAD: CGFloat = 14        // table cells: added to the widest cell of a column
let POPUP_ICON_SIZE = ICON_SIZE   // leading icons, the bar's own size

extension PopupRow {
    var font: NSFont { nerdFont(hero ? "Bold" : "Regular", dim ? 12 : 13) }
    // accent stays for tints and marks: as text on clear glass it washes out
    var color: Color { dim ? .secondary : .primary }
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
// hover state to pick its ink
struct PopupButton<Label: View>: View {
    var highlight = false
    let action: () -> Void
    @ViewBuilder let label: (_ selected: Bool) -> Label
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            label(hovered)
                .frame(height: BUTTON_HEIGHT)
                .background(PopupPlate(selected: hovered, highlight: highlight))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}

struct PopupSeparator: View {
    var body: some View { Divider().padding(.vertical, 2) }
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

// a readout, not a control: the row it sits in does the flipping
struct PopupSwitch: View {
    let on: Bool
    var ink: NSColor? = nil // on an accent plate the accent would vanish

    var body: some View {
        Capsule()
            .fill(on ? Color(nsColor: ink ?? palette.accent) : Color.primary.opacity(0.15))
            .frame(width: 26, height: 15)
            .overlay(alignment: on ? .trailing : .leading) {
                Circle().fill(.white).shadow(color: .black.opacity(0.25), radius: 0.5, y: 0.5).padding(1.5)
            }
            .animation(.snappy(duration: 0.15), value: on)
    }
}

struct PopupSlider: View {
    let value: Double // 0...1
    let onChange: (Double) -> Void

    var body: some View {
        GeometryReader { g in
            let k: CGFloat = 14, track = max(g.size.width - k, 1)
            let x = track * CGFloat(min(max(value, 0), 1))
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.15)).frame(height: 4)
                Capsule().fill(Color(nsColor: palette.accent)).frame(width: x + k / 2, height: 4)
                Circle().fill(.white).shadow(color: .black.opacity(0.3), radius: 1, y: 0.5)
                    .frame(width: k, height: k).offset(x: x)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged {
                onChange(Double(min(max(($0.location.x - k / 2) / track, 0), 1)))
            })
        }
        .frame(height: 16)
    }
}
