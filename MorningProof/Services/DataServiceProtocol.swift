import Foundation

/// Protocol abstracting data persistence operations
/// Allows swapping between UserDefaults (legacy) and SwiftData implementations
@MainActor
protocol DataServiceProtocol {
    // MARK: - Settings
    func loadSettings() -> MorningProofSettings?
    func saveSettings(_ settings: MorningProofSettings)

    // MARK: - Habit Configs
    func loadHabitConfigs() -> [HabitConfig]?
    func saveHabitConfigs(_ configs: [HabitConfig])

    // MARK: - Daily Logs
    func loadDailyLog(for date: Date) -> DailyLog?
    func saveDailyLog(_ log: DailyLog)
    func loadDailyLogs(from startDate: Date, to endDate: Date) -> [DailyLog]

    // MARK: - Streak Data
    func loadStreakData() -> StreakData
    func saveStreakData(_ streakData: StreakData)

    // MARK: - Achievements
    func loadAchievements() -> UserAchievements
    func saveAchievements(_ achievements: UserAchievements)

    // MARK: - Onboarding
    func hasCompletedOnboarding() -> Bool
    func setOnboardingCompleted(_ completed: Bool)

    // MARK: - Reset
    func resetAllData()
}
