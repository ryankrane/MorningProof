import Foundation

class StorageService {
    // Legacy keys
    private let streakKey = "morningproof_streak_data"
    private let achievementsKey = "morningproof_achievements"
    private let settingsKey = "morningproof_settings"

    // Morning Proof keys
    private let mpSettingsKey = "morningproof_settings"
    private let mpHabitConfigsKey = "morningproof_habit_configs"
    private let mpDailyLogPrefix = "morningproof_daily_"
    private let mpOnboardingKey = "morningproof_onboarding_completed"

    private let defaults = UserDefaults.standard

    // MARK: - Legacy Streak Data (kept for backward compatibility)

    func loadStreakData() -> StreakData {
        guard let data = defaults.data(forKey: streakKey),
              let streakData = try? JSONDecoder().decode(StreakData.self, from: data) else {
            return StreakData()
        }
        return streakData
    }

    func saveStreakData(_ streakData: StreakData) {
        if let data = try? JSONEncoder().encode(streakData) {
            defaults.set(data, forKey: streakKey)
        }
    }

    func recordCompletion() -> StreakData {
        var streakData = loadStreakData()
        streakData.recordCompletion()
        saveStreakData(streakData)
        return streakData
    }

    // MARK: - Legacy Achievements

    func loadAchievements() -> UserAchievements {
        guard let data = defaults.data(forKey: achievementsKey),
              let achievements = try? JSONDecoder().decode(UserAchievements.self, from: data) else {
            return UserAchievements()
        }
        return achievements
    }

    func saveAchievements(_ achievements: UserAchievements) {
        if let data = try? JSONEncoder().encode(achievements) {
            defaults.set(data, forKey: achievementsKey)
        }
    }

    // MARK: - Legacy Settings

    func loadSettings() -> UserSettings {
        guard let data = defaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(UserSettings.self, from: data) else {
            return UserSettings()
        }
        return settings
    }

    func saveSettings(_ settings: UserSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: settingsKey)
        }
    }

    // MARK: - Morning Proof Settings

    func loadMorningProofSettings() -> MorningProofSettings? {
        guard let data = defaults.data(forKey: mpSettingsKey),
              let settings = try? JSONDecoder().decode(MorningProofSettings.self, from: data) else {
            return nil
        }
        return settings
    }

    func saveMorningProofSettings(_ settings: MorningProofSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: mpSettingsKey)
        }
    }

    // MARK: - Habit Configs

    func loadHabitConfigs() -> [HabitConfig]? {
        guard let data = defaults.data(forKey: mpHabitConfigsKey),
              let configs = try? JSONDecoder().decode([HabitConfig].self, from: data) else {
            return nil
        }
        return configs
    }

    func saveHabitConfigs(_ configs: [HabitConfig]) {
        if let data = try? JSONEncoder().encode(configs) {
            defaults.set(data, forKey: mpHabitConfigsKey)
        }
    }

    // MARK: - Daily Logs

    func loadDailyLog(for date: Date) -> DailyLog? {
        let key = dailyLogKey(for: date)
        guard let data = defaults.data(forKey: key),
              let log = try? JSONDecoder().decode(DailyLog.self, from: data) else {
            return nil
        }
        return log
    }

    func saveDailyLog(_ log: DailyLog) {
        let key = dailyLogKey(for: log.date)
        if let data = try? JSONEncoder().encode(log) {
            defaults.set(data, forKey: key)
        }
    }

    private func dailyLogKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return mpDailyLogPrefix + formatter.string(from: date)
    }

    // MARK: - Onboarding

    func hasCompletedOnboarding() -> Bool {
        defaults.bool(forKey: mpOnboardingKey)
    }

    func setOnboardingCompleted(_ completed: Bool) {
        defaults.set(completed, forKey: mpOnboardingKey)
    }

    // MARK: - Reset

    func resetAll() {
        defaults.removeObject(forKey: streakKey)
        defaults.removeObject(forKey: achievementsKey)
        defaults.removeObject(forKey: settingsKey)
        resetMorningProofData()
    }

    func resetMorningProofData() {
        defaults.removeObject(forKey: mpSettingsKey)
        defaults.removeObject(forKey: mpHabitConfigsKey)
        defaults.removeObject(forKey: mpOnboardingKey)

        // Remove daily logs for the past 30 days
        let calendar = Calendar.current
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                defaults.removeObject(forKey: dailyLogKey(for: date))
            }
        }
    }
}
