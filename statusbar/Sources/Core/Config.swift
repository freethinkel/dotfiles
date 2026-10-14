import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

// --- config ---------------------------------------------------------------
// Tunables live here; everything else derives from them.

let FONT_FAMILY = "IoskeleyMonoNL Nerd Font Mono"

// geometry (pt)
let BAR_HEIGHT: CGFloat = 34
let PILL_HEIGHT: CGFloat = 26     // hit/draw box of every item
let PAD_LEFT: CGFloat = 10        // outer edge padding, both ends
let GAP: CGFloat = 14             // between the left-cluster groups
let ITEM_GAP: CGFloat = 2         // between right-cluster items
let ITEM_PAD: CGFloat = 10        // inside a right-cluster item, each side
let RADIUS: CGFloat = 4           // active-workspace / focus plates
let CHIP_BOX: CGFloat = 20        // workspace label box
let CHIP_PAD: CGFloat = 2
let CHIP_GAP: CGFloat = 4         // between workspace chips
let APP_ICON_SIZE: CGFloat = 20
let ICON_SIZE: CGFloat = 16
let ICON_GAP: CGFloat = 4         // icon to label, right-cluster items       // bar glyphs; "sf:" icons are SF Symbols at this point size
let APP_ICON_GAP: CGFloat = 2

// popups
let ROW_HEIGHT: CGFloat = 26
let POPUP_PAD: CGFloat = 8
let CELL_PAD: CGFloat = 14        // table cells: added to the widest cell of a column

// right cluster, screen order left to right
let DEFAULT_ORDER = ["claude", "weather", "home", "tailscale", "caffeinate", "theme", "more", "agents", "layout", "brightness", "volume", "battery", "clock", "activity"]

// Dragged order, kept in UserDefaults. Items added to DEFAULT_ORDER later
// slot in at their default index; ones removed from it drop out.
var rightOrder: [String] = {
    var order = (UserDefaults.standard.stringArray(forKey: "rightOrder") ?? [])
        .filter(DEFAULT_ORDER.contains)
    for (i, name) in DEFAULT_ORDER.enumerated() where !order.contains(name) {
        order.insert(name, at: min(i, order.count))
    }
    return order
}()
// whatever sits left of the "more" chevron hides behind it until clicked
var collapsed = true
var dragName: String? // the pill being dragged, if any
var collapsible: ArraySlice<String> { rightOrder.prefix { $0 != "more" } }

// above app windows, one below the native menu bar: with the menu bar on
// auto-hide it slides in OVER the bar when the pointer hits the top edge
let BAR_LEVEL = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue - 1)

// polling (s) — only for sources with no publisher
let WEATHER_POLL: TimeInterval = 1800
let TAILSCALE_POLL: TimeInterval = 15
let TAILSCALE_CLI = "/usr/local/bin/tailscale"
let CLAUDE_POLL: TimeInterval = 300
let HOME_POLL: TimeInterval = 15
let AGENTS_POLL: TimeInterval = 5
let ACTIVITY_POLL: TimeInterval = 60 // also the cpu averaging window
let ACTIVITY_CPU_HOT = 0.8
// no "switch": the only ones are the ACs' power switches under climate.*; add it back for smart plugs
let HOME_DOMAINS: Set<String> = ["climate", "light", "fan"]
