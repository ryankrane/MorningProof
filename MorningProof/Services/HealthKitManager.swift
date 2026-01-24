import Foundation
import HealthKit

@MainActor
final class HealthKitManager: ObservableObject, Sendable {
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
        if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(energyType)
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

            // Register background observers for goal notifications
            await HealthKitBackgroundDeliveryService.shared.registerObservers()

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
        let startOfToday = calendar.startOfDay(for: now)

        // Look for sleep from 6 PM yesterday to noon today (excludes afternoon naps)
        // This ensures we only capture "last night's sleep" not random daytime naps from yesterday
        guard let sixPMYesterday = calendar.date(byAdding: .hour, value: -30, to: startOfToday), // 6 PM yesterday
              let noonToday = calendar.date(byAdding: .hour, value: 12, to: startOfToday) else { return }

        // End bound is the earlier of now or noon (don't include afternoon naps from today)
        let endBound = min(now, noonToday)

        let predicate = HKQuery.predicateForSamples(withStart: sixPMYesterday, end: endBound, options: .strictStartDate)
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

            // Filter for sleep stages first (detailed sleep tracking)
            let sleepStages = samples.filter { sample in
                let value = HKCategoryValueSleepAnalysis(rawValue: sample.value)
                return value == .asleepCore || value == .asleepDeep || value == .asleepREM || value == .asleepUnspecified
            }

            // Fallback to inBed if no sleep stages found (basic sleep tracking from some devices)
            let sleepSamples: [HKCategorySample]
            if sleepStages.isEmpty {
                sleepSamples = samples.filter { sample in
                    let value = HKCategoryValueSleepAnalysis(rawValue: sample.value)
                    return value == .inBed
                }
            } else {
                sleepSamples = sleepStages
            }

            guard !sleepSamples.isEmpty else {
                self.lastNightSleep = nil
                return
            }

            // Select samples from the best (highest priority) source only
            // This prevents double-counting when multiple sources (Apple Watch, iPhone, AutoSleep, etc.)
            // each record their own overlapping sleep sessions
            let groups = groupSamplesBySource(sleepSamples)
            let selectedSamples = selectBestSourceSamples(from: groups)

            guard !selectedSamples.isEmpty else {
                self.lastNightSleep = nil
                return
            }

            // Calculate total sleep duration by merging overlapping intervals
            // Apple Health stores sleep stages (core, deep, REM) as separate samples that overlap
            // We need to merge them to avoid double-counting the same sleep time
            let totalSeconds = mergedSleepDuration(from: selectedSamples)

            // Track earliest start and latest end for reference (from selected source only)
            let earliestStart = selectedSamples.map { $0.startDate }.min()
            let latestEnd = selectedSamples.map { $0.endDate }.max()

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

    // MARK: - Active Energy Check

    func fetchActiveEnergyBeforeCutoff(cutoffMinutes: Int) async -> Double {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        var cutoffComponents = calendar.dateComponents([.year, .month, .day], from: now)
        cutoffComponents.hour = cutoffMinutes / 60
        cutoffComponents.minute = cutoffMinutes % 60

        guard let cutoffTime = calendar.date(from: cutoffComponents) else { return 0 }

        let endTime = min(now, cutoffTime)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endTime, options: .strictStartDate)

        do {
            let energy = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: energyType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }

                    let kcal = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                    continuation.resume(returning: kcal)
                }

                healthStore.execute(query)
            }

            return energy
        } catch {
            MPLogger.error("Failed to fetch active energy before cutoff", error: error, category: MPLogger.healthKit)
            return 0
        }
    }

    // MARK: - Morning Workout Check

    /// Checks if user has recorded a workout in Apple Health before the cutoff time.
    /// Only counts formal HKWorkout records (from Apple Fitness, Strava, etc.).
    /// Users can manually confirm if no workout is detected.
    func checkMorningWorkout(cutoffMinutes: Int) async -> Bool {
        return await checkFormalWorkout(cutoffMinutes: cutoffMinutes)
    }

    /// Checks specifically for formal HKWorkout records
    private func checkFormalWorkout(cutoffMinutes: Int) async -> Bool {
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
            MPLogger.error("Failed to check formal workout", error: error, category: MPLogger.healthKit)
            return false
        }
    }

    // MARK: - Source Selection Helpers

    /// Groups sleep samples by their source bundle identifier
    private func groupSamplesBySource(_ samples: [HKCategorySample]) -> [String: [HKCategorySample]] {
        var groups: [String: [HKCategorySample]] = [:]
        for sample in samples {
            let bundleId = sample.sourceRevision.source.bundleIdentifier
            groups[bundleId, default: []].append(sample)
        }
        return groups
    }

    /// Returns priority for a source (lower = better). Apple Watch is highest priority.
    private func sourcePriority(for bundleId: String, productType: String?) -> Int {
        // Check if source is from Apple Watch (productType contains "Watch")
        if let productType = productType, productType.lowercased().contains("watch") {
            return 0  // Highest priority
        }

        // Known quality third-party sleep apps
        let knownSleepApps = [
            "com.tantsissa.autosleep",    // AutoSleep
            "com.northcube.SleepCycle",   // Sleep Cycle
            "com.pillow.sleepanalytics",  // Pillow
            "com.ouraring.oura"           // Oura Ring
        ]
        if knownSleepApps.contains(bundleId) {
            return 1
        }

        // Apple Health (could be iPhone or Watch without productType)
        if bundleId.hasPrefix("com.apple.health") {
            return 2
        }

        // Other sources
        return 3
    }

    /// Selects samples from the highest-priority source
    private func selectBestSourceSamples(from groups: [String: [HKCategorySample]]) -> [HKCategorySample] {
        guard !groups.isEmpty else { return [] }

        var bestSource: String?
        var bestPriority = Int.max

        for (bundleId, samples) in groups {
            let productType = samples.first?.sourceRevision.productType
            let priority = sourcePriority(for: bundleId, productType: productType)

            if priority < bestPriority {
                bestPriority = priority
                bestSource = bundleId
            }
        }

        return bestSource.flatMap { groups[$0] } ?? []
    }

    // MARK: - Sleep Interval Merging

    /// Merges overlapping sleep intervals and returns total sleep duration in seconds.
    /// Apple Health stores sleep stages (core, deep, REM) as separate overlapping samples.
    /// Without merging, we'd double/triple count the same sleep time.
    ///
    /// Uses a 5-minute gap tolerance for brief interruptions within a single source.
    /// Since we now filter to a single source, we don't need the larger tolerance
    /// that was previously used for cross-source merging.
    private func mergedSleepDuration(from samples: [HKCategorySample]) -> TimeInterval {
        guard !samples.isEmpty else { return 0 }

        // Convert samples to (start, end) tuples and sort by start time
        var intervals = samples.map { ($0.startDate, $0.endDate) }
        intervals.sort { $0.0 < $1.0 }

        // Merge overlapping or nearby intervals (within 5 minutes)
        let gapTolerance: TimeInterval = 5 * 60 // 5 minutes
        var merged: [(Date, Date)] = []
        for interval in intervals {
            if let last = merged.last, interval.0 <= last.1.addingTimeInterval(gapTolerance) {
                // Overlaps with or near previous - extend the end if needed
                merged[merged.count - 1] = (last.0, max(last.1, interval.1))
            } else {
                // Gap too large - add as new interval
                merged.append(interval)
            }
        }

        // Sum the merged intervals
        return merged.reduce(0) { total, interval in
            total + interval.1.timeIntervalSince(interval.0)
        }
    }
}
