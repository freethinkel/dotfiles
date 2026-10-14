import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

// --- battery (IOPS publishes, capacity ticks included)
var battery = (pct: 0, charging: false, minutes: -1)

func batteryRows() -> [PopupRow] {
    let b = battery
    let time = b.minutes > 0 ? "\(b.minutes / 60):\(String(format: "%02d", b.minutes % 60))" : "—"
    return [
        PopupRow(text: "battery", hero: true),
        PopupRow(text: "\(b.pct)%", detail: b.charging ? (b.pct >= 100 ? "charged" : "charging") : "on battery", dim: true),
        PopupRow(text: b.charging ? "until full" : "time left", detail: b.pct >= 100 && b.charging ? "—" : time, dim: true),
        PopupRow(separator: true),
        PopupRow(text: "battery settings…", dim: true, action: {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Battery-Settings.extension")!)
            closePopup()
        }),
    ]
}

func updateBattery() {
    guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
          let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef]
    else { return }
    for source in list {
        guard let d = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any],
              let cur = d[kIOPSCurrentCapacityKey] as? Int else { continue }
        let max = d[kIOPSMaxCapacityKey] as? Int ?? 100
        let pct = max > 0 ? Int((Double(cur) / Double(max) * 100).rounded()) : cur
        let charging = (d[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
        // same thresholds and glyphs the bar already uses
        var icon = "sf:battery.0percent", color: KeyPath<Palette, NSColor> = \.red
        switch pct {
        case 90...: icon = "sf:battery.100percent"; color = \.green
        case 60..<90: icon = "sf:battery.75percent"; color = \.label
        case 30..<60: icon = "sf:battery.50percent"; color = \.label
        case 10..<30: icon = "sf:battery.25percent"; color = \.yellow
        default: break
        }
        if charging { icon = "sf:battery.100percent.bolt"; color = \.green }
        // minutes; IOPS reports -1 while it is still estimating
        let toEmpty = d[kIOPSTimeToEmptyKey] as? Int ?? -1, toFull = d[kIOPSTimeToFullChargeKey] as? Int ?? -1
        battery = (pct, charging, charging ? toFull : toEmpty)
        if openPopup == "battery" { refreshPopup() }
        set("battery") { $0.icon = icon; $0.iconColor = color; $0.label = charging && pct >= 100 ? "" : "\(pct)%" }
        return
    }
}
