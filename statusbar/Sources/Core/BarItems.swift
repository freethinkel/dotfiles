import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

// --- right cluster ---------------------------------------------------------
// An item is data. Layout, hit-testing and drawing are generic over the
// list, so adding a pill is one entry and one provider — no per-item
// geometry, no padding arithmetic, no width caches.

struct BarItem: Equatable {
    var icon = ""
    var label = ""
    // which palette colour, not a copy of it: read when drawing, so a
    // theme switch recolours every pill in the repaint it already does
    var iconColor: KeyPath<Palette, NSColor>?
    var drawing = true
    var badge = false // dot on the icon's top-right corner
    var badgeColor: KeyPath<Palette, NSColor> = \.red
    var stale = false // last good fetch is 2+ polls old: drawn muted
}

var rightItems: [String: BarItem] = [:]

func set(_ name: String, _ mutate: (inout BarItem) -> Void) {
    var item = rightItems[name] ?? BarItem()
    mutate(&item)
    guard item != rightItems[name] else { return } // no pixels owed
    let t0 = DispatchTime.now().uptimeNanoseconds
    rightItems[name] = item
    repaint()
    // an open popup shows the same state as its pill — the brightness
    // popup kept whatever value it was built with while the pill moved
    if openPopup == name { refreshPopup() }
    tlog(String(format: "item %@ %.2f ms", name, Double(DispatchTime.now().uptimeNanoseconds - t0) / 1_000_000))
}

// A failed fetch keeps the last value on the pill, dimmed once the last
// good one is two polls old: a stale number should not pass for a live one.
var lastFetch: [String: Date] = [:]
func fetchFailed(_ name: String, poll: TimeInterval) {
    let age = Date().timeIntervalSince(lastFetch[name] ?? .distantPast)
    tlog("\(name): fetch failed, last good \(Int(min(age, 1e9)))s ago")
    set(name) { $0.stale = age > 2 * poll }
}

func shell(_ launch: String, _ args: [String], stdin input: String? = nil) -> String {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: launch)
    p.arguments = args
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = FileHandle.nullDevice
    let inPipe = Pipe()
    if input != nil { p.standardInput = inPipe }
    guard (try? p.run()) != nil else { return "" }
    if let input { // ponytail: small inputs only — written whole before reading
        inPipe.fileHandleForWriting.write(input.data(using: .utf8)!)
        try? inPipe.fileHandleForWriting.close()
    }
    let out = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return String(data: out, encoding: .utf8) ?? ""
}
