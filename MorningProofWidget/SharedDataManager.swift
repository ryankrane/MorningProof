import Foundation

/// Shared data manager for widget and main app communication via App Groups
struct SharedDataManager {
    static let appGroupID = "group.com.rk.bedmate"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Keys
    private enum Keys {
        static let currentStreak = "widget_current_streak"
        static let longestStreak = "widget_longest_streak"
        static let completedHabitsToday = "widget_completed_habits"
        static let totalHabitsToday = "widget_total_habits"
        static let morningCutoffTime = "widget_cutoff_time"
        static let lastPerfectMorning = "widget_last_perfect"
        static let habitStatuses = "widget_habit_statuses"
        static let lastUpdated = "widget_last_updated"
    }

    // MARK: - Widget Data Model
    struct WidgetData {
        var currentStreak: Int
        var longestStreak: Int
        var completedHabits: Int
        var totalHabits: Int
        var cutoffTime: Date?
        var lastPerfectMorning: Date?
        var habitStatuses: [HabitStatus]
        var lastUpdated: Date

        static var placeholder: WidgetData {
            WidgetData(
                currentStreak: 7,
                longestStreak: 14,
                completedHabits: 3,
                totalHabits: 5,
                cutoffTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()),
                lastPerfectMorning: Date(),
                habitStatuses: [
                    HabitStatus(name: "Made Bed", icon: "bed.double.fill", isCompleted: true),
                    HabitStatus(name: "Morning Walk", icon: "figure.walk", isCompleted: true),
                    HabitStatus(name: "Drank Water", icon: "drop.fill", isCompleted: true),
                    HabitStatus(name: "Journaling", icon: "book.fill", isCompleted: false),
                    HabitStatus(name: "Meditation", icon: "brain.head.profile", isCompleted: false)
                ],
                lastUpdated: Date()
            )
        }
    }

    struct HabitStatus: Codable {
        var name: String
        var icon: String
        var isCompleted: Bool
    }

    // MARK: - Read Data (Widget side)
    static func loadWidgetData() -> WidgetData {
        guard let defaults = sharedDefaults else {
            return .placeholder
        }

        let currentStreak = defaults.integer(forKey: Keys.currentStreak)
        let longestStreak = defaults.integer(forKey: Keys.longestStreak)
        let completedHabits = defaults.integer(forKey: Keys.completedHabitsToday)
        let totalHabits = defaults.integer(forKey: Keys.totalHabitsToday)
        let cutoffTime = defaults.object(forKey: Keys.morningCutoffTime) as? Date
        let lastPerfect = defaults.object(forKey: Keys.lastPerfectMorning) as? Date
        let lastUpdated = defaults.object(forKey: Keys.lastUpdated) as? Date ?? Date()

        var habitStatuses: [HabitStatus] = []
        if let data = defaults.data(forKey: Keys.habitStatuses),
           let decoded = try? JSONDecoder().decode([HabitStatus].self, from: data) {
            habitStatuses = decoded
        }

        // Return placeholder if no data yet
        if totalHabits == 0 {
            return .placeholder
        }

        return WidgetData(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            completedHabits: completedHabits,
            totalHabits: totalHabits,
            cutoffTime: cutoffTime,
            lastPerfectMorning: lastPerfect,
            habitStatuses: habitStatuses,
            lastUpdated: lastUpdated
        )
    }

    // MARK: - Write Data (Main app side)
    static func saveWidgetData(
        currentStreak: Int,
        longestStreak: Int,
        completedHabits: Int,
        totalHabits: Int,
        cutoffMinutes: Int,
        lastPerfectMorning: Date?,
        habitStatuses: [HabitStatus]
    ) {
        guard let defaults = sharedDefaults else { return }

        defaults.set(currentStreak, forKey: Keys.currentStreak)
        defaults.set(longestStreak, forKey: Keys.longestStreak)
        defaults.set(completedHabits, forKey: Keys.completedHabitsToday)
        defaults.set(totalHabits, forKey: Keys.totalHabitsToday)
        defaults.set(lastPerfectMorning, forKey: Keys.lastPerfectMorning)
        defaults.set(Date(), forKey: Keys.lastUpdated)

        // Calculate cutoff time for today
        let calendar = Calendar.current
        let hour = cutoffMinutes / 60
        let minute = cutoffMinutes % 60
        if let cutoffTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) {
            defaults.set(cutoffTime, forKey: Keys.morningCutoffTime)
        }

        // Save habit statuses
        if let encoded = try? JSONEncoder().encode(habitStatuses) {
            defaults.set(encoded, forKey: Keys.habitStatuses)
        }
    }
}
