import Foundation

struct StreakData: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var totalCompletions: Int
    var lastCompletionDate: Date?
    var completionDates: [Date]

    // Achievement tracking fields
    var earlyCompletions: [Int: Int]  // hour -> count (tracks which hours completions happen)
    var comebackCount: Int
    var lastLostStreak: Int
    var hasRebuiltAfterLoss: Bool
    var perfectMonthsCompleted: Int
    var completedOnNewYear: Bool
    var installDate: Date?
    var completedOnAnniversary: Bool

    // Track which months have been checked for perfection to avoid double-counting
    var checkedPerfectMonths: Set<String>

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
        self.checkedPerfectMonths = []
    }

    // Custom decoding to handle migration from older versions without checkedPerfectMonths
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentStreak = try container.decode(Int.self, forKey: .currentStreak)
        longestStreak = try container.decode(Int.self, forKey: .longestStreak)
        totalCompletions = try container.decode(Int.self, forKey: .totalCompletions)
        lastCompletionDate = try container.decodeIfPresent(Date.self, forKey: .lastCompletionDate)
        completionDates = try container.decode([Date].self, forKey: .completionDates)
        earlyCompletions = try container.decode([Int: Int].self, forKey: .earlyCompletions)
        comebackCount = try container.decode(Int.self, forKey: .comebackCount)
        lastLostStreak = try container.decode(Int.self, forKey: .lastLostStreak)
        hasRebuiltAfterLoss = try container.decode(Bool.self, forKey: .hasRebuiltAfterLoss)
        perfectMonthsCompleted = try container.decode(Int.self, forKey: .perfectMonthsCompleted)
        completedOnNewYear = try container.decode(Bool.self, forKey: .completedOnNewYear)
        installDate = try container.decodeIfPresent(Date.self, forKey: .installDate)
        completedOnAnniversary = try container.decode(Bool.self, forKey: .completedOnAnniversary)
        // Default to empty set for older versions without this field
        checkedPerfectMonths = try container.decodeIfPresent(Set<String>.self, forKey: .checkedPerfectMonths) ?? []
    }

    /// Records a completion for today.
    /// Thread-safe: Guards against duplicate completions on the same day.
    mutating func recordCompletion() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let hour = calendar.component(.hour, from: now)

        // Guard against duplicate completions on the same day (race condition protection)
        if let lastDate = lastCompletionDate {
            let lastDay = calendar.startOfDay(for: lastDate)

            // Already recorded today - no-op (prevents race conditions)
            if lastDay == today {
                return
            }

            let daysDifference = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDifference == 1 {
                // Yesterday was completed - continue streak
                currentStreak += 1

                // Check if we've rebuilt after a loss
                if lastLostStreak > 0 && !hasRebuiltAfterLoss {
                    hasRebuiltAfterLoss = true
                }
            } else {
                // Streak broken (missed a day or more)
                if currentStreak > 0 {
                    lastLostStreak = currentStreak
                    comebackCount += 1
                    hasRebuiltAfterLoss = false
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

        // Track special dates
        trackSpecialDates(date: today, calendar: calendar)

        // Check for perfect month
        checkPerfectMonth(date: today, calendar: calendar)
    }

    private mutating func trackEarlyCompletion(hour: Int) {
        // Track completions by the actual hour they occurred (0-23)
        // This enables achievements like "Early Riser" (before 6am), "Dawn Warrior" (before 5am), etc.
        earlyCompletions[hour, default: 0] += 1
    }

    /// Returns count of completions that occurred before a given hour
    func completionsBeforeHour(_ targetHour: Int) -> Int {
        earlyCompletions.filter { $0.key < targetHour }.values.reduce(0, +)
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
        // Check both:
        // 1. The previous month (in case we just started a new month)
        // 2. The current month if it just ended (last day of month)

        // Check the previous month
        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: date) {
            checkMonthForPerfection(monthDate: previousMonth, calendar: calendar)
        }

        // Check if today is the last day of the current month
        if let lastDayOfMonth = lastDayOfMonth(for: date, calendar: calendar),
           calendar.isDate(date, inSameDayAs: lastDayOfMonth) {
            checkMonthForPerfection(monthDate: date, calendar: calendar)
        }
    }

    /// Checks if a specific month was a perfect month (all days completed)
    private mutating func checkMonthForPerfection(monthDate: Date, calendar: Calendar) {
        let month = calendar.component(.month, from: monthDate)
        let year = calendar.component(.year, from: monthDate)
        let monthKey = "\(year)-\(month)"

        // Don't double-check months we've already verified
        guard !checkedPerfectMonths.contains(monthKey) else { return }

        // Don't check future months or the current month unless it's the last day
        let now = Date()
        let nowMonth = calendar.component(.month, from: now)
        let nowYear = calendar.component(.year, from: now)

        // If checking current month and it's not complete yet, skip
        if year == nowYear && month == nowMonth {
            guard let lastDay = lastDayOfMonth(for: monthDate, calendar: calendar),
                  calendar.isDate(now, inSameDayAs: lastDay) else {
                return
            }
        }

        // If checking a future month, skip
        if year > nowYear || (year == nowYear && month > nowMonth) {
            return
        }

        let daysInMonth = calendar.range(of: .day, in: .month, for: monthDate)?.count ?? 0
        let completionsInThisMonth = completionsInMonth(date: monthDate)

        // Check if all days were completed
        let uniqueDays = Set(completionsInThisMonth.map { calendar.component(.day, from: $0) })
        if uniqueDays.count >= daysInMonth {
            perfectMonthsCompleted += 1
            checkedPerfectMonths.insert(monthKey)
        } else {
            // Mark as checked even if not perfect (to avoid rechecking)
            checkedPerfectMonths.insert(monthKey)
        }
    }

    /// Returns the last day of the month for a given date
    private func lastDayOfMonth(for date: Date, calendar: Calendar) -> Date? {
        guard let range = calendar.range(of: .day, in: .month, for: date) else { return nil }
        var components = calendar.dateComponents([.year, .month], from: date)
        components.day = range.upperBound - 1
        return calendar.date(from: components)
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
