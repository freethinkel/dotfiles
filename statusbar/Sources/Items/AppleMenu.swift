import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

// The system menu the hidden native menu bar used to carry. "Reload Bar" has no counterpart here on purpose: there
// is no config to re-read, the theme is watched, and a row that did
// nothing would be worse than a row that is absent.
func appleRows() -> [PopupRow] {
    func settings(_ pane: String) -> () -> Void {
        { NSWorkspace.shared.open(URL(string: pane)!); closePopup() }
    }
    func run(_ launch: String, _ args: [String]) -> () -> Void {
        {
            closePopup()
            DispatchQueue.global(qos: .userInitiated).async { _ = shell(launch, args) }
        }
    }
    func systemEvents(_ verb: String) -> () -> Void {
        run("/usr/bin/osascript", ["-e", "tell application \"System Events\" to \(verb)"])
    }
    return [
        PopupRow(text: "About This Mac", hero: true,
                 action: settings("x-apple.systempreferences:com.apple.SystemProfiler.AboutExtension")),
        PopupRow(text: "System Settings…", action: run("/usr/bin/open", ["-a", "System Settings"])),
        // pmset displaysleepnow only darkens the panel — whether that
        // locks depends on the screenLock delay, so it usually did not
        PopupRow(text: "Lock Screen",
                 action: systemEvents("keystroke \"q\" using {control down, command down}")),
        PopupRow(text: "Sleep", action: run("/usr/bin/pmset", ["sleepnow"])),
        PopupRow(text: "Restart…", action: systemEvents("restart")),
        PopupRow(text: "Shut Down…", action: systemEvents("shut down")),
    ]
}



// The focused app's menu bar, read over Accessibility and rendered
// INSIDE our popup: top level lists File/Edit/…, clicking drills into
// that menu's actual items, and clicking a leaf performs its AXPress —
// the command runs with no native menu ever appearing. A navigation
// stack lives for the popup's lifetime; "‹" walks back up.
var appMenuStack: [(title: String, element: AXUIElement)] = []

private func axChildren(_ element: AXUIElement) -> [AXUIElement] {
    var ref: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, "AXChildren" as CFString, &ref) == .success,
          let children = ref as? [AXUIElement] else { return [] }
    return children
}

private func axString(_ element: AXUIElement, _ attr: String) -> String {
    var ref: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attr as CFString, &ref) == .success else { return "" }
    return ref as? String ?? ""
}

// one menu's items as popup rows — shared by the app drill-down and the
// apple pill. A menu bar item wraps one AXMenu; the items live inside.
// AXEnabled is a lie for closed menus: apps validate items lazily when
// a menu OPENS, so unopened menus read mostly disabled (Arc's whole
// Tabs menu greyed out). Render all leaves live; a truly disabled
// item's AXPress just no-ops.
// Recent Items: AX exposes no menu-item images, but its entries are
// apps and documents whose icons Launch Services can resolve by name —
// the section headers ("Applications"/"Documents"/"Servers") say which
// strategy applies. Headers render dim, entries get real icons.
func recentItemIcon(_ title: String, section: String) -> NSImage? {
    if section == "Applications" {
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == title }),
           let icon = app.icon { return icon }
        if let path = NSWorkspace.shared.fullPath(forApplication: title) {
            return NSWorkspace.shared.icon(forFile: path)
        }
        return nil
    }
    if section == "Documents" {
        let ext = (title as NSString).pathExtension
        if !ext.isEmpty, let type = UTType(filenameExtension: ext) {
            return NSWorkspace.shared.icon(for: type)
        }
        return NSWorkspace.shared.icon(for: .data)
    }
    return nil
}

func rowsForMenu(_ element: AXUIElement, context: String = "",
                 collapseAlternates: Bool = false) -> [PopupRow] {
    let container = axChildren(element).first ?? element
    var rows: [PopupRow] = []
    var section = ""
    var prevTitle = ""
    let recents = context == "Recent Items"
    for item in axChildren(container) {
        let title = axString(item, "AXTitle")
        if title.isEmpty {
            if rows.last?.separator != true { rows.append(PopupRow(separator: true)) }
            prevTitle = ""
            continue
        }
        // the Apple menu carries hold-Option ALTERNATES ("Restart…" then
        // "Restart", "Force Quit…" then "Force Quit Arc") that the native
        // menu hides — AX enumerates them flat. An item whose title
        // extends its predecessor's (ellipsis stripped) is the alternate.
        if collapseAlternates, !prevTitle.isEmpty {
            let base = prevTitle.replacingOccurrences(of: "…", with: "")
            if title.hasPrefix(base) { continue }
        }
        prevTitle = title
        // Recent Items' own hold-Option alternates ("Show X in Finder")
        // carry a different title shape than the root menu's (English UI;
        // the pattern is locale-bound, worst case they reappear)
        if recents, title.hasPrefix("Show “"), title.hasSuffix("” in Finder") { continue }
        if recents, ["Applications", "Documents", "Servers"].contains(title) {
            section = title
            rows.append(PopupRow(text: title, dim: true))
            continue
        }
        if !axChildren(item).isEmpty {
            rows.append(PopupRow(icon: "›", text: title, action: {
                appMenuStack.append((title, item))
                refreshPopup()
            }))
        } else {
            let cmd = axString(item, "AXMenuItemCmdChar")
            rows.append(PopupRow(image: recents ? recentItemIcon(title, section: section) : nil,
                                 text: title, detail: cmd.isEmpty ? "" : "⌘\(cmd)", action: {
                closePopup()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    AXUIElementPerformAction(item, "AXPress" as CFString)
                }
            }))
        }
    }
    return rows
}

// the frontmost app's AX menu bar, resolved the popup-safe way
func frontAppAXMenuBar() -> AXUIElement? {
    guard !model.frontApp.isEmpty,
          let app = NSWorkspace.shared.runningApplications.first(where: {
              $0.localizedName == model.frontApp
                  && $0.processIdentifier != ProcessInfo.processInfo.processIdentifier
          })
    else { return nil }
    let ax = AXUIElementCreateApplication(app.processIdentifier)
    var ref: CFTypeRef?
    guard AXUIElementCopyAttributeValue(ax, "AXMenuBar" as CFString, &ref) == .success,
          let bar = ref, CFGetTypeID(bar) == AXUIElementGetTypeID() else { return nil }
    return (bar as! AXUIElement)
}

// The REAL Apple menu — child 0 of the front app's menu bar — with
// submenus drilled into behind a back row. Falls back to the hand-rolled
// rows when Accessibility is not granted or AX has nothing.
func appleMenuRows() -> [PopupRow] {
    guard AXIsProcessTrusted(),
          let menubar = frontAppAXMenuBar(),
          let apple = axChildren(menubar).first
    else { return appleRows() }
    if let top = appMenuStack.last {
        var rows = [PopupRow(icon: "‹", text: top.title, highlight: true, action: {
            appMenuStack.removeLast()
            refreshPopup()
        })]
        rows.append(contentsOf: rowsForMenu(top.element, context: top.title))
        return rows
    }
    let rows = rowsForMenu(apple, collapseAlternates: true)
    guard !rows.isEmpty else { return appleRows() }
    return rows
}
