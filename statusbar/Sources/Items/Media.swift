import AppKit

// --- media (Spotifast, polled) ----------------------------------------------
// Spotifast posts no distributed notification and MediaRemote is closed
// to third parties, so the pill asks its CLI. One call is ~10 ms and
// runs only while Spotifast does.
// ponytail: 2 s poll, a track change shows up to 2 s late; switch to a
// push source if Spotifast ever grows one

let spotifastBundleID = "rocks.spotifast.Spotifast"
let SPOTIFAST_CLI = "/Applications/Spotifast.app/Contents/MacOS/Spotifast"
let MEDIA_POLL: TimeInterval = 2

func spotifastRunning() -> Bool {
    !NSRunningApplication.runningApplications(withBundleIdentifier: spotifastBundleID).isEmpty
}

func setMedia(_ next: Media) {
    guard next != model.media else { return }
    model.media = next
    loadCover(next.art)
    repaint()
    tlog("media \(next.playing ? "play" : "pause") \(next.title)")
}

func updateMedia() {
    guard spotifastRunning() else { return setMedia(Media()) }
    DispatchQueue.global(qos: .utility).async {
        // state, title, artists, album, … tab-separated
        let f = shell(SPOTIFAST_CLI, ["now-playing", "--raw"])
            .trimmingCharacters(in: .newlines)
            .split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        // the CLI answers blank about once an hour while Spotifast is
        // fine; one bad poll kept blanking the pill for a cycle
        guard f.count >= 3 else { return }
        let next = Media(running: true, playing: f[0] == "playing",
                         title: f[2].isEmpty ? f[1] : "\(f[2]) — \(f[1])",
                         art: f.count > 9 ? f[9] : "", saved: f.count > 10 && !["", "no", "false"].contains(f[10]))
        DispatchQueue.main.async { setMedia(next) }
    }
}

func spotifast(_ command: String) {
    DispatchQueue.global(qos: .userInitiated).async {
        _ = shell(SPOTIFAST_CLI, [command])
        DispatchQueue.main.async { updateMedia() }
    }
}

// the cover, fetched once per track; the old one stays up until the new
// one lands, so a track change does not flash an empty square
// ponytail: the 640 px art scaled down to 20 pt; fine at one fetch a track
var coverImage: NSImage?
private var coverURL = ""

func loadCover(_ url: String) {
    guard url != coverURL else { return }
    coverURL = url
    guard let u = URL(string: url), !url.isEmpty else { coverImage = nil; return }
    URLSession.shared.dataTask(with: u) { data, _, _ in
        let img = data.flatMap(NSImage.init(data:))
        DispatchQueue.main.async {
            guard url == coverURL, let img else { return }
            coverImage = img
            repaint()
        }
    }.resume()
}
