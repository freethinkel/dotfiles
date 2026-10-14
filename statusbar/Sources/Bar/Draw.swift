import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

// --- view -----------------------------------------------------------------

// Text positioning, done properly.
//
// `NSString.size(withAttributes:)` returns the TYPOGRAPHIC box — advance
// width and line height — which is what you want to flow a paragraph and
// exactly wrong for centring one glyph in a pill. A glyph's ink does not
// fill its advance (Nerd Font icons carry lopsided side bearings), and a
// line box reserves descender room that digits never use. Measured on the
// live bar, that put the wifi glyph 4 px right of centre and every label
// about 1 px high.
//
// So: icons centre on their INK box, text centres on CAP HEIGHT. Cap
// height rather than ink for text because it does not move when the
// content changes — "28°C" and "8:05 PM" sit on the same baseline.
func inkBox(_ s: String, _ font: NSFont) -> CGRect {
    if s.hasPrefix("ts") { return CGRect(x: 0, y: 0, width: font.pointSize, height: font.pointSize) }
    if s.hasPrefix("key:") { return CGRect(origin: .zero, size: keyBadge(s, font).size) }
    if s.hasPrefix("donut:") { return CGRect(x: 0, y: 0, width: font.pointSize, height: font.pointSize) }
    if s.hasPrefix("agents:") {
        let m = agentMark(font)
        return CGRect(x: 0, y: 0, width: CGFloat(s.count - 7) * m.step - m.gap, height: font.pointSize)
    }
    if let img = sfSymbol(s, font) { return CGRect(origin: .zero, size: img.size) }
    let line = CTLineCreateWithAttributedString(
        NSAttributedString(string: s, attributes: [.font: font]))
    return CTLineGetImageBounds(line, nil) // baseline at y = 0
}

func advance(_ s: String, _ font: NSFont) -> CGFloat {
    let line = CTLineCreateWithAttributedString(
        NSAttributedString(string: s, attributes: [.font: font]))
    return CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
}

// draws with `origin` as the BASELINE origin, which is the only anchor
// that means the same thing for every string
func drawLine(_ s: String, _ font: NSFont, _ color: NSColor, baseline origin: CGPoint) {
    guard !s.isEmpty, let ctx = NSGraphicsContext.current?.cgContext else { return }
    let line = CTLineCreateWithAttributedString(NSAttributedString(
        string: s, attributes: [.font: font, .foregroundColor: color]))
    ctx.textPosition = origin
    CTLineDraw(line, ctx)
}

// one glyph, centred on its ink in both axes
// "sf:<name>" is an SF Symbol drawn at the font's point size and tinted
// like text; anything else is a font glyph
func sfSymbol(_ s: String, _ font: NSFont, _ color: NSColor? = nil) -> NSImage? {
    guard s.hasPrefix("sf:") else { return nil }
    // cached by name, size and tint; a theme switch only adds keys
    let key = "\(s)|\(font.pointSize)|\(color?.description ?? "")"
    if let img = symbolCache[key] { return img }
    let img = loadSymbol(s, font, color)
    symbolCache[key] = img
    return img
}

var symbolCache: [String: NSImage?] = [:]
func loadSymbol(_ s: String, _ font: NSFont, _ color: NSColor?) -> NSImage? {
    var config = NSImage.SymbolConfiguration(pointSize: font.pointSize, weight: .medium)
    if let color { config = config.applying(.init(paletteColors: [color])) }
    return NSImage(systemSymbolName: String(s.dropFirst(3)), accessibilityDescription: nil)?
        .withSymbolConfiguration(config)
}

// "key:<text>" is a keycap: a filled rounded plate, the text in the bar's background colour
func keyBadge(_ s: String, _ font: NSFont) -> (text: String, font: NSFont, size: NSSize) {
    // Heavy: knocked-out text reads a weight lighter than the bar's Bold
    let text = String(s.dropFirst(4)), f = nerdFont("Heavy", (font.pointSize * 0.62).rounded())
    return (text, f, NSSize(width: (advance(text, f) + 8).rounded(), height: font.pointSize + 1))
}

// "agents:<states>" is a row of status marks, one digit (AgentState) each
func agentMark(_ font: NSFont) -> (d: CGFloat, gap: CGFloat, step: CGFloat) {
    let d = (font.pointSize * 0.55).rounded(), gap: CGFloat = 5
    return (d, gap, d + gap)
}

// "donut:<0...1>" is a progress ring the size of a glyph
func drawIcon(_ s: String, _ font: NSFont, _ color: NSColor, centeredIn box: CGRect) {
    if s.hasPrefix("agents:") {
        let m = agentMark(font), lw: CGFloat = 1.5, r = m.d / 2 - lw / 2
        let marks = s.dropFirst(7)
        var x = box.midX - CGFloat(marks.count - 1) * m.step / 2
        for ch in marks {
            guard let st = ch.wholeNumberValue.flatMap({ AgentState(rawValue: $0) }) else { continue }
            let c = NSPoint(x: x.rounded(), y: box.midY.rounded())
            func circle(_ radius: CGFloat) -> NSBezierPath {
                let p = NSBezierPath(ovalIn: NSRect(x: c.x - radius, y: c.y - radius, width: radius * 2, height: radius * 2))
                p.lineWidth = lw
                return p
            }
            st.color.setStroke()
            st.color.setFill()
            switch st {
            case .idle: circle(r).stroke()
            case .done: circle(r + lw / 2).fill()
            case .working: // the right half filled, like a moon
                circle(r).stroke()
                let half = NSBezierPath()
                half.move(to: c)
                half.appendArc(withCenter: c, radius: r, startAngle: 90, endAngle: -90, clockwise: true)
                half.close()
                half.fill()
            case .blocked: // a dot inside a ring: the one that wants you
                circle(r).stroke()
                circle(max(1, r - lw - 1)).fill()
            }
            x += m.step
        }
        return
    }
    if s.hasPrefix("donut:"), let f = Double(s.dropFirst(6)) {
        let d = font.pointSize, lw = max(2, d / 6), r = (d - lw) / 2
        let c = NSPoint(x: box.midX.rounded(), y: box.midY.rounded())
        let track = NSBezierPath()
        track.appendArc(withCenter: c, radius: r, startAngle: 0, endAngle: 360)
        track.lineWidth = lw
        palette.label.withAlphaComponent(0.2).setStroke()
        track.stroke()
        let arc = NSBezierPath()
        arc.appendArc(withCenter: c, radius: r, startAngle: 90,
                      endAngle: 90 - 360 * CGFloat(min(max(f, 0), 1)), clockwise: true)
        arc.lineWidth = lw
        arc.lineCapStyle = .round
        color.setStroke()
        if f > 0 { arc.stroke() }
        return
    }
    if s.hasPrefix("key:") {
        let k = keyBadge(s, font)
        let r = NSRect(x: (box.midX - k.size.width / 2).rounded(), y: (box.midY - k.size.height / 2).rounded(),
                       width: k.size.width, height: k.size.height)
        color.setFill()
        NSBezierPath(roundedRect: r, xRadius: 3.5, yRadius: 3.5).fill()
        drawText(k.text, k.font, palette.barBG, centeredIn: r)
        return
    }
    // "ts" is the Tailscale mark: a 3x3 dot grid, the T lit; "ts:off" is all dim
    if s.hasPrefix("ts") {
        let step = font.pointSize * 0.34, r = font.pointSize * 0.12
        for row in -1...1 {
            for col in -1...1 {
                let lit = s == "ts" && (row == 0 || (row == -1 && col == 0))
                color.withAlphaComponent(lit ? 1 : 0.3).setFill()
                NSBezierPath(ovalIn: NSRect(x: box.midX.rounded() + CGFloat(col) * step - r,
                                            y: box.midY.rounded() + CGFloat(row) * step - r,
                                            width: r * 2, height: r * 2)).fill()
            }
        }
        return
    }
    if let img = sfSymbol(s, font, color) {
        img.draw(in: NSRect(x: (box.midX - img.size.width / 2).rounded(),
                            y: (box.midY - img.size.height / 2).rounded(),
                            width: img.size.width, height: img.size.height))
        return
    }
    let ink = inkBox(s, font)
    drawLine(s, font, color,
             baseline: CGPoint(x: box.midX - ink.midX, y: box.midY - ink.midY))
}

// a text run: advance-centred across, cap-height-centred down
func drawText(_ s: String, _ font: NSFont, _ color: NSColor, centeredIn box: CGRect) {
    drawLine(s, font, color,
             baseline: CGPoint(x: box.midX - advance(s, font) / 2,
                               y: box.midY - font.capHeight / 2))
}

func drawText(_ s: String, _ font: NSFont, _ color: NSColor, leftAt x: CGFloat, midY: CGFloat) {
    drawLine(s, font, color, baseline: CGPoint(x: x, y: midY - font.capHeight / 2))
}

// Icons come from the running app and are cached by name: a redraw must
// not walk the process list.
var iconCache: [String: NSImage] = [:]
func appIcon(_ name: String) -> NSImage? {
    if let cached = iconCache[name] { return cached }
    guard let icon = NSWorkspace.shared.runningApplications
        .first(where: { $0.localizedName == name })?.icon else { return nil }
    iconCache[name] = icon
    return icon
}
