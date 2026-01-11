import Foundation

struct StreakData: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var totalCompletions: Int
    var lastCompletionDate: Date?
    var completionDates: [Date] // All dates bed was made

    init() {
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalCompletions = 0
        self.lastCompletionDate = nil
        self.completionDates = []
    }

    mutating func recordCompletion() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

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
                // Streak broken, start fresh
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
}
