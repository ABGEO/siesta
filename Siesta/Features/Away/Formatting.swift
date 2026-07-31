import Foundation

enum Away {

    /// Human-friendly duration, e.g. "1 hour", "90 min" -> "1h 30m", "30 min".
    static func durationLabel(_ interval: TimeInterval) -> String {
        let totalMinutes = max(0, Int(interval.rounded()) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        switch (hours, minutes) {
        case (0, _): return String(localized: "\(minutes) min")
        case (_, 0): return hours == 1 ? String(localized: "1 hour") : String(localized: "\(hours) hours")
        default: return String(localized: "\(hours)h \(minutes)m")
        }
    }

    /// Countdown string. Shows H:MM:SS past an hour, otherwise MM:SS.
    static func remaining(until end: Date, now: Date) -> String {
        let totalSeconds = max(0, Int(end.timeIntervalSince(now)))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%02d:%02d", minutes, seconds)
    }

    /// Short wall-clock time, e.g. "3:00 PM".
    static func clockTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    /// Default "until tomorrow" target: 9:00 AM the next day.
    static func untilTomorrow(from now: Date = Date()) -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now

        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }
}
