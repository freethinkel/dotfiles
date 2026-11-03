import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

// --- nori -------------------------------------------------------------------
// The bar talks to nori's control socket itself, no CLI in between: one
// request per connection, the arguments joined by tabs, one line. After
// "subscribe" the connection stays open and nori writes the whole
// `query spaces` array as one line, at once and on every change, the target
// of a Space switch included before Dock's slide starts (nori README, "CLI").

let noriSocket = "/tmp/nori-ctl_\(NSUserName()).socket"

func noriConnect(_ args: [String]) -> Int32? {
    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    guard fd >= 0 else { return nil }
    var addr = sockaddr_un()
    addr.sun_family = sa_family_t(AF_UNIX)
    _ = noriSocket.withCString { strncpy(&addr.sun_path.0, $0, 103) }
    let ok = withUnsafePointer(to: &addr) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) }
    } == 0
    let line = args.joined(separator: "\t") + "\n"
    guard ok, line.utf8CString.withUnsafeBytes({ write(fd, $0.baseAddress, $0.count - 1) }) == line.utf8.count else {
        close(fd)
        return nil
    }
    return fd
}

// click-to-jump, without the slide: the click already says where to go.
// The reply (empty, or "error: …") is not waited for.
func noriAction(_ args: [String]) {
    if let fd = noriConnect(args) { close(fd) }
}
func focusWindow(_ id: String) { noriAction(["focus", "window", id, "--instant"]) }
func focusWorkspace(_ ws: String) { noriAction(["focus", "space", ws, "--instant"]) }

// The last line nori sent, kept so a display change can re-apply it.
var noriState = Snapshot()
var noriStream: DispatchSourceRead?

// ponytail: nori not running = a connect() every 2 s; watch for its launch if that ever shows up
func startNoriStream() {
    guard noriStream == nil else { return }
    guard let fd = noriConnect(["subscribe"]) else {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { startNoriStream() }
        return
    }
    tlog("nori: subscribed")
    var buffer = Data()
    var chunk = [UInt8](repeating: 0, count: 65536)
    let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: .main)
    source.setEventHandler {
        let n = read(fd, &chunk, chunk.count)
        guard n > 0 else { return source.cancel() } // nori quit
        buffer.append(contentsOf: chunk[..<n])
        // only the newest complete line matters, a burst applies once
        guard let nl = buffer.lastIndex(of: 0x0A) else { return }
        let lines = buffer[..<nl]
        buffer = Data(buffer[buffer.index(after: nl)...])
        let start = lines.lastIndex(of: 0x0A).map { lines.index(after: $0) } ?? lines.startIndex
        guard let s = snapshot(fromNori: Data(lines[start...])) else { return }
        let t0 = DispatchTime.now().uptimeNanoseconds
        noriState = s
        guard apply(s) else { return }
        repaint()
        tlog(String(format: "nori %@ %.2f ms", model.focused,
                    Double(DispatchTime.now().uptimeNanoseconds - t0) / 1_000_000))
    }
    source.setCancelHandler {
        close(fd)
        noriStream = nil
        tlog("nori: stream closed")
        noriState = Snapshot()
        clearSpaces()
        repaint()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { startNoriStream() }
    }
    noriStream = source
    source.resume()
}

let cid = SLSMainConnectionID()
// move and resize only fire for SUBSCRIBED windows, and going fullscreen
// is a resize — so the subscription set is kept equal to every normal
// window, refreshed whenever one is created or destroyed (borders.swift's
// recipe, and its reason).
var subscribed: Set<UInt32> = []
func rebuildSubscriptions() {
    guard let list = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]]
    else { return }
    var wids: [UInt32] = []
    for w in list where (w[kCGWindowLayer as String] as? Int) == 0 {
        if let n = w[kCGWindowNumber as String] as? Int { wids.append(UInt32(n)) }
    }
    let set = Set(wids)
    guard set != subscribed, !wids.isEmpty else { return }
    subscribed = set
    _ = wids.withUnsafeBufferPointer {
        SLSRequestNotificationsForWindows(cid, $0.baseAddress!, Int32(wids.count))
    }
}
