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

        // Ensure every custom habit has a config (fixes data inconsistencies)
        reconcileCustomHabitConfigs()

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

        // Create completion entries for enabled habits that are active on this day
        for config in habitConfigs where config.isEnabled && DaySchedule.isActiveOn(date: date, activeDays: config.activeDays) {
            let completion = HabitCompletion(habitType: config.habitType, date: date)
            log.completions.append(completion)
        }

        return log
    }

    func createCustomCompletions(for date: Date) -> [CustomHabitCompletion] {
        var completions: [CustomHabitCompletion] = []

        // Create completion entries for enabled custom habits that are active on this day
        for config in customHabitConfigs where config.isEnabled {
            if let habit = customHabits.first(where: { $0.id == config.customHabitId && $0.isActive }) {
                // Check if habit is active on this day
                if DaySchedule.isActiveOn(date: date, activeDays: habit.activeDays) {
                    let completion = CustomHabitCompletion(customHabitId: config.customHabitId, date: date)
                    completions.append(completion)
                }
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

    func completeBedVerification(image: UIImage) async throws -> VerificationResult {
        guard let index = todayLog.completions.firstIndex(where: { $0.habitType == .madeBed }) else {
            throw VerificationError.habitNotEnabled
        }

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
    }

    func completeSunlightVerification(image: UIImage) async throws -> SunlightVerificationResult {
        guard let index = todayLog.completions.firstIndex(where: { $0.habitType == .sunlightExposure }) else {
            throw VerificationError.habitNotEnabled
        }

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
    }

    func completeHydrationVerification(image: UIImage) async throws -> HydrationVerificationResult {
        guard let index = todayLog.completions.firstIndex(where: { $0.habitType == .hydration }) else {
            throw VerificationError.habitNotEnabled
        }

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

        // Create today's completion (only if habit is active today)
        if DaySchedule.isActiveOn(date: Date(), activeDays: habit.activeDays) {
            let completion = CustomHabitCompletion(customHabitId: habit.id)
            todayCustomCompletions.append(completion)
        }

        recalculateScore()
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
        recalculateScore()
        saveCurrentState()
    }

    /// Ensures every custom habit has a corresponding config.
    /// This fixes data inconsistencies where habits exist but configs are missing.
    private func reconcileCustomHabitConfigs() {
        var needsSave = false

        // Fix any habits that have isActive = false (all custom habits should be active)
        for i in customHabits.indices where !customHabits[i].isActive {
            customHabits[i].isActive = true
            needsSave = true
        }

        let existingConfigIds = Set(customHabitConfigs.map { $0.customHabitId })

        for habit in customHabits where habit.isActive {
            if !existingConfigIds.contains(habit.id) {
                // Create missing config with enabled=true
                let config = CustomHabitConfig(
                    customHabitId: habit.id,
                    isEnabled: true,
                    displayOrder: customHabitConfigs.count
                )
                customHabitConfigs.append(config)
                needsSave = true
            }
        }

        // Also create today's completions for newly configured habits
        if needsSave {
            for config in customHabitConfigs where config.isEnabled {
                if let habit = customHabits.first(where: { $0.id == config.customHabitId && $0.isActive }) {
                    if DaySchedule.isActiveOn(date: Date(), activeDays: habit.activeDays) {
                        if !todayCustomCompletions.contains(where: { $0.customHabitId == config.customHabitId }) {
                            let completion = CustomHabitCompletion(customHabitId: config.customHabitId)
                            todayCustomCompletions.append(completion)
                        }
                    }
                }
            }
            saveCurrentState()
        }
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
    func completeCustomHabitVerification(habit: CustomHabit, image: UIImage) async throws -> CustomVerificationResult {
        guard let index = todayCustomCompletions.firstIndex(where: { $0.customHabitId == habit.id }) else {
            throw VerificationError.habitNotEnabled
        }

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
    }

    /// Get enabled custom habits that are active today (sorted by display order)
    var enabledCustomHabits: [CustomHabit] {
        let today = Date()
        let enabledIds = Set(customHabitConfigs.filter { $0.isEnabled }.map { $0.customHabitId })
        return customHabits
            .filter { enabledIds.contains($0.id) && $0.isActive && DaySchedule.isActiveOn(date: today, activeDays: $0.activeDays) }
            .sorted { habit1, habit2 in
                let order1 = customHabitConfigs.first { $0.customHabitId == habit1.id }?.displayOrder ?? 0
                let order2 = customHabitConfigs.first { $0.customHabitId == habit2.id }?.displayOrder ?? 0
                return order1 < order2
            }
    }

    /// Get all enabled custom habits regardless of day schedule (for settings/routine UI)
    var allEnabledCustomHabits: [CustomHabit] {
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

        // Note: Streak is NOT updated here - it only updates when user explicitly locks in via lockInDay()
        // This ensures the flame stays gray until the lock-in celebration completes
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

            // Add or remove from today's log (only if active today)
            let isActiveToday = DaySchedule.isActiveToday(activeDays: habitConfigs[index].activeDays)
            if enabled && isActiveToday {
                if !todayLog.completions.contains(where: { $0.habitType == habitType }) {
                    todayLog.completions.append(HabitCompletion(habitType: habitType))
                }
            } else if !enabled {
                todayLog.completions.removeAll { $0.habitType == habitType }
            }
        }

        if let newGoal = goal {
            habitConfigs[index].goal = newGoal
        }

        recalculateScore()
        saveCurrentState()
    }

    /// Update the day-of-week schedule for a habit
    func updateHabitSchedule(_ habitType: HabitType, activeDays: Set<Int>) {
        guard let index = habitConfigs.firstIndex(where: { $0.habitType == habitType }) else { return }

        habitConfigs[index].activeDays = activeDays

        // Update today's log based on new schedule
        let isActiveToday = DaySchedule.isActiveToday(activeDays: activeDays)
        let isEnabled = habitConfigs[index].isEnabled

        if isEnabled && isActiveToday {
            // Add to today's log if not present
            if !todayLog.completions.contains(where: { $0.habitType == habitType }) {
                todayLog.completions.append(HabitCompletion(habitType: habitType))
            }
        } else {
            // Remove from today's log if not active today
            todayLog.completions.removeAll { $0.habitType == habitType }
        }

        recalculateScore()
        saveCurrentState()
    }

    /// Update the day-of-week schedule for a custom habit
    func updateCustomHabitSchedule(_ habitId: UUID, activeDays: Set<Int>) {
        guard let index = customHabits.firstIndex(where: { $0.id == habitId }) else { return }

        customHabits[index].activeDays = activeDays

        // Update today's completions based on new schedule
        let isActiveToday = DaySchedule.isActiveToday(activeDays: activeDays)
        let isEnabled = customHabitConfigs.first { $0.customHabitId == habitId }?.isEnabled ?? false

        if isEnabled && isActiveToday {
            // Add to today's completions if not present
            if !todayCustomCompletions.contains(where: { $0.customHabitId == habitId }) {
                let completion = CustomHabitCompletion(customHabitId: habitId)
                todayCustomCompletions.append(completion)
            }
        } else {
            // Remove from today's completions if not active today
            todayCustomCompletions.removeAll { $0.customHabitId == habitId }
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

    /// Reset only today's progress (for testing) - keeps settings, habits, and onboarding state
    /// Treats today as "day 0" - a completely fresh start
    func resetTodaysProgress() {
        // Reset today's log (clears all completions)
        todayLog = createDailyLog(for: Date())

        // Reset custom habit completions for today
        todayCustomCompletions = createCustomCompletions(for: Date())

        // Reset lock-in status
        AppLockingDataStore.isDayLockedIn = false

        // If today was counted as a perfect morning, undo the totalPerfectMornings count
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let lastDate = lastPerfectMorningDate, calendar.isDate(lastDate, inSameDayAs: today) {
            if settings.totalPerfectMornings > 0 {
                settings.totalPerfectMornings -= 1
            }
        }

        // Always reset to "day 0" state - fresh start for today
        currentStreak = 0
        lastPerfectMorningDate = nil
        saveStreakData()

        saveCurrentState()
    }

    func resetAllData() {
        // Reset all settings to defaults
        settings = MorningProofSettings()
        habitConfigs = HabitConfig.defaultConfigs
        todayLog = createDailyLog(for: Date())
        hasCompletedOnboarding = false

        // Reset streak data
        currentStreak = 0
        longestStreak = 0
        lastPerfectMorningDate = nil

        // Reset custom habits
        customHabits = []
        customHabitConfigs = []
        todayCustomCompletions = []

        // Clear all persisted data
        storageService.resetMorningProofData()

        // Clear App Group data (for extensions)
        AppLockingDataStore.isDayLockedIn = false
        AppLockingDataStore.morningCutoffMinutes = 540
        AppLockingDataStore.blockingStartMinutes = 0
        AppLockingDataStore.appLockingEnabled = false
        AppLockingDataStore.wasEmergencyUnlock = false
    }

    // MARK: - Computed Properties

    /// Habits that are enabled AND active today (filtered by day-of-week schedule)
    var enabledHabits: [HabitConfig] {
        let today = Date()
        return habitConfigs
            .filter { $0.isEnabled && DaySchedule.isActiveOn(date: today, activeDays: $0.activeDays) }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    /// All enabled habits regardless of day schedule (for settings/routine UI)
    var allEnabledHabits: [HabitConfig] {
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

    /// Public accessor for the cutoff time
    var cutoffTime: Date {
        getCutoffTime()
    }

    /// True if past cutoff AND has incomplete habits that have been completed before (not first-time users)
    var hasOverdueHabits: Bool {
        guard isPastCutoff else { return false }

        // Check predefined habits
        for completion in todayLog.completions where !completion.isCompleted {
            if hasHabitEverBeenCompleted(completion.habitType) {
                return true
            }
        }

        // Check custom habits
        for completion in todayCustomCompletions where !completion.isCompleted {
            if hasCustomHabitEverBeenCompleted(completion.customHabitId) {
                return true
            }
        }

        return false
    }

    /// Returns true if this habit has ever been completed in any past day
    func hasHabitEverBeenCompleted(_ habitType: HabitType) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Check last 30 days (enough to detect first-time users)
        for i in 1...30 {  // Start at 1 to skip today
            guard let date = calendar.date(byAdding: .day, value: -i, to: today),
                  let log = getDailyLog(for: date) else { continue }

            if log.completions.contains(where: { $0.habitType == habitType && $0.isCompleted }) {
                return true
            }
        }
        return false
    }

    /// Returns true if this custom habit has ever been completed in any past day
    func hasCustomHabitEverBeenCompleted(_ customHabitId: UUID) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Check last 30 days (enough to detect first-time users)
        for i in 1...30 {  // Start at 1 to skip today
            guard let date = calendar.date(byAdding: .day, value: -i, to: today),
                  let completions = storageService.loadCustomCompletions(for: date) else { continue }

            if completions.contains(where: { $0.customHabitId == customHabitId && $0.isCompleted }) {
                return true
            }
        }
        return false
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

        // Update the streak now that user has explicitly locked in
        updateStreak()

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
            settings.totalPerfectMornings += 1
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

// MARK: - Verification Errors

enum VerificationError: LocalizedError {
    case habitNotEnabled
    case networkError
    case serverError

    var errorDescription: String? {
        switch self {
        case .habitNotEnabled:
            return "This habit is not enabled"
        case .networkError:
            return "Unable to connect. Please check your internet connection and try again."
        case .serverError:
            return "Something went wrong. Please try again."
        }
    }
}
