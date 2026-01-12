import Foundation
import SwiftUI
import WidgetKit

@MainActor
class MorningProofManager: ObservableObject {
    static let shared = MorningProofManager()

    // MARK: - Published Properties

    @Published var todayLog: DailyLog
    @Published var habitConfigs: [HabitConfig]
    @Published var settings: MorningProofSettings
    @Published var isLoading = false
    @Published var hasCompletedOnboarding = false
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var lastPerfectMorningDate: Date?

    // MARK: - Dependencies

    private let healthKit = HealthKitManager.shared
    private let storageService = StorageService()
    private let apiService = ClaudeAPIService()

    // MARK: - Initialization

    init() {
        self.settings = MorningProofSettings()
        self.habitConfigs = HabitConfig.defaultConfigs
        self.todayLog = DailyLog()

        loadData()
    }

    // MARK: - Data Loading

    func loadData() {
        // Load settings
        if let savedSettings = storageService.loadMorningProofSettings() {
            settings = savedSettings
        }

        // Load habit configs
        if let savedConfigs = storageService.loadHabitConfigs() {
            habitConfigs = savedConfigs
        }

        // Load or create today's log
        if let savedLog = storageService.loadDailyLog(for: Date()) {
            todayLog = savedLog
        } else {
            todayLog = createDailyLog(for: Date())
        }

        hasCompletedOnboarding = storageService.hasCompletedOnboarding()

        // Load streak data
        loadStreakData()
        checkAndUpdateStreakOnLoad()
    }

    func createDailyLog(for date: Date) -> DailyLog {
        var log = DailyLog(date: date)

        // Create completion entries for enabled habits
        for config in habitConfigs where config.isEnabled {
            let completion = HabitCompletion(habitType: config.habitType, date: date)
            log.completions.append(completion)
        }

        return log
    }

    // MARK: - HealthKit Sync

    func syncHealthData() async {
        isLoading = true

        await healthKit.syncMorningData()

        // Update auto-tracked habits
        await updateAutoTrackedHabits()

        isLoading = false
    }

    private func updateAutoTrackedHabits() async {
        // Update morning steps
        if let index = todayLog.completions.firstIndex(where: { $0.habitType == .morningSteps }) {
            let steps = await healthKit.fetchStepsBeforeCutoff(cutoffMinutes: settings.morningCutoffMinutes)
            let stepGoal = habitConfigs.first { $0.habitType == .morningSteps }?.goal ?? 500

            todayLog.completions[index].verificationData = HabitCompletion.VerificationData(stepCount: steps)
            todayLog.completions[index].score = min(100, (steps * 100) / stepGoal)
            todayLog.completions[index].isCompleted = steps >= stepGoal

            if todayLog.completions[index].isCompleted && todayLog.completions[index].completedAt == nil {
                todayLog.completions[index].completedAt = Date()
            }
        }

        // Update sleep duration
        if let index = todayLog.completions.firstIndex(where: { $0.habitType == .sleepDuration }) {
            if let sleepData = healthKit.lastNightSleep {
                let sleepGoal = Double(habitConfigs.first { $0.habitType == .sleepDuration }?.goal ?? 7)

                todayLog.completions[index].verificationData = HabitCompletion.VerificationData(sleepHours: sleepData.totalHours)
                todayLog.completions[index].score = min(100, Int((sleepData.totalHours / sleepGoal) * 100))
                todayLog.completions[index].isCompleted = sleepData.totalHours >= sleepGoal

                if todayLog.completions[index].isCompleted && todayLog.completions[index].completedAt == nil {
                    todayLog.completions[index].completedAt = Date()
                }
            }
        }

        recalculateScore()
        saveCurrentState()
    }

    // MARK: - Habit Completion

    func completeHabit(_ habitType: HabitType, verificationData: HabitCompletion.VerificationData? = nil) {
        guard let index = todayLog.completions.firstIndex(where: { $0.habitType == habitType }) else { return }

        todayLog.completions[index].isCompleted = true
        todayLog.completions[index].completedAt = Date()
        todayLog.completions[index].score = 100

        if let data = verificationData {
            todayLog.completions[index].verificationData = data
        }

        recalculateScore()
        saveCurrentState()
    }

    func completeBedVerification(image: UIImage) async -> VerificationResult? {
        guard let index = todayLog.completions.firstIndex(where: { $0.habitType == .madeBed }) else { return nil }

        do {
            let result = try await apiService.verifyBed(image: image)

            if result.isMade {
                todayLog.completions[index].isCompleted = true
                todayLog.completions[index].completedAt = Date()
                todayLog.completions[index].score = result.score * 10 // Convert 1-10 to percentage
                todayLog.completions[index].verificationData = HabitCompletion.VerificationData(
                    aiScore: result.score,
                    aiFeedback: result.feedback
                )

                recalculateScore()
                saveCurrentState()
            }

            return result
        } catch {
            MPLogger.error("Bed verification failed", error: error, category: MPLogger.api)
            return nil
        }
    }

    func completeTextEntry(habitType: HabitType, text: String) {
        guard text.count >= habitType.minimumTextLength else { return }
        guard let index = todayLog.completions.firstIndex(where: { $0.habitType == habitType }) else { return }

        todayLog.completions[index].isCompleted = true
        todayLog.completions[index].completedAt = Date()
        todayLog.completions[index].score = 100
        todayLog.completions[index].verificationData = HabitCompletion.VerificationData(textEntry: text)

        recalculateScore()
        saveCurrentState()
    }

    func updateManualSleep(hours: Double) {
        guard let index = todayLog.completions.firstIndex(where: { $0.habitType == .sleepDuration }) else { return }

        let sleepGoal = Double(habitConfigs.first { $0.habitType == .sleepDuration }?.goal ?? 7)

        todayLog.completions[index].verificationData = HabitCompletion.VerificationData(sleepHours: hours)
        todayLog.completions[index].score = min(100, Int((hours / sleepGoal) * 100))
        todayLog.completions[index].isCompleted = hours >= sleepGoal

        if todayLog.completions[index].isCompleted && todayLog.completions[index].completedAt == nil {
            todayLog.completions[index].completedAt = Date()
        }

        recalculateScore()
        saveCurrentState()
    }

    // MARK: - Score Calculation

    func recalculateScore() {
        todayLog.calculateScore(enabledHabits: habitConfigs)

        // Check if all completed before cutoff
        let cutoffTime = getCutoffTime()
        let enabledTypes = Set(habitConfigs.filter { $0.isEnabled }.map { $0.habitType })
        let relevantCompletions = todayLog.completions.filter { enabledTypes.contains($0.habitType) }

        todayLog.allCompletedBeforeCutoff = relevantCompletions.allSatisfy { completion in
            guard completion.isCompleted, let completedAt = completion.completedAt else { return false }
            return completedAt <= cutoffTime
        }

        // Update streak when all habits completed
        updateStreak()
    }

    private func getCutoffTime() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = settings.morningCutoffMinutes / 60
        components.minute = settings.morningCutoffMinutes % 60
        return calendar.date(from: components) ?? Date()
    }

    // MARK: - Settings

    func updateHabitConfig(_ habitType: HabitType, isEnabled: Bool? = nil, goal: Int? = nil) {
        guard let index = habitConfigs.firstIndex(where: { $0.habitType == habitType }) else { return }

        if let enabled = isEnabled {
            habitConfigs[index].isEnabled = enabled

            // Add or remove from today's log
            if enabled {
                if !todayLog.completions.contains(where: { $0.habitType == habitType }) {
                    todayLog.completions.append(HabitCompletion(habitType: habitType))
                }
            } else {
                todayLog.completions.removeAll { $0.habitType == habitType }
            }
        }

        if let newGoal = goal {
            habitConfigs[index].goal = newGoal
        }

        recalculateScore()
        saveCurrentState()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        storageService.setOnboardingCompleted(true)
        saveCurrentState()
    }

    // MARK: - Persistence

    func saveCurrentState() {
        storageService.saveMorningProofSettings(settings)
        storageService.saveHabitConfigs(habitConfigs)
        storageService.saveDailyLog(todayLog)

        // Update widgets
        updateWidgetData()
        WidgetCenter.shared.reloadAllTimelines()

        // Update Live Activity
        Task {
            await updateLiveActivity()
        }
    }

    private func updateWidgetData() {
        let habitStatuses = enabledHabits.map { config -> SharedDataManager.HabitStatus in
            let completion = todayLog.completions.first { $0.habitType == config.habitType }
            return SharedDataManager.HabitStatus(
                name: config.habitType.displayName,
                icon: config.habitType.icon,
                isCompleted: completion?.isCompleted ?? false
            )
        }

        SharedDataManager.saveWidgetData(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            completedHabits: completedCount,
            totalHabits: totalEnabled,
            cutoffMinutes: settings.morningCutoffMinutes,
            lastPerfectMorning: lastPerfectMorningDate,
            habitStatuses: habitStatuses
        )
    }

    private func updateLiveActivity() async {
        let lastCompleted = todayLog.completions
            .filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
            .first

        let lastHabitName = lastCompleted.flatMap { completion in
            habitConfigs.first { $0.habitType == completion.habitType }?.habitType.displayName
        }

        await LiveActivityManager.shared.updateActivity(
            completedHabits: completedCount,
            totalHabits: totalEnabled,
            lastCompletedHabit: lastHabitName,
            currentStreak: currentStreak
        )
    }

    /// Starts the morning routine Live Activity
    func startMorningActivity() {
        LiveActivityManager.shared.startActivity(
            cutoffTime: getCutoffTime(),
            totalHabits: totalEnabled,
            currentStreak: currentStreak
        )
    }

    /// Ends the morning routine Live Activity
    func endMorningActivity() async {
        await LiveActivityManager.shared.endActivity()
    }

    func resetAllData() {
        settings = MorningProofSettings()
        habitConfigs = HabitConfig.defaultConfigs
        todayLog = createDailyLog(for: Date())
        hasCompletedOnboarding = false
        storageService.resetMorningProofData()
    }

    // MARK: - Computed Properties

    var enabledHabits: [HabitConfig] {
        habitConfigs.filter { $0.isEnabled }.sorted { $0.displayOrder < $1.displayOrder }
    }

    var completedCount: Int {
        todayLog.completions.filter { $0.isCompleted }.count
    }

    var totalEnabled: Int {
        enabledHabits.count
    }

    var isPastCutoff: Bool {
        Date() > getCutoffTime()
    }

    var timeUntilCutoff: TimeInterval {
        let cutoff = getCutoffTime()
        return max(0, cutoff.timeIntervalSince(Date()))
    }

    func getCompletion(for habitType: HabitType) -> HabitCompletion? {
        todayLog.completions.first { $0.habitType == habitType }
    }

    func getDailyLog(for date: Date) -> DailyLog? {
        storageService.loadDailyLog(for: date)
    }

    // MARK: - Streak Tracking

    /// Returns true if all enabled habits are completed today (regardless of cutoff time)
    /// This is used for basic streak tracking
    var hasCompletedAllHabitsToday: Bool {
        return completedCount == totalEnabled && totalEnabled > 0
    }

    /// Returns true if all habits were completed BEFORE the cutoff time
    /// Used for bonus features and extra celebrations
    var isPerfectMorning: Bool {
        guard !isPastCutoff || todayLog.allCompletedBeforeCutoff else { return false }
        return hasCompletedAllHabitsToday
    }

    func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Check if all habits are completed today (streak counts regardless of cutoff)
        if hasCompletedAllHabitsToday {
            if lastPerfectMorningDate == nil {
                // First perfect morning ever
                currentStreak = 1
            } else if let lastDate = lastPerfectMorningDate {
                let lastDay = calendar.startOfDay(for: lastDate)

                if lastDay == today {
                    // Already counted today
                    return
                } else if let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: today),
                          calendar.isDate(lastDay, inSameDayAs: yesterdayDate) {
                    // Yesterday was perfect, increment streak
                    currentStreak += 1
                } else {
                    // Streak broken, start new
                    currentStreak = 1
                }
            }

            lastPerfectMorningDate = today
            longestStreak = max(longestStreak, currentStreak)
            saveStreakData()
        }
    }

    func checkAndUpdateStreakOnLoad() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let lastDate = lastPerfectMorningDate else { return }
        let lastDay = calendar.startOfDay(for: lastDate)

        // If last perfect morning was more than 1 day ago, reset streak
        if let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day, daysDiff > 1 {
            currentStreak = 0
            saveStreakData()
        }
    }

    /// Recovers the user's streak after they purchase streak recovery
    func recoverStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return }

        // Restore the streak by pretending yesterday was a perfect morning
        lastPerfectMorningDate = yesterday
        currentStreak = max(1, settings.currentStreak)

        saveStreakData()
    }

    /// Check if streak was broken and needs recovery
    var streakNeedsRecovery: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let lastDate = lastPerfectMorningDate else { return false }
        let lastDay = calendar.startOfDay(for: lastDate)

        if let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day {
            return daysDiff > 1 && settings.currentStreak > 0
        }
        return false
    }

    /// The streak that would be recovered
    var recoverableStreak: Int {
        return settings.currentStreak
    }

    private func saveStreakData() {
        settings.currentStreak = currentStreak
        settings.longestStreak = longestStreak
        settings.lastPerfectMorningDate = lastPerfectMorningDate
        saveCurrentState()
    }

    private func loadStreakData() {
        currentStreak = settings.currentStreak
        longestStreak = settings.longestStreak
        lastPerfectMorningDate = settings.lastPerfectMorningDate
    }
}

// MARK: - Morning Proof Settings

struct MorningProofSettings: Codable {
    var userName: String
    var morningCutoffMinutes: Int  // Minutes from midnight (e.g., 540 = 9:00 AM)
    var stepGoal: Int
    var sleepGoalHours: Int

    // Streak tracking
    var currentStreak: Int
    var longestStreak: Int
    var lastPerfectMorningDate: Date?
    var totalPerfectMornings: Int

    // Notifications
    var notificationsEnabled: Bool
    var morningReminderTime: Int  // Minutes from midnight (e.g., 420 = 7:00 AM)
    var countdownWarnings: [Int]  // Minutes before cutoff (e.g., [15, 5, 1])

    // App Locking (UI ready, functionality later)
    var appLockingEnabled: Bool
    var lockedApps: [String]  // App bundle IDs (for future use)
    var lockGracePeriod: Int  // Minutes after cutoff before locking

    // Accountability
    var strictModeEnabled: Bool  // Prevents editing past completions
    var allowStreakRecovery: Bool

    // Goals
    var weeklyPerfectMorningsGoal: Int  // Out of 7 days
    var customSleepGoal: Double
    var customStepGoal: Int

    init() {
        self.userName = ""
        self.morningCutoffMinutes = 540  // 9:00 AM
        self.stepGoal = 500
        self.sleepGoalHours = 7
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastPerfectMorningDate = nil
        self.totalPerfectMornings = 0

        // Notifications
        self.notificationsEnabled = true
        self.morningReminderTime = 420  // 7:00 AM
        self.countdownWarnings = [15, 5, 1]

        // App Locking
        self.appLockingEnabled = false
        self.lockedApps = []
        self.lockGracePeriod = 5

        // Accountability - strict mode always on (no editing past completions)
        self.strictModeEnabled = true
        self.allowStreakRecovery = false

        // Goals
        self.weeklyPerfectMorningsGoal = 5
        self.customSleepGoal = 7.0
        self.customStepGoal = 500
    }

    // Computed helper for hour (for HealthKit API compatibility)
    var morningCutoffHour: Int {
        morningCutoffMinutes / 60
    }

    // Formatted display string
    var cutoffTimeFormatted: String {
        let hour = morningCutoffMinutes / 60
        let minute = morningCutoffMinutes % 60
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }

    // Generate all cutoff time options (5:00 AM to 1:00 PM in 15-min intervals)
    static let cutoffTimeOptions: [(minutes: Int, label: String)] = {
        stride(from: 300, through: 780, by: 15).map { mins in
            let hour = mins / 60
            let minute = mins % 60
            let period = hour >= 12 ? "PM" : "AM"
            let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
            return (mins, String(format: "%d:%02d %@", displayHour, minute, period))
        }
    }()
}
