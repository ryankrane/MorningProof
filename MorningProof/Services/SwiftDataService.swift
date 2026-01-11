import Foundation
import SwiftData

/// SwiftData implementation of DataServiceProtocol
@MainActor
class SwiftDataService: DataServiceProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Settings

    func loadSettings() -> MorningProofSettings? {
        let descriptor = FetchDescriptor<SDSettings>()
        guard let sdSettings = try? modelContext.fetch(descriptor).first else {
            return nil
        }
        return convertToMorningProofSettings(sdSettings)
    }

    func saveSettings(_ settings: MorningProofSettings) {
        let descriptor = FetchDescriptor<SDSettings>()
        let existing = try? modelContext.fetch(descriptor).first

        if let sdSettings = existing {
            updateSDSettings(sdSettings, from: settings)
        } else {
            let sdSettings = createSDSettings(from: settings)
            modelContext.insert(sdSettings)
        }

        try? modelContext.save()
    }

    // MARK: - Habit Configs

    func loadHabitConfigs() -> [HabitConfig]? {
        let descriptor = FetchDescriptor<SDHabitConfig>(
            sortBy: [SortDescriptor(\.displayOrder)]
        )
        guard let sdConfigs = try? modelContext.fetch(descriptor), !sdConfigs.isEmpty else {
            return nil
        }
        return sdConfigs.compactMap { convertToHabitConfig($0) }
    }

    func saveHabitConfigs(_ configs: [HabitConfig]) {
        // Delete existing configs
        let descriptor = FetchDescriptor<SDHabitConfig>()
        if let existing = try? modelContext.fetch(descriptor) {
            for config in existing {
                modelContext.delete(config)
            }
        }

        // Insert new configs
        for config in configs {
            let sdConfig = SDHabitConfig(from: config)
            modelContext.insert(sdConfig)
        }

        try? modelContext.save()
    }

    // MARK: - Daily Logs

    func loadDailyLog(for date: Date) -> DailyLog? {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        var descriptor = FetchDescriptor<SDDailyLog>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < endOfDay }
        )
        descriptor.fetchLimit = 1

        guard let sdLog = try? modelContext.fetch(descriptor).first else {
            return nil
        }
        return convertToDailyLog(sdLog)
    }

    func saveDailyLog(_ log: DailyLog) {
        let startOfDay = Calendar.current.startOfDay(for: log.date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        var descriptor = FetchDescriptor<SDDailyLog>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < endOfDay }
        )
        descriptor.fetchLimit = 1

        let existing = try? modelContext.fetch(descriptor).first

        if let sdLog = existing {
            updateSDDailyLog(sdLog, from: log)
        } else {
            let sdLog = createSDDailyLog(from: log)
            modelContext.insert(sdLog)
        }

        try? modelContext.save()
    }

    func loadDailyLogs(from startDate: Date, to endDate: Date) -> [DailyLog] {
        let start = Calendar.current.startOfDay(for: startDate)
        let end = Calendar.current.startOfDay(for: endDate)

        let descriptor = FetchDescriptor<SDDailyLog>(
            predicate: #Predicate { $0.date >= start && $0.date <= end },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let sdLogs = try? modelContext.fetch(descriptor) else {
            return []
        }
        return sdLogs.map { convertToDailyLog($0) }
    }

    // MARK: - Streak Data

    func loadStreakData() -> StreakData {
        // Streak data is now stored in Settings
        if let settings = loadSettings() {
            var streakData = StreakData()
            streakData.currentStreak = settings.currentStreak
            streakData.longestStreak = settings.longestStreak
            return streakData
        }
        return StreakData()
    }

    func saveStreakData(_ streakData: StreakData) {
        // Streak data is saved as part of settings
        // This is handled by saveSettings
    }

    // MARK: - Achievements

    func loadAchievements() -> UserAchievements {
        let descriptor = FetchDescriptor<SDUnlockedAchievement>()
        guard let unlocked = try? modelContext.fetch(descriptor) else {
            return UserAchievements()
        }

        var achievements = UserAchievements()
        for item in unlocked {
            achievements.unlockedAchievements[item.achievementId] = item.unlockedDate
        }
        return achievements
    }

    func saveAchievements(_ achievements: UserAchievements) {
        // Delete existing
        let descriptor = FetchDescriptor<SDUnlockedAchievement>()
        if let existing = try? modelContext.fetch(descriptor) {
            for item in existing {
                modelContext.delete(item)
            }
        }

        // Insert new
        for (id, date) in achievements.unlockedAchievements {
            let sdAchievement = SDUnlockedAchievement(achievementId: id, unlockedDate: date)
            modelContext.insert(sdAchievement)
        }

        try? modelContext.save()
    }

    // MARK: - Onboarding

    private let onboardingKey = "swiftdata_onboarding_completed"

    func hasCompletedOnboarding() -> Bool {
        UserDefaults.standard.bool(forKey: onboardingKey)
    }

    func setOnboardingCompleted(_ completed: Bool) {
        UserDefaults.standard.set(completed, forKey: onboardingKey)
    }

    // MARK: - Reset

    func resetAllData() {
        // Delete all data
        try? modelContext.delete(model: SDSettings.self)
        try? modelContext.delete(model: SDHabitConfig.self)
        try? modelContext.delete(model: SDDailyLog.self)
        try? modelContext.delete(model: SDHabitCompletion.self)
        try? modelContext.delete(model: SDStreakRecord.self)
        try? modelContext.delete(model: SDUnlockedAchievement.self)

        setOnboardingCompleted(false)

        try? modelContext.save()
    }

    // MARK: - Conversion Helpers

    private func convertToMorningProofSettings(_ sd: SDSettings) -> MorningProofSettings {
        var settings = MorningProofSettings()
        settings.userName = sd.userName
        settings.morningCutoffMinutes = sd.morningCutoffMinutes
        settings.stepGoal = sd.stepGoal
        settings.sleepGoalHours = sd.sleepGoalHours
        settings.customSleepGoal = sd.customSleepGoal
        settings.customStepGoal = sd.customStepGoal
        settings.currentStreak = sd.currentStreak
        settings.longestStreak = sd.longestStreak
        settings.lastPerfectMorningDate = sd.lastPerfectMorningDate
        settings.totalPerfectMornings = sd.totalPerfectMornings
        settings.notificationsEnabled = sd.notificationsEnabled
        settings.morningReminderTime = sd.morningReminderTime
        settings.countdownWarnings = sd.countdownWarnings
        settings.appLockingEnabled = sd.appLockingEnabled
        settings.lockedApps = sd.lockedApps
        settings.lockGracePeriod = sd.lockGracePeriod
        settings.strictModeEnabled = sd.strictModeEnabled
        settings.allowStreakRecovery = sd.allowStreakRecovery
        settings.weeklyPerfectMorningsGoal = sd.weeklyPerfectMorningsGoal
        return settings
    }

    private func createSDSettings(from settings: MorningProofSettings) -> SDSettings {
        let sd = SDSettings()
        updateSDSettings(sd, from: settings)
        return sd
    }

    private func updateSDSettings(_ sd: SDSettings, from settings: MorningProofSettings) {
        sd.userName = settings.userName
        sd.morningCutoffMinutes = settings.morningCutoffMinutes
        sd.stepGoal = settings.stepGoal
        sd.sleepGoalHours = settings.sleepGoalHours
        sd.customSleepGoal = settings.customSleepGoal
        sd.customStepGoal = settings.customStepGoal
        sd.currentStreak = settings.currentStreak
        sd.longestStreak = settings.longestStreak
        sd.lastPerfectMorningDate = settings.lastPerfectMorningDate
        sd.totalPerfectMornings = settings.totalPerfectMornings
        sd.notificationsEnabled = settings.notificationsEnabled
        sd.morningReminderTime = settings.morningReminderTime
        sd.countdownWarnings = settings.countdownWarnings
        sd.appLockingEnabled = settings.appLockingEnabled
        sd.lockedApps = settings.lockedApps
        sd.lockGracePeriod = settings.lockGracePeriod
        sd.strictModeEnabled = settings.strictModeEnabled
        sd.allowStreakRecovery = settings.allowStreakRecovery
        sd.weeklyPerfectMorningsGoal = settings.weeklyPerfectMorningsGoal
    }

    private func convertToHabitConfig(_ sd: SDHabitConfig) -> HabitConfig? {
        guard let habitType = sd.habitType else { return nil }
        return HabitConfig(
            habitType: habitType,
            isEnabled: sd.isEnabled,
            goal: sd.goal,
            displayOrder: sd.displayOrder
        )
    }

    private func convertToDailyLog(_ sd: SDDailyLog) -> DailyLog {
        var log = DailyLog(date: sd.date)
        log.id = sd.id
        log.morningScore = sd.morningScore
        log.allCompletedBeforeCutoff = sd.allCompletedBeforeCutoff
        log.completions = sd.completions.compactMap { convertToHabitCompletion($0) }
        return log
    }

    private func createSDDailyLog(from log: DailyLog) -> SDDailyLog {
        let sd = SDDailyLog(date: log.date)
        sd.id = log.id
        sd.morningScore = log.morningScore
        sd.allCompletedBeforeCutoff = log.allCompletedBeforeCutoff

        for completion in log.completions {
            let sdCompletion = SDHabitCompletion(from: completion)
            sdCompletion.dailyLog = sd
            sd.completions.append(sdCompletion)
        }

        return sd
    }

    private func updateSDDailyLog(_ sd: SDDailyLog, from log: DailyLog) {
        sd.morningScore = log.morningScore
        sd.allCompletedBeforeCutoff = log.allCompletedBeforeCutoff

        // Update completions
        for completion in log.completions {
            if let existing = sd.completions.first(where: { $0.habitTypeRaw == completion.habitType.rawValue }) {
                updateSDHabitCompletion(existing, from: completion)
            } else {
                let sdCompletion = SDHabitCompletion(from: completion)
                sdCompletion.dailyLog = sd
                sd.completions.append(sdCompletion)
            }
        }
    }

    private func convertToHabitCompletion(_ sd: SDHabitCompletion) -> HabitCompletion? {
        guard let habitType = sd.habitType else { return nil }
        var completion = HabitCompletion(habitType: habitType, date: sd.date)
        completion.id = sd.id
        completion.isCompleted = sd.isCompleted
        completion.score = sd.score
        completion.completedAt = sd.completedAt

        if sd.photoURL != nil || sd.aiScore != nil || sd.stepCount != nil || sd.sleepHours != nil || sd.textEntry != nil {
            completion.verificationData = HabitCompletion.VerificationData(
                photoURL: sd.photoURL,
                aiScore: sd.aiScore,
                aiFeedback: sd.aiFeedback,
                stepCount: sd.stepCount,
                sleepHours: sd.sleepHours,
                textEntry: sd.textEntry
            )
        }

        return completion
    }

    private func updateSDHabitCompletion(_ sd: SDHabitCompletion, from completion: HabitCompletion) {
        sd.isCompleted = completion.isCompleted
        sd.score = completion.score
        sd.completedAt = completion.completedAt

        if let data = completion.verificationData {
            sd.photoURL = data.photoURL
            sd.aiScore = data.aiScore
            sd.aiFeedback = data.aiFeedback
            sd.stepCount = data.stepCount
            sd.sleepHours = data.sleepHours
            sd.textEntry = data.textEntry
        }
    }
}
