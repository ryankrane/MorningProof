import Foundation

struct StreakData: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var totalCompletions: Int
    var lastCompletionDate: Date?
    var completionDates: [Date]

    // Achievement tracking fields
    var earlyCompletions: [Int: Int]  // hour -> count
    var comebackCount: Int
    var lastLostStreak: Int
    var hasRebuiltAfterLoss: Bool
    var perfectMonthsCompleted: Int
    var completedOnNewYear: Bool
    var installDate: Date?
    var completedOnAnniversary: Bool

    init() {
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalCompletions = 0
        self.lastCompletionDate = nil
        self.completionDates = []
        self.earlyCompletions = [:]
        self.comebackCount = 0
        self.lastLostStreak = 0
        self.hasRebuiltAfterLoss = false
        self.perfectMonthsCompleted = 0
        self.completedOnNewYear = false
        self.installDate = Date()
        self.completedOnAnniversary = false
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
                return
            } else if daysDifference == 1 {
                currentStreak += 1

                // Check if we've rebuilt after a loss
                if lastLostStreak > 0 && !hasRebuiltAfterLoss {
                    hasRebuiltAfterLoss = true
                }
            } else {
                // Streak broken
                if currentStreak > 0 {
                    lastLostStreak = currentStreak
                    comebackCount += 1
                    hasRebuiltAfterLoss = false
                }
                currentStreak = 1
            }
        } else {
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

        // Track special dates
        trackSpecialDates(date: today, calendar: calendar)

        // Check for perfect month
        checkPerfectMonth(date: today, calendar: calendar)
    }

    private mutating func trackEarlyCompletion(hour: Int) {
        // Track completions before 7 AM
        if hour < 7 {
            earlyCompletions[7, default: 0] += 1
        }
    }

    private mutating func trackSpecialDates(date: Date, calendar: Calendar) {
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        // New Year's Day
        if month == 1 && day == 1 {
            completedOnNewYear = true
        }

        // Anniversary check
        if let install = installDate {
            let installMonth = calendar.component(.month, from: install)
            let installDay = calendar.component(.day, from: install)

            // Check if at least one year has passed
            if let yearsSinceInstall = calendar.dateComponents([.year], from: install, to: date).year,
               yearsSinceInstall >= 1,
               month == installMonth,
               day == installDay {
                completedOnAnniversary = true
            }
        }
    }

    private mutating func checkPerfectMonth(date: Date, calendar: Calendar) {
        // Get the previous month (since we just completed today)
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: date) else { return }

        let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth)?.count ?? 0
        let completionsInPreviousMonth = completionsInMonth(date: previousMonth)

        // If we completed every day of the previous month
        if completionsInPreviousMonth.count >= daysInPreviousMonth {
            // Verify it's actually consecutive days
            let uniqueDays = Set(completionsInPreviousMonth.map { calendar.component(.day, from: $0) })
            if uniqueDays.count >= daysInPreviousMonth {
                perfectMonthsCompleted += 1
            }
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
            hasRebuiltAfterLoss: hasRebuiltAfterLoss,
            perfectMonthsCompleted: perfectMonthsCompleted,
            completedOnNewYear: completedOnNewYear,
            installDate: installDate,
            completedOnAnniversary: completedOnAnniversary
        )
    }
}
