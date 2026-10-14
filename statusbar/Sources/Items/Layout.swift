import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

// --- keyboard layout (TIS publishes a distributed notification) ----------

func inputSourceProp<T>(_ src: TISInputSource, _ key: CFString) -> T? {
    guard let ptr = TISGetInputSourceProperty(src, key) else { return nil }
    return Unmanaged<AnyObject>.fromOpaque(ptr).takeUnretainedValue() as? T
}

// "EN", "RU": the source's first language, falling back to its name
func layoutShort(_ src: TISInputSource) -> String {
    let langs: [String] = inputSourceProp(src, kTISPropertyInputSourceLanguages) ?? []
    let name: String = inputSourceProp(src, kTISPropertyLocalizedName) ?? "?"
    return (langs.first ?? name).prefix(2).uppercased()
}

func updateLayout() {
    let src = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
    set("layout") { $0.icon = "key:\(layoutShort(src))"; $0.iconColor = nil; $0.label = "" }
}

func layoutRows() -> [PopupRow] {
    let filter = [kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource,
                  kTISPropertyInputSourceIsSelectCapable: true] as CFDictionary
    let sources = (TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource]) ?? []
    let current: String? = inputSourceProp(TISCopyCurrentKeyboardInputSource().takeRetainedValue(),
                                           kTISPropertyInputSourceID)
    var rows = [PopupRow(text: "keyboard", hero: true)]
    for src in sources {
        let id: String? = inputSourceProp(src, kTISPropertyInputSourceID)
        let name: String = inputSourceProp(src, kTISPropertyLocalizedName) ?? "?"
        rows.append(PopupRow(text: name, detail: layoutShort(src), highlight: id == current, action: {
            TISSelectInputSource(src)
            closePopup()
        }))
    }
    rows.append(PopupRow(text: "keyboard settings…", dim: true, action: {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension")!)
        closePopup()
    }))
    return rows
}
