import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

// --- activity: the cpu pill stays a quiet glyph and only speaks up when
// the machine is struggling — cpu busy over the last poll, memory
// pressure (critical only, red without a word), thermal throttling. Click still opens btop for the culprit.
let hostPort = mach_host_self()
var lastTicks: host_cpu_load_info?

func cpuBusy() -> Double? { // share of ticks since the previous call, nil on the first
    var info = host_cpu_load_info()
    var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
    let kr = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { host_statistics(hostPort, HOST_CPU_LOAD_INFO, $0, &count) }
    }
    guard kr == KERN_SUCCESS else { return nil }
    defer { lastTicks = info }
    guard let prev = lastTicks else { return nil }
    let t = info.cpu_ticks, p = prev.cpu_ticks // user, system, idle, nice
    let busy = Double(t.0 &- p.0) + Double(t.1 &- p.1) + Double(t.3 &- p.3)
    let total = busy + Double(t.2 &- p.2)
    return total > 0 ? busy / total : nil
}

func updateActivity() {
    var level: Int32 = 1, size = MemoryLayout<Int32>.size // 1 normal, 2 warn, 4 critical
    sysctlbyname("kern.memorystatus_vm_pressure_level", &level, &size, nil, 0)
    let thermal = ProcessInfo.processInfo.thermalState
    var flags: [String] = [], color: KeyPath<Palette, NSColor> = \.accent
    if let cpu = cpuBusy(), cpu >= ACTIVITY_CPU_HOT { flags.append("\(Int(cpu * 100))%"); color = \.yellow }
    if thermal.rawValue >= ProcessInfo.ThermalState.serious.rawValue { flags.append("hot"); color = \.yellow }
    if level >= 4 || thermal == .critical { color = \.red }
    set("activity") { $0.icon = "sf:cpu"; $0.iconColor = color; $0.label = flags.joined(separator: " ") }
}
