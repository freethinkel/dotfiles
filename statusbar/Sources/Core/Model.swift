import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

// --- model ----------------------------------------------------------------

// Shared across every display: which workspace has focus, what the front
// app is, which workspaces hold what. Anything that differs per screen —
// the workspace set, the visible one, the notch — belongs to the surface.
// a window as the chips see it: whose icon, how to focus it, whether it has focus
struct BarWin: Equatable {
    var app: String
    var id: String
    var focused = false
}

final class Model {
    var focused = "" // globally focused workspace
    var apps: [String: [BarWin]] = [:] // ws -> one entry per window, left to right as on the strip
    var frontApp = ""
    var media = Media()
}

struct Media: Equatable {
    var running = false
    var playing = false
    var title = ""
}

let model = Model()
var palette = loadPalette()

// One line of nori's stream, which is `query spaces`: every Space with its
// display, whether it is focused or visible, its strip left to right
// (floating windows already left out) and the window that has focus there.
// Keyed by display UUID, or "Main" when displays share their Spaces.
struct Snapshot {
    var perMonitor: [String: (workspaces: [String], visible: String)] = [:]
    var apps: [String: [BarWin]] = [:]
    var focused = ""
}

func snapshot(fromNori line: Data) -> Snapshot? {
    guard let spaces = try? JSONSerialization.jsonObject(with: line) as? [[String: Any]] else { return nil }
    var s = Snapshot()
    for space in spaces {
        // fullscreen Spaces have no Desktop number, nothing to show or focus
        guard let number = space["number"] as? Int, let display = space["display"] as? String else { continue }
        let ws = "\(number)"
        s.perMonitor[display, default: ([], "")].workspaces.append(ws)
        if space["isVisible"] as? Bool == true { s.perMonitor[display]?.visible = ws }
        if space["isFocused"] as? Bool == true { s.focused = ws }
        var names: [Int: String] = [:]
        for app in space["apps"] as? [[String: Any]] ?? [] {
            for id in app["windows"] as? [Int] ?? [] { names[id] = app["name"] as? String }
        }
        let focusedWin = space["focusedWindow"] as? Int
        for id in space["columns"] as? [Int] ?? [] {
            guard let app = names[id], !app.hasPrefix("statusbar") else { continue }
            s.apps[ws, default: []].append(BarWin(app: app, id: "\(id)", focused: id == focusedWin))
        }
    }
    return s
}

// nori gone: no Spaces to show rather than its last word
func clearSpaces() {
    for surface in surfaces {
        surface.workspaces = []
        surface.mine = []
        surface.visible = ""
    }
    model.apps = [:]
    model.focused = ""
}

// Reports whether anything actually moved. A workspace switch produces
// window moves too, and those snapshots come back identical — saying so
// keeps the repaint (and the log line) for the times something changed.
@discardableResult
func apply(_ s: Snapshot) -> Bool {
    var changed = false
    for surface in surfaces {
        guard let part = s.perMonitor[surface.monitorID] ?? s.perMonitor["Main"] else { continue }
        if !part.workspaces.isEmpty, surface.workspaces != part.workspaces {
            surface.workspaces = part.workspaces
            surface.mine = Set(part.workspaces)
            changed = true
        }
        if !part.visible.isEmpty, surface.visible != part.visible {
            surface.visible = part.visible
            changed = true
        }
    }
    if model.apps != s.apps { model.apps = s.apps; changed = true }
    if !s.focused.isEmpty, model.focused != s.focused {
        tlog("focused \(s.focused) (snapshot)")
        model.focused = s.focused
        changed = true
    }
    return changed
}

