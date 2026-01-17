import Foundation

/// Helper for day-of-week scheduling
enum DaySchedule {
    // MARK: - Presets

    /// All 7 days (Sunday through Saturday)
    static let allDays: Set<Int> = Set(1...7)

    /// Monday through Friday (2-6 in Calendar.weekday)
    static let weekdays: Set<Int> = Set(2...6)

    /// Saturday and Sunday (1 and 7 in Calendar.weekday)
    static let weekends: Set<Int> = [1, 7]

    // MARK: - Day Names

    /// Short day names for display (S, M, T, W, T, F, S)
    static let shortDayNames: [(day: Int, name: String)] = [
        (1, "S"),  // Sunday
        (2, "M"),  // Monday
        (3, "T"),  // Tuesday
        (4, "W"),  // Wednesday
        (5, "T"),  // Thursday
        (6, "F"),  // Friday
        (7, "S")   // Saturday
    ]

    /// Full day names
    static let fullDayNames: [Int: String] = [
        1: "Sunday",
        2: "Monday",
        3: "Tuesday",
        4: "Wednesday",
        5: "Thursday",
        6: "Friday",
        7: "Saturday"
    ]

    /// Abbreviated day names (Sun, Mon, etc.)
    static let abbreviatedDayNames: [Int: String] = [
        1: "Sun",
        2: "Mon",
        3: "Tue",
        4: "Wed",
        5: "Thu",
        6: "Fri",
        7: "Sat"
    ]

    // MARK: - Helpers

    /// Check if a habit is active on a given date
    static func isActiveOn(date: Date, activeDays: Set<Int>) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return activeDays.contains(weekday)
    }

    /// Check if a habit is active today
    static func isActiveToday(activeDays: Set<Int>) -> Bool {
        isActiveOn(date: Date(), activeDays: activeDays)
    }

    /// Get display string for a set of active days
    static func displayString(for activeDays: Set<Int>) -> String {
        // Check for presets first
        if activeDays == allDays {
            return "Every day"
        }
        if activeDays == weekdays {
            return "Weekdays"
        }
        if activeDays == weekends {
            return "Weekends"
        }

        // For custom combinations, show abbreviated day names
        let sortedDays = activeDays.sorted()
        let dayNames = sortedDays.compactMap { abbreviatedDayNames[$0] }
        return dayNames.joined(separator: ", ")
    }

    /// Get a short display string (for compact UIs)
    static func shortDisplayString(for activeDays: Set<Int>) -> String {
        if activeDays == allDays {
            return "Every day"
        }
        if activeDays == weekdays {
            return "Weekdays"
        }
        if activeDays == weekends {
            return "Weekends"
        }

        // For custom, just show count
        return "\(activeDays.count) days"
    }
}
