import AppKit

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
    rightItems[name] = item
    repaint()
    // an open popup shows the same state as its pill — a slider
    // popup kept whatever value it was built with while the pill moved
    if openPopup == name { refreshPopup() }
}

// A failed fetch keeps the last value on the pill, dimmed once the last
// good one is two polls old: a stale number should not pass for a live one.
var lastFetch: [String: Date] = [:]
func fetchFailed(_ name: String, poll: TimeInterval) {
    let age = Date().timeIntervalSince(lastFetch[name] ?? .distantPast)
    tlog("\(name): fetch failed, last good \(Int(min(age, 1e9)))s ago")
    set(name) { $0.stale = age > 2 * poll }
}

// A hung CLI (tailscale with its daemon wedged) would hold a worker thread
// forever, and the poll would stack another one every 15 s: past `timeout`
// it gets SIGTERM. nil waits for good, for prompts a person has to answer.
// ponytail: a child that ignores SIGTERM, or a grandchild holding the pipe, still hangs
func shell(_ launch: String, _ args: [String], timeout: TimeInterval? = 30) -> String {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: launch)
    p.arguments = args
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = FileHandle.nullDevice
    guard (try? p.run()) != nil else { return "" }
    let kill = DispatchWorkItem {
        guard p.isRunning else { return }
        tlog("shell: \(launch) \(args.first ?? "") timed out")
        p.terminate()
    }
    if let timeout { DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: kill) }
    let out = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    kill.cancel()
    return String(data: out, encoding: .utf8) ?? ""
}
