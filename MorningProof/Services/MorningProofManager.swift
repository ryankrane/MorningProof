import Foundation
import SwiftUI

@MainActor
final class MorningProofManager: ObservableObject, Sendable {
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

    // Custom Habits
    @Published var customHabits: [CustomHabit] = []
    @Published var customHabitConfigs: [CustomHabitConfig] = []
    @Published var todayCustomCompletions: [CustomHabitCompletion] = []

    // MARK: - Dependencies
    // Note: HealthKitManager accessed lazily to avoid @MainActor singleton deadlock

    private var healthKit: HealthKitManager { HealthKitManager.shared }
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

        // Load custom habits
        if let savedCustomHabits = storageService.loadCustomHabits() {
            customHabits = savedCustomHabits
        }
        if let savedCustomConfigs = storageService.loadCustomHabitConfigs() {
            customHabitConfigs = savedCustomConfigs
        }
        if let savedCustomCompletions = storageService.loadCustomCompletions(for: Date()) {
            todayCustomCompletions = savedCustomCompletions
        } else {
            todayCustomCompletions = createCustomCompletions(for: Date())
        }

        hasCompletedOnboarding = storageService.hasCompletedOnboarding()

        // Load streak data
        loadStreakData()
        checkAndUpdateStreakOnLoad()

        // TEMPORARILY DISABLED - Waiting for Family Controls approval
        // Check for emergency unlock (user bypassed app blocking)
        // checkForEmergencyUnlock()

        // Ensure shields are applied if we're in the blocking window
        // ensureShieldsAppliedIfNeeded()
    }

    /// Ensures app shields are applied if the user is in the blocking window.
    /// This handles edge cases like app being force-quit during blocking.
    private func ensureShieldsAppliedIfNeeded() {
        guard settings.appLockingEnabled else { return }
        guard AppLockingDataStore.shouldApplyShields() else { return }
        guard !AppLockingDataStore.hasLockedInToday else { return }

        // We're in the blocking window but shields might not be applied
        // (e.g., app was force-quit, or device was restarted)
        ScreenTimeManager.shared.applyShields()
        MPLogger.info("Applied shields on app launch (in blocking window)", category: MPLogger.screenTime)
    }

    /// Checks if the user performed an emergency unlock (bypassed app blocking).
    /// If so, breaks their streak as a consequence.
    private func checkForEmergencyUnlock() {
        guard AppLockingDataStore.wasEmergencyUnlock else { return }

        // Reset the flag
        AppLockingDataStore.wasEmergencyUnlock = false

        // Break the streak
        if settings.currentStreak > 0 {
            MPLogger.warning("Emergency unlock detected - breaking streak from \(settings.currentStreak) to 0", category: MPLogger.general)
            settings.currentStreak = 0
            saveCurrentState()
        }
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

    func createCustomCompletions(for date: Date) -> [CustomHabitCompletion] {
        var completions: [CustomHabitCompletion] = []

        // Create completion entries for enabled custom habits
        for config in customHabitConfigs where config.isEnabled {
            if customHabits.contains(where: { $0.id == config.customHabitId && $0.isActive }) {
                let completion = CustomHabitCompletion(customHabitId: config.customHabitId, date: date)
                completions.append(completion)
            }
        }

        return completions
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

            todayLog.completions[index].verificationData = HabitCompletion.VerificationData(stepCount: steps, isFromHealthKit: true)
            todayLog.completions[index].score = min(100, (steps * 100) / stepGoal)
            todayLog.completions[index].isCompleted = steps >= stepGoal

            if todayLog.completions[index].isCompleted && todayLog.completions[index].completedAt == nil {
                todayLog.completions[index].completedAt = Date()
            }
        }

        // Update sleep duration (only if not manually entered)
        if let index = todayLog.completions.firstIndex(where: { $0.habitType == .sleepDuration }) {
            // Don't override manual entries
            let isManualEntry = todayLog.completions[index].verificationData?.isFromHealthKit == false

            if !isManualEntry, let sleepData = healthKit.lastNightSleep {
                let sleepGoal = Double(habitConfigs.first { $0.habitType == .sleepDuration }?.goal ?? 7)

                todayLog.completions[index].verificationData = HabitCompletion.VerificationData(sleepHours: sleepData.totalHours, isFromHealthKit: true)
                todayLog.completions[index].score = min(100, Int((sleepData.totalHours / sleepGoal) * 100))
                todayLog.completions[index].isCompleted = sleepData.totalHours >= sleepGoal

                if todayLog.completions[index].isCompleted && todayLog.completions[index].completedAt == nil {
                    todayLog.completions[index].completedAt = Date()
                }
            }
        }

        // Update morning workout (only if not manually completed)
        if let index = todayLog.completions.firstIndex(where: { $0.habitType == .morningWorkout }) {
            // Don't override if already manually completed
            let isManuallyCompleted = todayLog.completions[index].isCompleted && todayLog.completions[index].verificationData?.workoutDetected != true

            if !isManuallyCompleted {
                let hasWorkout = await healthKit.checkMorningWorkout(cutoffMinutes: settings.morningCutoffMinutes)

                todayLog.completions[index].verificationData = HabitCompletion.VerificationData(workoutDetected: hasWorkout, isFromHealthKit: true)

                if hasWorkout {
                    todayLog.completions[index].isCompleted = true
                    todayLog.completions[index].score = 100

                    if todayLog.completions[index].completedAt == nil {
                        todayLog.completions[index].completedAt = Date()
                    }
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
                todayLog.completions[index].score = 100 // Binary pass/fail
                todayLog.completions[index].verificationData = HabitCompletion.VerificationData(
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

    func completeSunlightVerification(image: UIImage) async -> SunlightVerificationResult? {
        guard let index = todayLog.completions.firstIndex(where: { $0.habitType == .sunlightExposure }) else { return nil }

        do {
            let result = try await apiService.verifySunlight(image: image)

            if result.isOutside {
                todayLog.completions[index].isCompleted = true
                todayLog.completions[index].completedAt = Date()
                todayLog.completions[index].score = 100 // Binary pass/fail
                todayLog.completions[index].verificationData = HabitCompletion.VerificationData(
                    aiFeedback: result.feedback
                )

                recalculateScore()
                saveCurrentState()
            }

            return result
        } catch {
            MPLogger.error("Sunlight verification failed", error: error, category: MPLogger.api)
            return nil
        }
    }

    func completeHydrationVerification(image: UIImage) async -> HydrationVerificationResult? {
        guard let index = todayLog.completions.firstIndex(where: { $0.habitType == .hydration }) else { return nil }

        do {
            let result = try await apiService.verifyHydration(image: image)

            if result.isWater {
                todayLog.completions[index].isCompleted = true
                todayLog.completions[index].completedAt = Date()
                todayLog.completions[index].score = 100 // Binary - no score
                todayLog.completions[index].verificationData = HabitCompletion.VerificationData(
                    aiFeedback: result.feedback
                )

                recalculateScore()
                saveCurrentState()
            }

            return result
        } catch {
            MPLogger.error("Hydration verification failed", error: error, category: MPLogger.api)
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

        todayLog.completions[index].verificationData = HabitCompletion.VerificationData(sleepHours: hours, isFromHealthKit: false)
        todayLog.completions[index].score = min(100, Int((hours / sleepGoal) * 100))
        todayLog.completions[index].isCompleted = hours >= sleepGoal

        if todayLog.completions[index].isCompleted && todayLog.completions[index].completedAt == nil {
            todayLog.completions[index].completedAt = Date()
        }

        recalculateScore()
        saveCurrentState()
    }

    // MARK: - Custom Habit Management

    /// Add a new custom habit
    func addCustomHabit(_ habit: CustomHabit) {
        customHabits.append(habit)

        // Create config for the habit
        let config = CustomHabitConfig(
            customHabitId: habit.id,
            isEnabled: true,
            displayOrder: customHabitConfigs.count
        )
        customHabitConfigs.append(config)

        // Create today's completion
        let completion = CustomHabitCompletion(customHabitId: habit.id)
        todayCustomCompletions.append(completion)

        saveCurrentState()
    }

    /// Update an existing custom habit
    func updateCustomHabit(_ habit: CustomHabit) {
        if let index = customHabits.firstIndex(where: { $0.id == habit.id }) {
            customHabits[index] = habit
            saveCurrentState()
        }
    }

    /// Delete a custom habit
    func deleteCustomHabit(id: UUID) {
        customHabits.removeAll { $0.id == id }
        customHabitConfigs.removeAll { $0.customHabitId == id }
        todayCustomCompletions.removeAll { $0.customHabitId == id }
        saveCurrentState()
    }

    /// Toggle custom habit enabled state
    func toggleCustomHabit(_ habitId: UUID, isEnabled: Bool) {
        if let index = customHabitConfigs.firstIndex(where: { $0.customHabitId == habitId }) {
            customHabitConfigs[index].isEnabled = isEnabled

            if isEnabled {
                // Add completion if not present
                if !todayCustomCompletions.contains(where: { $0.customHabitId == habitId }) {
                    let completion = CustomHabitCompletion(customHabitId: habitId)
                    todayCustomCompletions.append(completion)
                }
            } else {
                // Remove completion
                todayCustomCompletions.removeAll { $0.customHabitId == habitId }
            }

            recalculateScore()
            saveCurrentState()
        }
    }

    /// Get custom habit by ID
    func getCustomHabit(id: UUID) -> CustomHabit? {
        customHabits.first { $0.id == id }
    }

    /// Get completion for a custom habit
    func getCustomCompletion(for habitId: UUID) -> CustomHabitCompletion? {
        todayCustomCompletions.first { $0.customHabitId == habitId }
    }

    /// Complete custom habit with honor system
    func completeCustomHabitHonorSystem(_ habitId: UUID) {
        guard let index = todayCustomCompletions.firstIndex(where: { $0.customHabitId == habitId }) else { return }

        todayCustomCompletions[index].isCompleted = true
        todayCustomCompletions[index].completedAt = Date()

        recalculateScore()
        saveCurrentState()
    }

    /// Complete custom habit with AI verification
    func completeCustomHabitVerification(habit: CustomHabit, image: UIImage) async -> CustomVerificationResult? {
        guard let index = todayCustomCompletions.firstIndex(where: { $0.customHabitId == habit.id }) else { return nil }

        do {
            let result = try await apiService.verifyCustomHabit(image: image, customHabit: habit)

            if result.isVerified {
                todayCustomCompletions[index].isCompleted = true
                todayCustomCompletions[index].completedAt = Date()
                todayCustomCompletions[index].verificationData = CustomHabitCompletion.VerificationData(
                    aiFeedback: result.feedback
                )

                recalculateScore()
                saveCurrentState()
            }

            return result
        } catch {
            MPLogger.error("Custom habit verification failed", error: error, category: MPLogger.api)
            return nil
        }
    }

    /// Get enabled custom habits (sorted by display order)
    var enabledCustomHabits: [CustomHabit] {
        let enabledIds = Set(customHabitConfigs.filter { $0.isEnabled }.map { $0.customHabitId })
        return customHabits
            .filter { enabledIds.contains($0.id) && $0.isActive }
            .sorted { habit1, habit2 in
                let order1 = customHabitConfigs.first { $0.customHabitId == habit1.id }?.displayOrder ?? 0
                let order2 = customHabitConfigs.first { $0.customHabitId == habit2.id }?.displayOrder ?? 0
                return order1 < order2
            }
    }

    /// Manually complete a workout when HealthKit doesn't detect it
    func completeManualWorkout() {
        guard let index = todayLog.completions.firstIndex(where: { $0.habitType == .morningWorkout }) else { return }

        todayLog.completions[index].verificationData = HabitCompletion.VerificationData(workoutDetected: false, isFromHealthKit: false)
        todayLog.completions[index].isCompleted = true
        todayLog.completions[index].score = 100
        todayLog.completions[index].completedAt = Date()

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

        // Save custom habits data
        storageService.saveCustomHabits(customHabits)
        storageService.saveCustomHabitConfigs(customHabitConfigs)
        storageService.saveCustomCompletions(todayCustomCompletions, for: Date())

        // Sync to App Group for Screen Time extensions
        AppLockingDataStore.morningCutoffMinutes = settings.morningCutoffMinutes
        AppLockingDataStore.appLockingEnabled = settings.appLockingEnabled
        AppLockingDataStore.blockingStartMinutes = settings.blockingStartMinutes

        // Update Live Activity
        Task {
            await updateLiveActivity()
        }
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
        let predefinedCompleted = todayLog.completions.filter { $0.isCompleted }.count
        let customCompleted = todayCustomCompletions.filter { $0.isCompleted }.count
        return predefinedCompleted + customCompleted
    }

    var totalEnabled: Int {
        enabledHabits.count + enabledCustomHabits.count
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

    // MARK: - Lock In Day

    /// Returns true if user can lock in their day (all habits complete and not already locked)
    var canLockInDay: Bool {
        hasCompletedAllHabitsToday && !todayLog.isDayLockedIn
    }

    /// Explicitly lock in the day - called when user long-presses the lock button
    func lockInDay() {
        guard canLockInDay else { return }

        todayLog.isDayLockedIn = true
        todayLog.lockedInAt = Date()

        // Sync lock status to App Group for extensions
        AppLockingDataStore.isDayLockedIn = true

        // TEMPORARILY DISABLED - Waiting for Family Controls approval
        // Remove app shields if app locking is enabled
        // if settings.appLockingEnabled {
        //     ScreenTimeManager.shared.removeShields()
        // }

        saveCurrentState()
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

    // App Locking
    var appLockingEnabled: Bool
    var lockedApps: [String]  // App bundle IDs (for future use)
    var blockingStartMinutes: Int  // When blocking starts (minutes from midnight, e.g. 360 = 6 AM)

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
        self.blockingStartMinutes = 0  // 0 = not configured, user must set

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
