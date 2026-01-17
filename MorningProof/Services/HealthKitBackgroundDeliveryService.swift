import Foundation
import HealthKit
import UserNotifications

/// Service for handling HealthKit background delivery notifications.
/// Registers observers for health data types and sends notifications when goals are met.
///
/// Key concepts:
/// - `HKObserverQuery` only notifies that data changed - we must run a separate query to get actual values
/// - Cannot access @MainActor managers in background - reads settings from UserDefaults directly
/// - Completion handler MUST always be called or HealthKit will throttle future deliveries
final class HealthKitBackgroundDeliveryService: @unchecked Sendable {
    static let shared = HealthKitBackgroundDeliveryService()

    private let healthStore = HKHealthStore()

    // Store observer queries so we can stop them later
    private var stepObserverQuery: HKObserverQuery?
    private var sleepObserverQuery: HKObserverQuery?
    private var workoutObserverQuery: HKObserverQuery?

    // MARK: - UserDefaults Keys for Notification Tracking

    private enum Keys {
        static let stepGoalNotifiedDate = "healthkit_step_goal_notified_date"
        static let sleepGoalNotifiedDate = "healthkit_sleep_goal_notified_date"
        static let workoutNotifiedDate = "healthkit_workout_notified_date"

        // Settings keys (must match what MorningProofManager saves)
        static let morningProofSettings = "morningProofSettings"
        static let habitConfigs = "habitConfigs"
    }

    private var defaults: UserDefaults {
        // Use app group for consistency
        UserDefaults(suiteName: AppLockingDataStore.suiteName) ?? UserDefaults.standard
    }

    private init() {}

    // MARK: - Public API

    /// Registers background delivery observers for all supported health types.
    /// Call this on app launch after HealthKit authorization.
    func registerObservers() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            MPLogger.warning("HealthKit not available - skipping background observers", category: MPLogger.healthKit)
            return
        }

        // Reset daily notification state if it's a new day
        resetDailyNotificationStateIfNeeded()

        await registerStepObserver()
        await registerSleepObserver()
        await registerWorkoutObserver()

        MPLogger.info("HealthKit background observers registered", category: MPLogger.healthKit)
    }

    /// Stops all observer queries. Call when user disables health tracking.
    func stopObservers() {
        if let query = stepObserverQuery {
            healthStore.stop(query)
            stepObserverQuery = nil
        }
        if let query = sleepObserverQuery {
            healthStore.stop(query)
            sleepObserverQuery = nil
        }
        if let query = workoutObserverQuery {
            healthStore.stop(query)
            workoutObserverQuery = nil
        }

        MPLogger.info("HealthKit background observers stopped", category: MPLogger.healthKit)
    }

    /// Resets daily notification state. Call at midnight or when checking for new day.
    func resetDailyNotificationStateIfNeeded() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Check each notification date and reset if from a previous day
        if let stepDate = defaults.object(forKey: Keys.stepGoalNotifiedDate) as? Date,
           !calendar.isDate(stepDate, inSameDayAs: today) {
            defaults.removeObject(forKey: Keys.stepGoalNotifiedDate)
        }

        if let sleepDate = defaults.object(forKey: Keys.sleepGoalNotifiedDate) as? Date,
           !calendar.isDate(sleepDate, inSameDayAs: today) {
            defaults.removeObject(forKey: Keys.sleepGoalNotifiedDate)
        }

        if let workoutDate = defaults.object(forKey: Keys.workoutNotifiedDate) as? Date,
           !calendar.isDate(workoutDate, inSameDayAs: today) {
            defaults.removeObject(forKey: Keys.workoutNotifiedDate)
        }
    }

    // MARK: - Observer Registration

    private func registerStepObserver() async {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        // Enable background delivery
        do {
            try await healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate)
        } catch {
            MPLogger.error("Failed to enable background delivery for steps", error: error, category: MPLogger.healthKit)
            return
        }

        // Create and execute observer query
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, completionHandler, error in
            if let error = error {
                MPLogger.error("Step observer error", error: error, category: MPLogger.healthKit)
                completionHandler()
                return
            }

            Task {
                await self?.handleStepDataChange()
                completionHandler()
            }
        }

        stepObserverQuery = query
        healthStore.execute(query)
    }

    private func registerSleepObserver() async {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        do {
            try await healthStore.enableBackgroundDelivery(for: sleepType, frequency: .immediate)
        } catch {
            MPLogger.error("Failed to enable background delivery for sleep", error: error, category: MPLogger.healthKit)
            return
        }

        let query = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] _, completionHandler, error in
            if let error = error {
                MPLogger.error("Sleep observer error", error: error, category: MPLogger.healthKit)
                completionHandler()
                return
            }

            Task {
                await self?.handleSleepDataChange()
                completionHandler()
            }
        }

        sleepObserverQuery = query
        healthStore.execute(query)
    }

    private func registerWorkoutObserver() async {
        let workoutType = HKObjectType.workoutType()

        do {
            try await healthStore.enableBackgroundDelivery(for: workoutType, frequency: .immediate)
        } catch {
            MPLogger.error("Failed to enable background delivery for workouts", error: error, category: MPLogger.healthKit)
            return
        }

        let query = HKObserverQuery(sampleType: workoutType, predicate: nil) { [weak self] _, completionHandler, error in
            if let error = error {
                MPLogger.error("Workout observer error", error: error, category: MPLogger.healthKit)
                completionHandler()
                return
            }

            Task {
                await self?.handleWorkoutDataChange()
                completionHandler()
            }
        }

        workoutObserverQuery = query
        healthStore.execute(query)
    }

    // MARK: - Data Change Handlers

    private func handleStepDataChange() async {
        // Check if step tracking is enabled
        guard isStepTrackingEnabled() else { return }

        // Check if already notified today
        guard !hasNotifiedForStepsToday() else { return }

        // Check if we're past cutoff (don't notify after cutoff)
        guard !isPastCutoff() else { return }

        // Fetch today's steps
        let steps = await fetchTodaySteps()
        let goal = getStepGoal()

        guard steps >= goal else { return }

        // Goal met! Send notification
        await sendGoalNotification(
            identifier: "step_goal_complete",
            title: "Step goal achieved!",
            body: "You hit \(steps.formatted()) steps this morning."
        )

        // Mark as notified
        defaults.set(Date(), forKey: Keys.stepGoalNotifiedDate)
        MPLogger.info("Step goal notification sent (\(steps)/\(goal))", category: MPLogger.healthKit)
    }

    private func handleSleepDataChange() async {
        // Check if sleep tracking is enabled
        guard isSleepTrackingEnabled() else { return }

        // Check if already notified today
        guard !hasNotifiedForSleepToday() else { return }

        // Check if we're past cutoff
        guard !isPastCutoff() else { return }

        // Fetch last night's sleep
        let sleepHours = await fetchLastNightSleep()
        let goal = getSleepGoal()

        guard sleepHours >= goal else { return }

        // Format sleep duration nicely
        let hours = Int(sleepHours)
        let minutes = Int((sleepHours - Double(hours)) * 60)
        let durationString = minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours) hours"

        await sendGoalNotification(
            identifier: "sleep_goal_complete",
            title: "Sleep goal achieved!",
            body: "You got \(durationString) of sleep last night."
        )

        defaults.set(Date(), forKey: Keys.sleepGoalNotifiedDate)
        MPLogger.info("Sleep goal notification sent (\(String(format: "%.1f", sleepHours))/\(goal)h)", category: MPLogger.healthKit)
    }

    private func handleWorkoutDataChange() async {
        // Check if workout tracking is enabled
        guard isWorkoutTrackingEnabled() else { return }

        // Check if already notified today
        guard !hasNotifiedForWorkoutToday() else { return }

        // Check if we're past cutoff
        guard !isPastCutoff() else { return }

        // Check for morning workout
        let hasWorkout = await checkMorningWorkout()

        guard hasWorkout else { return }

        await sendGoalNotification(
            identifier: "workout_complete",
            title: "Morning workout detected!",
            body: "Great start to your day."
        )

        defaults.set(Date(), forKey: Keys.workoutNotifiedDate)
        MPLogger.info("Workout notification sent", category: MPLogger.healthKit)
    }

    // MARK: - HealthKit Queries

    private func fetchTodaySteps() async -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let cutoffTime = getCutoffTime()
        let endTime = min(now, cutoffTime)

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endTime, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if error != nil {
                    continuation.resume(returning: 0)
                    return
                }
                let count = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(count))
            }
            healthStore.execute(query)
        }
    }

    private func fetchLastNightSleep() async -> Double {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }

        let calendar = Calendar.current
        let now = Date()
        guard let yesterday = calendar.date(byAdding: .hour, value: -24, to: now) else { return 0 }

        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if error != nil {
                    continuation.resume(returning: 0)
                    return
                }

                guard let categorySamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }

                // Filter for actual sleep (not just in bed)
                let sleepSamples = categorySamples.filter { sample in
                    let value = HKCategoryValueSleepAnalysis(rawValue: sample.value)
                    return value == .asleepCore || value == .asleepDeep || value == .asleepREM || value == .asleepUnspecified
                }

                var totalSeconds: TimeInterval = 0
                for sample in sleepSamples {
                    totalSeconds += sample.endDate.timeIntervalSince(sample.startDate)
                }

                continuation.resume(returning: totalSeconds / 3600)
            }
            healthStore.execute(query)
        }
    }

    private func checkMorningWorkout() async -> Bool {
        let workoutType = HKObjectType.workoutType()

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let cutoffTime = getCutoffTime()
        let endTime = min(now, cutoffTime)

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endTime, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, error in
                if error != nil {
                    continuation.resume(returning: false)
                    return
                }
                continuation.resume(returning: (samples?.count ?? 0) > 0)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Notification Sending

    private func sendGoalNotification(identifier: String, title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "GOAL_COMPLETE"

        // nil trigger = immediate delivery
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            MPLogger.error("Failed to send goal notification", error: error, category: MPLogger.notification)
        }
    }

    // MARK: - Settings Helpers

    private func getCutoffTime() -> Date {
        let cutoffMinutes = AppLockingDataStore.morningCutoffMinutes
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = cutoffMinutes / 60
        components.minute = cutoffMinutes % 60
        return calendar.date(from: components) ?? Date()
    }

    private func isPastCutoff() -> Bool {
        return Date() > getCutoffTime()
    }

    private func getStepGoal() -> Int {
        // Try to read from stored habit configs
        if let data = UserDefaults.standard.data(forKey: Keys.habitConfigs),
           let configs = try? JSONDecoder().decode([HabitConfig].self, from: data),
           let stepConfig = configs.first(where: { $0.habitType == .morningSteps }) {
            return stepConfig.goal
        }
        return 500 // Default
    }

    private func getSleepGoal() -> Double {
        if let data = UserDefaults.standard.data(forKey: Keys.habitConfigs),
           let configs = try? JSONDecoder().decode([HabitConfig].self, from: data),
           let sleepConfig = configs.first(where: { $0.habitType == .sleepDuration }) {
            return Double(sleepConfig.goal)
        }
        return 7.0 // Default
    }

    private func isStepTrackingEnabled() -> Bool {
        if let data = UserDefaults.standard.data(forKey: Keys.habitConfigs),
           let configs = try? JSONDecoder().decode([HabitConfig].self, from: data),
           let stepConfig = configs.first(where: { $0.habitType == .morningSteps }) {
            return stepConfig.isEnabled
        }
        return false
    }

    private func isSleepTrackingEnabled() -> Bool {
        if let data = UserDefaults.standard.data(forKey: Keys.habitConfigs),
           let configs = try? JSONDecoder().decode([HabitConfig].self, from: data),
           let sleepConfig = configs.first(where: { $0.habitType == .sleepDuration }) {
            return sleepConfig.isEnabled
        }
        return false
    }

    private func isWorkoutTrackingEnabled() -> Bool {
        if let data = UserDefaults.standard.data(forKey: Keys.habitConfigs),
           let configs = try? JSONDecoder().decode([HabitConfig].self, from: data),
           let workoutConfig = configs.first(where: { $0.habitType == .morningWorkout }) {
            return workoutConfig.isEnabled
        }
        return false
    }

    // MARK: - Notification State Tracking

    private func hasNotifiedForStepsToday() -> Bool {
        guard let date = defaults.object(forKey: Keys.stepGoalNotifiedDate) as? Date else { return false }
        return Calendar.current.isDateInToday(date)
    }

    private func hasNotifiedForSleepToday() -> Bool {
        guard let date = defaults.object(forKey: Keys.sleepGoalNotifiedDate) as? Date else { return false }
        return Calendar.current.isDateInToday(date)
    }

    private func hasNotifiedForWorkoutToday() -> Bool {
        guard let date = defaults.object(forKey: Keys.workoutNotifiedDate) as? Date else { return false }
        return Calendar.current.isDateInToday(date)
    }
}
