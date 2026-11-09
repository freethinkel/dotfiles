import AppKit
import EventKit

// --- clock (no publisher: the one honest timer, aligned to the minute)
func updateClock() {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "dd MMM HH:mm"
    set("clock") { $0.icon = "sf:calendar"; $0.label = f.string(from: Date()) }
}

// --- calendar events (EventKit publishes EKEventStoreChanged; "now"
// moving past an event is the clock's minute tick)
let eventStore = EKEventStore()
var todayEvents: [EKEvent] = []

func updateEvents() {
    guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { return }
    let now = Date()
    let cal = Calendar.current
    let end = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) ?? now
    // all-day ones (birthdays, holidays) would keep the dot lit all day
    todayEvents = eventStore.events(matching: eventStore.predicateForEvents(withStart: now, end: end, calendars: nil))
        .filter { e in
            !e.isAllDay && e.status != .canceled && e.endDate > now
                && e.attendees?.first(where: \.isCurrentUser)?.participantStatus != .declined
        }
        .sorted { $0.startDate < $1.startDate }
    set("clock") { $0.badge = !todayEvents.isEmpty }
    if openPopup == "clock" { refreshPopup() }
}

// ponytail: a host list, add one when a call link opens Calendar instead
let MEETING_HOSTS = ["zoom.us", "meet.google.com", "teams.microsoft.com", "teams.live.com",
                     "telemost", "webex.com", "whereby.com", "meet.jit.si", "facetime.apple.com"]

func meetingLink(_ e: EKEvent) -> URL? {
    let text = [e.url?.absoluteString, e.location, e.notes].compactMap { $0 }.joined(separator: "\n")
    let links = (try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue))?
        .matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap(\.url) ?? []
    return links.first { u in MEETING_HOSTS.contains { u.host?.contains($0) == true } }
}


var calDay: Date? // the picked day, nil = today

func calendarRows() -> [PopupRow] {
    var rows: [PopupRow] = []
    let now = Date()
    var cal = Calendar(identifier: .gregorian)
    cal.firstWeekday = 2 // Monday, like the shell version
    cal.minimumDaysInFirstWeek = 4 // ISO week numbers
    let picked = cal.startOfDay(for: calDay ?? now)
    // the grid's own width: 8 columns, the font is mono and every cell is two glyphs.
    // Fixed so a long title or agenda never resizes the popup on a pick
    let width = 8 * (advance("00", nerdFont("Regular", 13)) + CELL_PAD)
    let title = DateFormatter()
    title.dateFormat = "MMMM yyyy"
    rows.append(PopupRow(text: title.string(from: picked).lowercased(), hero: true, pager: { step in
        calDay = cal.date(byAdding: .month, value: step, to: picked)
        refreshPopup()
    }, width: width))
    rows.append(PopupRow(cells: ["w", "mo", "tu", "we", "th", "fr", "sa", "su"], cellDim: Set(0..<8)))

    guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: picked)) else { return rows }
    // weekday index with Monday = 0
    let leading = (cal.component(.weekday, from: monthStart) + 5) % 7
    let gridStart = cal.date(byAdding: .day, value: -leading, to: monthStart)!
    let weeks = Int(ceil(Double(leading + cal.range(of: .day, in: .month, for: picked)!.count) / 7))
    let days = (0..<weeks * 7).map { cal.date(byAdding: .day, value: $0, to: gridStart)! }
    let gridEnd = cal.date(byAdding: .day, value: 1, to: days.last!)!

    let access = EKEventStore.authorizationStatus(for: .event) == .fullAccess
    let events = access ? eventStore.events(matching: eventStore.predicateForEvents(
        withStart: gridStart, end: gridEnd, calendars: nil)) : []
    func declined(_ e: EKEvent) -> Bool {
        e.status == .canceled || e.attendees?.first(where: \.isCurrentUser)?.participantStatus == .declined
    }
    func on(_ day: Date) -> [EKEvent] {
        let end = cal.date(byAdding: .day, value: 1, to: day)!
        return events.filter { $0.startDate < end && $0.endDate > day }
    }

    for w in 0..<weeks {
        let week = Array(days[w * 7..<w * 7 + 7])
        var dots: [[NSColor]] = [[]]
        for day in week {
            var colors: [NSColor] = []
            for e in on(day) where !declined(e) && !colors.contains(e.calendar.color) { colors.append(e.calendar.color) }
            dots.append(colors)
        }
        let inMonth = { (d: Date) in cal.isDate(d, equalTo: monthStart, toGranularity: .month) }
        rows.append(PopupRow(cells: ["\(cal.component(.weekOfYear, from: week[0]))"] + week.map { "\(cal.component(.day, from: $0))" },
                             cellDim: Set([0] + week.indices.filter { !inMonth(week[$0]) }.map { $0 + 1 }),
                             cellMark: week.firstIndex { cal.isDateInToday($0) }.map { $0 + 1 },
                             cellRing: week.firstIndex { $0 == picked && !cal.isDateInToday($0) }.map { $0 + 1 },
                             cellDots: dots,
                             onCell: { k in
                                 guard k > 0 else { return }
                                 calDay = week[k - 1]
                                 refreshPopup()
                             }))
    }

    // the picked day's agenda: a call opens its link, anything else opens Calendar
    rows.append(PopupRow(separator: true))
    let head = DateFormatter()
    head.dateFormat = "EEEE d MMMM"
    rows.append(PopupRow(text: cal.isDateInToday(picked) ? "today" : head.string(from: picked).lowercased(), header: true))
    let agenda = on(picked).sorted { ($0.isAllDay ? 0 : 1, $0.startDate) < ($1.isAllDay ? 0 : 1, $1.startDate) }
    if agenda.isEmpty { rows.append(PopupRow(text: access ? "no events" : "no calendar access", dim: true)) }
    let hm = DateFormatter()
    hm.dateFormat = "HH:mm"
    for e in agenda {
        let link = meetingLink(e)
        // ponytail: relative time only inside the hour, the clock covers the rest
        let mins = Int(ceil(e.startDate.timeIntervalSince(now) / 60))
        let when = e.isAllDay || e.endDate <= now ? nil
            : mins <= 0 ? "now" : mins <= 60 ? "in \(mins)m" : nil
        // "all day" is 7 wide; the font is mono, so padding lines the titles up
        let time = e.isAllDay ? "all day" : hm.string(from: e.startDate).padding(toLength: 7, withPad: " ", startingAt: 0)
        let detail = [when, link != nil && e.endDate > now ? "join" : nil].compactMap { $0 }.joined(separator: " · ")
        // the popup's width is the grid's: a long title is cut by the row, the time stays
        rows.append(PopupRow(text: "\(time) \(e.title ?? "")",
                             detail: detail,
                             dim: !e.isAllDay && e.endDate <= now,
                             highlight: when == "now",
                             action: {
                                 closePopup()
                                 NSWorkspace.shared.open(link ?? URL(fileURLWithPath: "/System/Applications/Calendar.app"))
                             },
                             bar: e.calendar.color,
                             strike: declined(e)))
    }
    return rows
}
