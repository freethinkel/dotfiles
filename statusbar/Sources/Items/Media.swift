import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

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
        let next = f.count < 3 ? Media(running: true)
            : Media(running: true, playing: f[0] == "playing",
                    title: f[2].isEmpty ? f[1] : "\(f[2]) — \(f[1])")
        DispatchQueue.main.async { setMedia(next) }
    }
}

func spotifast(_ command: String) {
    DispatchQueue.global(qos: .userInitiated).async {
        _ = shell(SPOTIFAST_CLI, [command])
        DispatchQueue.main.async { updateMedia() }
    }
}
