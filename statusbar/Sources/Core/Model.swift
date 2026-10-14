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
    var apps: [String: [BarWin]] = [:] // ws -> one entry per window, OmniWM-bar style
    var occupied: Set<String> = []
    // floating windows stay off the chips. Only the windows QUERY says
    // which are floating; the workspace-bar stream does not, so the
    // snapshot keeps the set and the stream filters by it.
    var floating: Set<String> = []
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

// SLOW path: who lives where. Three CLI calls — and it runs only when a
// window is created or destroyed, never on a workspace switch.
//
// It is computed OFF the main queue and applied on it. Measured the hard
// way: with the CLI calls inline on main, one contended rebuild blocked
// the render path for 7.6 seconds and every switch queued behind it. The
// architecture only pays off if subprocess work never sits on the path a
// frame has to travel.
struct Snapshot {
    var perMonitor: [String: (workspaces: [String], visible: String)] = [:]
    var apps: [String: [BarWin]] = [:]
    var occupied: Set<String> = []
    var floating: Set<String> = []
    var focused = ""
}

let rebuildQueue = DispatchQueue(label: "com.freethinkel.statusbar.rebuild")

func fetchSnapshot() -> Snapshot { omniwmSnapshot() }

// Two omniwmctl queries: workspaces arrive with their display and visibility in one query, and
// the windows query brings the app names the sole-app chips need. The
// snapshot also carries focus; the watch stream below covers the fast path.
func omniwmSnapshot() -> Snapshot {
    var s = Snapshot()
    var sets: [String: [String]] = [:]
    var visible: [String: String] = [:]
    if let list = omniQuery("workspaces",
                            ["--fields", "raw-name,display"])?["workspaces"]
        as? [[String: Any]] {
        for w in list {
            guard let name = w["rawName"] as? String,
                  let monitor = (w["display"] as? [String: Any])?["id"] as? String else { continue }
            sets[monitor, default: []].append(name)
        }
    }
    // visible/focused come from the DISPLAYS query: the workspaces
    // query's isVisible/isFocused go dark on EMPTY workspaces (the
    // same trap every workspace script hits), and the pill for a focused empty 8/9
    // never lit up
    if let displays = omniQuery("displays", [])?["displays"] as? [[String: Any]] {
        for d in displays {
            guard let id = d["id"] as? String,
                  let active = (d["activeWorkspace"] as? [String: Any])?["rawName"] as? String
            else { continue }
            visible[id] = active
            if (d["isCurrent"] as? Bool) == true { s.focused = active }
        }
    }
    for id in surfaces.map({ $0.monitorID }) {
        s.perMonitor[id] = (sets[id] ?? [], visible[id] ?? "")
    }

    if let list = omniQuery("windows", ["--fields", "id,workspace,app,mode,is-focused"])?["windows"]
        as? [[String: Any]] {
        for w in list {
            guard let ws = (w["workspace"] as? [String: Any])?["rawName"] as? String,
                  let app = (w["app"] as? [String: Any])?["name"] as? String,
                  let id = w["id"] as? String else { continue }
            guard (w["mode"] as? String) != "floating" else { s.floating.insert(id); continue }
            s.occupied.insert(ws)
            s.apps[ws, default: []].append(BarWin(app: app, id: id, focused: (w["isFocused"] as? Bool) == true))
        }
    }
    return s
}

// Reports whether anything actually moved. A workspace switch produces
// window moves too, and those snapshots come back identical — saying so
// keeps the repaint (and the log line) for the times something changed.
@discardableResult
func apply(_ s: Snapshot) -> Bool {
    var changed = false
    for surface in surfaces {
        guard let part = s.perMonitor[surface.monitorID] else { continue }
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
    model.floating = s.floating
    if model.occupied != s.occupied { model.occupied = s.occupied; changed = true }
    if model.apps != s.apps { model.apps = s.apps; changed = true }
    if !s.focused.isEmpty, model.focused != s.focused {
        tlog("focused \(s.focused) (snapshot)")
        model.focused = s.focused
        changed = true
    }
    return changed
}


// FAST path: a workspace switch changes focus and nothing else. No CLI,
// no IPC, no shell — every surface already knows the rest, and the one
// that owns the workspace also now shows it.
func setFocused(_ ws: String) {
    model.focused = ws
    for surface in surfaces where surface.mine.contains(ws) { surface.visible = ws }
}
