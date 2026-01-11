import Foundation
import SwiftUI

@MainActor
class MorningProofManager: ObservableObject {
    static let shared = MorningProofManager()

    // MARK: - Published Properties

    @Published var todayLog: DailyLog
    @Published var habitConfigs: [HabitConfig]
    @Published var settings: MorningProofSettings
    @Published var isLoading = false
    @Published var hasCompletedOnboarding = false

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
            let steps = await healthKit.fetchStepsBeforeCutoff(cutoffHour: settings.morningCutoffHour)
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
            print("Bed verification failed: \(error)")
            return nil
        }
    }

    func completeJournaling(text: String) {
        guard text.count >= HabitType.journaling.minimumTextLength else { return }
        guard let index = todayLog.completions.firstIndex(where: { $0.habitType == .journaling }) else { return }

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
    }

    private func getCutoffTime() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = settings.morningCutoffHour
        components.minute = 0
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
}

// MARK: - Morning Proof Settings

struct MorningProofSettings: Codable {
    var userName: String
    var wakeTimeHour: Int
    var wakeTimeMinute: Int
    var morningCutoffHour: Int
    var stepGoal: Int
    var sleepGoalHours: Int

    init() {
        self.userName = ""
        self.wakeTimeHour = 7
        self.wakeTimeMinute = 0
        self.morningCutoffHour = 9
        self.stepGoal = 500
        self.sleepGoalHours = 7
    }
}
