import Foundation

struct StreakData: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var totalCompletions: Int
    var lastCompletionDate: Date?
    var completionDates: [Date] // All dates bed was made

    // New tracking fields for achievements
    var earlyCompletions: [Int: Int] // hour -> count (completions before that hour)
    var comebackCount: Int // Number of times user came back after losing a streak
    var lastLostStreak: Int // The streak count when last broken (for bounce back achievement)
    var completedWeekends: Int // Number of complete weekends (both Sat & Sun)
    var mondayCompletions: Int // Number of Monday completions
    var completedOnNewYear: Bool // Has completed on Jan 1st
    var lastWeekendSaturday: Date? // Track partial weekend progress

    init() {
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalCompletions = 0
        self.lastCompletionDate = nil
        self.completionDates = []
        self.earlyCompletions = [:]
        self.comebackCount = 0
        self.lastLostStreak = 0
        self.completedWeekends = 0
        self.mondayCompletions = 0
        self.completedOnNewYear = false
        self.lastWeekendSaturday = nil
    }

    mutating func recordCompletion() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let hour = calendar.component(.hour, from: now)

        if let lastDate = lastCompletionDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDifference = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDifference == 0 {
                // Already completed today, no change
                return
            } else if daysDifference == 1 {
                // Consecutive day, increment streak
                currentStreak += 1
            } else {
                // Streak broken, track for comeback achievements
                if currentStreak > 0 {
                    lastLostStreak = currentStreak
                    comebackCount += 1
                }
                currentStreak = 1
            }
        } else {
            // First ever completion
            currentStreak = 1
        }

        totalCompletions += 1
        lastCompletionDate = today
        completionDates.append(today)

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        // Track early completions
        trackEarlyCompletion(hour: hour)

        // Track day-of-week achievements
        trackDayOfWeek(date: today, calendar: calendar)

        // Track special dates
        trackSpecialDates(date: today, calendar: calendar)
    }

    private mutating func trackEarlyCompletion(hour: Int) {
        // Track completions before various hours (6 AM and 7 AM)
        let trackedHours = [6, 7]
        for trackedHour in trackedHours {
            if hour < trackedHour {
                earlyCompletions[trackedHour, default: 0] += 1
            }
        }
    }

    private mutating func trackDayOfWeek(date: Date, calendar: Calendar) {
        let weekday = calendar.component(.weekday, from: date)

        // Monday is weekday 2 in Calendar
        if weekday == 2 {
            mondayCompletions += 1
        }

        // Saturday is weekday 7, Sunday is weekday 1
        if weekday == 7 {
            // It's Saturday, track it
            lastWeekendSaturday = date
        } else if weekday == 1 {
            // It's Sunday, check if we completed Saturday too
            if let saturday = lastWeekendSaturday {
                let daysDiff = calendar.dateComponents([.day], from: saturday, to: date).day ?? 0
                if daysDiff == 1 {
                    // Completed both Saturday and Sunday consecutively
                    completedWeekends += 1
                }
            }
            lastWeekendSaturday = nil
        }
    }

    private mutating func trackSpecialDates(date: Date, calendar: Calendar) {
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        // New Year's Day
        if month == 1 && day == 1 {
            completedOnNewYear = true
        }
    }

    var hasCompletedToday: Bool {
        guard let lastDate = lastCompletionDate else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }

    func wasCompletedOn(date: Date) -> Bool {
        let calendar = Calendar.current
        return completionDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }

    func completionsInMonth(date: Date) -> [Date] {
        let calendar = Calendar.current
        return completionDates.filter {
            calendar.isDate($0, equalTo: date, toGranularity: .month)
        }
    }

    // Convert to AchievementStats for checking achievements
    func toAchievementStats() -> AchievementStats {
        AchievementStats(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalCompletions: totalCompletions,
            earlyCompletions: earlyCompletions,
            comebackCount: comebackCount,
            lastLostStreak: lastLostStreak,
            completedWeekends: completedWeekends,
            mondayCompletions: mondayCompletions,
            completedOnNewYear: completedOnNewYear
        )
    }
}
