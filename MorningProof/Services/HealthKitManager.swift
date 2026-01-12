import Foundation
import HealthKit

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    @Published var isAuthorized = false
    @Published var authorizationDenied = false
    @Published var todaySteps: Int = 0
    @Published var lastNightSleep: SleepData?

    struct SleepData {
        var totalHours: Double
        var bedtime: Date?
        var wakeTime: Date?
        var qualityScore: Int // 0-100

        var formattedDuration: String {
            let hours = Int(totalHours)
            let minutes = Int((totalHours - Double(hours)) * 60)
            return "\(hours)h \(minutes)m"
        }
    }

    // Types we want to read
    private let typesToRead: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepType)
        }
        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }
        let workoutType = HKObjectType.workoutType()
        types.insert(workoutType)
        return types
    }()

    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async -> Bool {
        guard isHealthKitAvailable else {
            authorizationDenied = true
            return false
        }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            isAuthorized = true
            await syncMorningData()
            return true
        } catch {
            MPLogger.error("HealthKit authorization failed", error: error, category: MPLogger.healthKit)
            authorizationDenied = true
            return false
        }
    }

    func syncMorningData() async {
        await fetchTodaySteps()
        await fetchLastNightSleep()
    }

    // MARK: - Step Count

    func fetchTodaySteps() async {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        do {
            let steps = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: stepType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }

                    let count = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    continuation.resume(returning: Int(count))
                }

                healthStore.execute(query)
            }

            self.todaySteps = steps
        } catch {
            MPLogger.error("Failed to fetch steps", error: error, category: MPLogger.healthKit)
        }
    }

    func fetchStepsBeforeCutoff(cutoffMinutes: Int) async -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        var cutoffComponents = calendar.dateComponents([.year, .month, .day], from: now)
        cutoffComponents.hour = cutoffMinutes / 60
        cutoffComponents.minute = cutoffMinutes % 60

        guard let cutoffTime = calendar.date(from: cutoffComponents) else { return 0 }

        // If we're past the cutoff, use cutoff time. Otherwise use current time.
        let endTime = min(now, cutoffTime)

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endTime, options: .strictStartDate)

        do {
            let steps = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: stepType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }

                    let count = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    continuation.resume(returning: Int(count))
                }

                healthStore.execute(query)
            }

            return steps
        } catch {
            MPLogger.error("Failed to fetch steps before cutoff", error: error, category: MPLogger.healthKit)
            return 0
        }
    }

    // MARK: - Sleep Analysis

    func fetchLastNightSleep() async {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let calendar = Calendar.current
        let now = Date()

        // Look for sleep in the last 24 hours
        guard let yesterday = calendar.date(byAdding: .hour, value: -24, to: now) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
                let query = HKSampleQuery(
                    sampleType: sleepType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [sortDescriptor]
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }

                    let categorySamples = samples as? [HKCategorySample] ?? []
                    continuation.resume(returning: categorySamples)
                }

                healthStore.execute(query)
            }

            // Filter for actual sleep (not just in bed)
            let sleepSamples = samples.filter { sample in
                let value = HKCategoryValueSleepAnalysis(rawValue: sample.value)
                return value == .asleepCore || value == .asleepDeep || value == .asleepREM || value == .asleepUnspecified
            }

            guard !sleepSamples.isEmpty else {
                self.lastNightSleep = nil
                return
            }

            // Calculate total sleep duration
            var totalSeconds: TimeInterval = 0
            var earliestStart: Date?
            var latestEnd: Date?

            for sample in sleepSamples {
                totalSeconds += sample.endDate.timeIntervalSince(sample.startDate)

                if let existing = earliestStart {
                    if sample.startDate < existing {
                        earliestStart = sample.startDate
                    }
                } else {
                    earliestStart = sample.startDate
                }

                if let existing = latestEnd {
                    if sample.endDate > existing {
                        latestEnd = sample.endDate
                    }
                } else {
                    latestEnd = sample.endDate
                }
            }

            let totalHours = totalSeconds / 3600

            // Calculate quality score based on duration (7-9 hours is optimal)
            let qualityScore: Int
            if totalHours >= 7 && totalHours <= 9 {
                qualityScore = 100
            } else if totalHours >= 6 && totalHours < 7 {
                qualityScore = 80
            } else if totalHours > 9 && totalHours <= 10 {
                qualityScore = 85
            } else if totalHours >= 5 && totalHours < 6 {
                qualityScore = 60
            } else {
                qualityScore = 40
            }

            self.lastNightSleep = SleepData(
                totalHours: totalHours,
                bedtime: earliestStart,
                wakeTime: latestEnd,
                qualityScore: qualityScore
            )

        } catch {
            MPLogger.error("Failed to fetch sleep data", error: error, category: MPLogger.healthKit)
            self.lastNightSleep = nil
        }
    }

    // MARK: - Morning Workout Check

    func checkMorningWorkout(cutoffMinutes: Int) async -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        var cutoffComponents = calendar.dateComponents([.year, .month, .day], from: now)
        cutoffComponents.hour = cutoffMinutes / 60
        cutoffComponents.minute = cutoffMinutes % 60

        guard let cutoffTime = calendar.date(from: cutoffComponents) else { return false }

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: min(now, cutoffTime), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        do {
            let hasWorkout = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                let query = HKSampleQuery(
                    sampleType: HKObjectType.workoutType(),
                    predicate: predicate,
                    limit: 1,
                    sortDescriptors: [sortDescriptor]
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }

                    continuation.resume(returning: (samples?.count ?? 0) > 0)
                }

                healthStore.execute(query)
            }

            return hasWorkout
        } catch {
            MPLogger.error("Failed to check morning workout", error: error, category: MPLogger.healthKit)
            return false
        }
    }
}
