import ApplicationServices
import AppKit
import Carbon
import CoreAudio
import CoreLocation
import EventKit
import IOKit.ps
import UniformTypeIdentifiers

// --- location (one coordinate, for the weather) ---------------------------
// wttr.in's IP geolocation lands wherever the VPN exit node is, so the
// weather asks CoreLocation where the machine really is.
//
// TCC judges the RESPONSIBLE process, so only the launchd-started bar may
// prompt and running it by hand stays quiet.
final class LocationGate: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var managed: Bool { ProcessInfo.processInfo.environment["STATUSBAR_MANAGED"] != nil }

    func start() {
        manager.delegate = self
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorized:
            manager.requestLocation()
        case .denied, .restricted:
            tlog("location: denied — weather falls back to the timezone city")
        default:
            guard managed else {
                tlog("location: not launchd-managed, so not prompting")
                return
            }
            manager.requestWhenInUseAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        tlog("location: authorization now \(m.authorizationStatus.rawValue)")
        refresh()
    }

    // weather follows the machine, not the exit node; without a grant it
    // falls back to wttr.in's IP guess
    func refresh() {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorized: manager.requestLocation()
        default: updateWeather()
        }
    }

    func locationManager(_ m: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let c = locations.last?.coordinate else { return }
        weatherCoord = c
        updateWeather()
    }

    func locationManager(_ m: CLLocationManager, didFailWithError error: Error) {
        tlog("location: \(error.localizedDescription)")
        updateWeather() // last known coordinate, or the IP guess
    }
}
let locationGate = LocationGate()


// --- weather (no publisher; wttr.in, refreshed on a long timer)
// One j1 fetch feeds both the pill and its popup — weather.sh does the
// same, via a cache file it writes atomically because a click can read it
// mid-write. In one process the struct IS the cache and that race cannot
// be expressed.

struct Weather {
    var symbol = "", temp = "", desc = "", feels = ""
    var wind = "", humidity = "", pressure = "", visibility = "", uv = "", rain = ""
    var sunrise = "", sunset = "", moon = "", location = ""
    var fetched = Date()
    var hours: [(time: String, symbol: String, temp: String, rain: Int)] = []
    var days: [(name: String, symbol: String, low: String, high: String, rain: Int, wind: String, uv: String)] = []
}

func uvLevel(_ uv: String) -> String {
    guard let n = Int(uv) else { return uv }
    let level = n <= 2 ? "low" : n <= 5 ? "moderate" : n <= 7 ? "high" : n <= 10 ? "very high" : "extreme"
    return "\(n) \(level)"
}

var weather: Weather?

// WWO condition code -> SF Symbol, night-aware for the clear/partly pair
func weatherSymbol(_ code: Int, night: Bool) -> String {
    switch code {
    case 113: return night ? "sf:moon.stars.fill" : "sf:sun.max.fill"
    case 116: return night ? "sf:cloud.moon.fill" : "sf:cloud.sun.fill"
    case 119, 122: return "sf:cloud.fill"
    case 143, 248, 260: return "sf:cloud.fog.fill"
    case 176, 263, 266, 293, 296, 353: return "sf:cloud.drizzle.fill"
    case 299, 302, 305, 308, 356, 359: return "sf:cloud.rain.fill"
    case 200, 386, 389, 392, 395: return "sf:cloud.bolt.rain.fill"
    case 179, 182, 185, 227, 230, 281, 284, 311...338, 350, 362...368, 374...377: return "sf:cloud.snow.fill"
    default: return "sf:thermometer.medium"
    }
}

func moonEmoji(_ phase: String) -> String {
    switch phase {
    case "New Moon": return "🌑"
    case "Waxing Crescent": return "🌒"
    case "First Quarter": return "🌓"
    case "Waxing Gibbous": return "🌔"
    case "Full Moon": return "🌕"
    case "Waning Gibbous": return "🌖"
    case "Last Quarter", "Third Quarter": return "🌗"
    case "Waning Crescent": return "🌘"
    default: return "🌙"
    }
}

// wttr's "06:45 AM" -> minutes since midnight
func clockMinutes(_ s: String) -> Int? {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "hh:mm a"
    guard let d = f.date(from: s) else { return nil }
    let c = Calendar.current.dateComponents([.hour, .minute], from: d)
    return (c.hour ?? 0) * 60 + (c.minute ?? 0)
}

var weatherCoord: CLLocationCoordinate2D?

func updateWeather() {
    // no coordinate: the timezone's city beats an IP that sits behind the VPN
    // ponytail: a tz city is coarse (Europe/Moscow covers far more than Moscow)
    let place = weatherCoord.map { String(format: "%.3f,%.3f", $0.latitude, $0.longitude) }
        ?? TimeZone.current.identifier.split(separator: "/").last.map { String($0).replacingOccurrences(of: "_", with: "+") }
        ?? ""
    guard let url = URL(string: "https://wttr.in/\(place)?format=j1") else { return }
    var request = URLRequest(url: url)
    request.timeoutInterval = 15
    URLSession.shared.dataTask(with: request) { data, _, _ in
        guard let data,
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let current = (root["current_condition"] as? [[String: Any]])?.first,
              let days = root["weather"] as? [[String: Any]],
              let today = days.first
        else { return DispatchQueue.main.async { fetchFailed("weather", poll: WEATHER_POLL) } }

        func text(_ d: [String: Any], _ key: String) -> String { d[key] as? String ?? "" }
        func int(_ d: [String: Any], _ key: String) -> Int { Int(text(d, key)) ?? 0 }
        func nested(_ d: [String: Any], _ key: String) -> String {
            ((d[key] as? [[String: Any]])?.first?["value"] as? String) ?? ""
        }

        var w = Weather()
        // night by the real sun, not a fixed 7-20: a winter 17:00 is dark
        let astro = (today["astronomy"] as? [[String: Any]])?.first ?? [:]
        let sunrise = clockMinutes(text(astro, "sunrise")), sunset = clockMinutes(text(astro, "sunset"))
        func night(_ minute: Int) -> Bool {
            guard let sunrise, let sunset else { return minute < 7 * 60 || minute >= 20 * 60 }
            return minute < sunrise || minute >= sunset
        }
        func hhmm(_ minute: Int) -> String { String(format: "%02d:%02d", minute / 60, minute % 60) }
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let nowMin = (now.hour ?? 0) * 60 + (now.minute ?? 0)

        w.symbol = weatherSymbol(int(current, "weatherCode"), night: night(nowMin))
        w.temp = text(current, "temp_C")
        w.desc = nested(current, "weatherDesc").lowercased()
        w.feels = text(current, "FeelsLikeC")
        w.humidity = text(current, "humidity")
        w.pressure = text(current, "pressure")
        w.visibility = text(current, "visibility")
        w.uv = text(current, "uvIndex")
        if let sunrise, let sunset { w.sunrise = hhmm(sunrise); w.sunset = hhmm(sunset) }
        let phase = text(astro, "moon_phase")
        if !phase.isEmpty { w.moon = "\(moonEmoji(phase)) \(phase.lowercased())" }

        let arrows = ["↓", "↙", "←", "↖", "↑", "↗", "→", "↘"]
        func arrow(_ degrees: Int) -> String { arrows[((degrees + 180) / 45) % 8] }
        let speed = int(current, "windspeedKmph"), gust = int(current, "WindGustKmph")
        w.wind = "\(arrow(int(current, "winddirDegree"))) \(speed) km/h"
        if gust >= speed * 3 / 2, gust > speed + 10 { w.wind += " · gusts \(gust)" }

        // rain earns a row only with real signal: falling now, or likely today
        let precip = Double(text(current, "precipMM")) ?? 0
        let todayHours = (today["hourly"] as? [[String: Any]]) ?? []
        let chance = todayHours.map { int($0, "chanceofrain") }.max() ?? 0
        var rain: [String] = []
        if precip > 0 { rain.append("\(text(current, "precipMM")) mm now") }
        if chance >= 30 { rain.append("\(chance)% today") }
        w.rain = rain.joined(separator: " · ")

        // the next six 3-hour slots, today's remainder then tomorrow's start
        for (i, day) in days.prefix(2).enumerated() {
            for h in (day["hourly"] as? [[String: Any]]) ?? [] where w.hours.count < 6 {
                let minute = int(h, "time") / 100 * 60
                // today: the slot that holds now, and later ones
                guard i > 0 || minute + 180 > nowMin else { continue }
                w.hours.append((hhmm(minute), weatherSymbol(int(h, "weatherCode"), night: night(minute)),
                                text(h, "tempC"), int(h, "chanceofrain")))
            }
        }

        let iso = DateFormatter()
        iso.dateFormat = "yyyy-MM-dd"
        let short = DateFormatter()
        short.dateFormat = "EEE"
        for (i, day) in days.enumerated() {
            let hourly = (day["hourly"] as? [[String: Any]]) ?? []
            let noon = hourly.count > 4 ? hourly[4] : hourly.first ?? [:]
            let name = i == 0 ? "today"
                : iso.date(from: text(day, "date")).map { short.string(from: $0).lowercased() } ?? text(day, "date")
            w.days.append((name, weatherSymbol(int(noon, "weatherCode"), night: false),
                           text(day, "mintempC"), text(day, "maxtempC"),
                           hourly.map { int($0, "chanceofrain") }.max() ?? 0,
                           "\(hourly.map { int($0, "windspeedKmph") }.max() ?? 0) km/h",
                           text(day, "uvIndex")))
        }

        if let area = (root["nearest_area"] as? [[String: Any]])?.first {
            // wttr repeats the city as its region ("Porto, Porto"), so the
            // region is dropped whenever either name contains the other
            let city = nested(area, "areaName")
            let region = nested(area, "region")
            let country = nested(area, "country")
            var parts = [city]
            if !region.isEmpty,
               !city.lowercased().contains(region.lowercased()),
               !region.lowercased().contains(city.lowercased()) {
                parts.append(region)
            }
            if !country.isEmpty { parts.append(country) }
            w.location = parts.joined(separator: ", ")
        }

        DispatchQueue.main.async {
            weather = w
            lastFetch["weather"] = Date()
            set("weather") { $0.icon = w.symbol; $0.label = "\(w.temp)°"; $0.stale = false }
            if openPopup == "weather" { refreshPopup() }
        }
    }.resume()
}


func weatherRows() -> [PopupRow] {
    guard let w = weather else { return [] }
    func kv(_ k: String, _ v: String) -> PopupRow { PopupRow(cells: [k, v], cellDim: [0], labelCol: true) }
    // a label column, then one column per slot; cells under 10% rain read dim
    func head(_ label: String, _ cols: [String]) -> PopupRow {
        PopupRow(cells: [label] + cols, cellDim: Set(0...cols.count), labelCol: true)
    }
    func line(_ label: String, _ cols: [String], dim: [Bool] = []) -> PopupRow {
        PopupRow(cells: [label] + cols, cellDim: Set([0] + dim.indices.filter { dim[$0] }.map { $0 + 1 }), labelCol: true)
    }
    var rows: [PopupRow] = [PopupRow(icon: w.symbol, text: "\(w.temp)°C \(w.desc)", hero: true)]
    if w.feels != w.temp { rows.append(kv("feels", "\(w.feels)°C")) }
    rows.append(kv("wind", w.wind))
    rows.append(kv("humidity", "\(w.humidity)%"))
    if !w.pressure.isEmpty { rows.append(kv("pressure", "\(w.pressure) hPa")) }
    if !w.visibility.isEmpty { rows.append(kv("visibility", "\(w.visibility) km")) }
    if !w.uv.isEmpty { rows.append(kv("uv", uvLevel(w.uv))) }
    if !w.rain.isEmpty { rows.append(kv("rain", w.rain)) }
    if !w.sunrise.isEmpty { rows.append(kv("sun", "\(w.sunrise) → \(w.sunset)")) }
    if !w.moon.isEmpty { rows.append(kv("moon", w.moon)) }
    if !w.hours.isEmpty {
        rows.append(PopupRow(separator: true))
        rows.append(head("", w.hours.map(\.time)))
        rows.append(line("", w.hours.map(\.symbol)))
        rows.append(line("temp", w.hours.map { "\($0.temp)°" }))
        rows.append(line("rain", w.hours.map { "\($0.rain)%" }, dim: w.hours.map { $0.rain < 10 }))
    }
    if !w.days.isEmpty {
        rows.append(PopupRow(separator: true))
        rows.append(head("", w.days.map(\.name)))
        rows.append(line("", w.days.map(\.symbol)))
        rows.append(line("temp", w.days.map { "\($0.low)–\($0.high)°" }))
        rows.append(line("rain", w.days.map { "\($0.rain)%" }, dim: w.days.map { $0.rain < 10 }))
        rows.append(line("wind", w.days.map(\.wind)))
        rows.append(line("uv", w.days.map(\.uv)))
    }
    rows.append(PopupRow(separator: true))
    let at = DateFormatter()
    at.dateFormat = "HH:mm"
    rows.append(PopupRow(text: w.location.isEmpty ? "wttr.in" : w.location,
                         detail: "updated \(at.string(from: w.fetched))", dim: true))
    return rows
}
