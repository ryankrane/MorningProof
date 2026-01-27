import SwiftUI

struct DashboardView: View {
    @ObservedObject var manager: MorningProofManager
    @Environment(\.colorScheme) var colorScheme
    @State private var showSettings = false
    @State private var showBedCamera = false
    @State private var showSunlightCamera = false
    @State private var showHydrationCamera = false
    @State private var showSleepInput = false
    @State private var showHabitEditor = false
    @State private var holdProgress: [HabitType: CGFloat] = [:]

    // New AI-verified habits (using generic camera view)
    @State private var genericCameraHabitType: HabitType? = nil
    // Text entry habits
    @State private var textEntryHabitType: HabitType? = nil

    // Custom habit states
    @State private var customHabitCameraTarget: CustomHabit? = nil
    @State private var customHoldProgress: [UUID: CGFloat] = [:]
    @State private var recentlyCompletedCustomHabits: Set<UUID> = []
    @State private var customHabitRowFlash: [UUID: Bool] = [:]
    @State private var customHabitRowGlow: [UUID: CGFloat] = [:]
    @State private var showConfettiForCustomHabit: UUID? = nil

    // Celebration state
    @State private var recentlyCompletedHabits: Set<HabitType> = []
    @State private var showConfettiForHabit: HabitType? = nil
    @State private var showLockInCelebration = false
    @State private var previouslyCompletedHabits: Set<HabitType> = []
    @State private var showGrandFinaleConfetti = false  // For final habit celebration

    // Enhanced animation state
    @State private var habitRowFlash: [HabitType: Bool] = [:]
    @State private var habitRowGlow: [HabitType: CGFloat] = [:]
    @State private var triggerStreakPulse = false

    // Lock-in button position tracking
    @State private var lockButtonFrame: CGRect = .zero
    @State private var streakFlameFrame: CGRect = .zero

    // Lock-in celebration state
    @State private var previousStreakBeforeLockIn: Int = 0
    @State private var triggerIgnition: Bool = false
    @State private var streakShakeOffset: CGFloat = 0

    // Visual streak for flame timing - only updates AFTER celebration completes
    @State private var visualStreak: Int = 0
    // Visual perfect morning state - only updates AFTER celebration completes (for poof animation)
    @State private var visualPerfectMorning: Bool = false

    // Environment
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { geometry in
            let safeAreaHeight = geometry.size.height
            let habitCount = manager.totalEnabled
            let layout = DynamicHabitLayout(availableHeight: safeAreaHeight, habitCount: habitCount)

            ZStack {
                // Background
                MPColors.background
                    .ignoresSafeArea()

                // Use ScrollView only if habits can't fit (7+ habits typically)
                if layout.needsScrolling {
                    ScrollView(showsIndicators: false) {
                        dashboardContent(layout: layout)
                    }
                } else {
                    dashboardContent(layout: layout)
                }

                // Lock-in celebration overlay (when user locks in their day)
                // Uses ignoresSafeArea to ensure full screen coverage for accurate global positioning
                if showLockInCelebration {
                    LockInCelebrationView(
                        isShowing: $showLockInCelebration,
                        buttonPosition: CGPoint(x: lockButtonFrame.midX, y: lockButtonFrame.midY),
                        streakFlamePosition: CGPoint(x: streakFlameFrame.midX, y: streakFlameFrame.midY),
                        previousStreak: previousStreakBeforeLockIn,
                        onFlameArrived: {
                            // Update visual perfect morning state first (so poof can trigger)
                            visualPerfectMorning = manager.isPerfectMorning
                            // Trigger StreakHeroCard pulse when flame arrives
                            triggerStreakPulse = true
                        },
                        onIgnition: {
                            // Don't trigger ignition yet - wait for celebration to complete
                            // This ensures flame stays gray until the flying flame "ignites" it
                        },
                        onShake: { offset in
                            streakShakeOffset = offset
                        }
                    )
                    .ignoresSafeArea()
                }

                // Grand finale confetti (when final habit completed)
                if showGrandFinaleConfetti {
                    GrandFinaleConfettiView()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

            }
        }
        .sheet(isPresented: $showSettings) {
            MorningProofSettingsView(manager: manager)
        }
        .sheet(isPresented: $showBedCamera) {
            BedCameraView(manager: manager)
        }
        .sheet(isPresented: $showSunlightCamera) {
            SunlightCameraView(manager: manager)
        }
        .sheet(isPresented: $showHydrationCamera) {
            HydrationCameraView(manager: manager)
        }
        .sheet(isPresented: $showSleepInput) {
            SleepInputSheet(manager: manager)
        }
        .sheet(isPresented: $showHabitEditor) {
            HabitEditorSheet(manager: manager)
        }
        .sheet(item: $customHabitCameraTarget) { habit in
            if habit.mediaType == .video {
                VideoVerificationView(manager: manager, customHabit: habit)
            } else {
                CustomHabitCameraView(manager: manager, customHabit: habit)
            }
        }
        .sheet(item: $genericCameraHabitType) { habitType in
            GenericAICameraView(manager: manager, habitType: habitType)
        }
        .sheet(item: $textEntryHabitType) { habitType in
            TextEntryHabitSheet(manager: manager, habitType: habitType)
        }
        .task {
            // Track which habits were completed before sync
            previouslyCompletedHabits = Set(manager.todayLog.completions.filter { $0.isCompleted }.map { $0.habitType })

            await manager.syncHealthData()

            // Check for newly auto-completed habits after sync
            checkForNewlyCompletedHabits()

            // Sync after data loaded
            visualStreak = manager.currentStreak
        }
        .onAppear {
            // Initialize visual states with current values
            visualStreak = manager.currentStreak
            visualPerfectMorning = manager.isPerfectMorning
        }
        .onChange(of: manager.currentStreak) { oldValue, newValue in
            // Only sync visualStreak if:
            // 1. Not during a lock-in celebration (showLockInCelebration is false)
            // 2. OR streak decreased (reset/new day)
            if !showLockInCelebration || newValue < oldValue {
                visualStreak = newValue
            }
        }
        .onChange(of: manager.isPerfectMorning) { _, newValue in
            // Only sync if not during a lock-in celebration
            // During celebration, we update visualPerfectMorning when flame arrives
            if !showLockInCelebration {
                visualPerfectMorning = newValue
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    previouslyCompletedHabits = Set(manager.todayLog.completions.filter { $0.isCompleted }.map { $0.habitType })
                    await manager.syncHealthData()
                    checkForNewlyCompletedHabits()
                    // Sync after returning from background
                    if !showLockInCelebration {
                        visualStreak = manager.currentStreak
                        visualPerfectMorning = manager.isPerfectMorning
                    }
                }
            }
        }
        .onChange(of: showLockInCelebration) { oldValue, newValue in
            // When celebration completes (goes from true to false), update visual states
            // This is when the flying flame has "ignited" the streak flame
            if oldValue && !newValue {
                // Trigger ignition effect if going from 0→1
                if previousStreakBeforeLockIn == 0 {
                    triggerIgnition = true
                }
                // Now update the visual streak (makes flame turn orange and number update)
                visualStreak = manager.currentStreak
                // Update perfect morning state (triggers poof animation)
                visualPerfectMorning = manager.isPerfectMorning
            }
        }
    }

    private func triggerLockInCelebration() {
        // Capture the streak BEFORE lock-in (0 = ignition, 1+ = flare-up)
        previousStreakBeforeLockIn = manager.currentStreak
        manager.lockInDay()
        showLockInCelebration = true
    }

    // MARK: - Dashboard Content

    /// Main dashboard content extracted to support conditional ScrollView wrapping
    @ViewBuilder
    private func dashboardContent(layout: DynamicHabitLayout) -> some View {
        VStack(spacing: MPSpacing.xl) {
            // Header
            headerSection

            // Streak Hero Card - uses visualStreak and visualPerfectMorning so updates sync with celebration
            StreakHeroCard(
                currentStreak: visualStreak,
                completedToday: manager.completedCount,
                totalHabits: manager.totalEnabled,
                isPerfectMorning: visualPerfectMorning,
                timeUntilCutoff: manager.isPastCutoff ? nil : manager.timeUntilCutoff,
                cutoffTimeFormatted: manager.settings.cutoffTimeFormatted,
                hasOverdueHabits: manager.hasOverdueHabits,
                triggerPulse: $triggerStreakPulse,
                flameFrame: $streakFlameFrame,
                triggerIgnition: $triggerIgnition,
                impactShake: $streakShakeOffset,
                cardHeight: layout.streakCardHeight
            )

            // Habits List
            habitsSection(layout: layout)

            // Always add spacer to push content to top
            // Use minLength when scrolling to add extra padding at bottom
            Spacer(minLength: layout.needsScrolling ? MPSpacing.xxxl : 0)
        }
        .padding(.horizontal, MPSpacing.xl)
        .padding(.top, MPSpacing.sm)
    }

    /// Checks for habits that were just auto-completed by HealthKit sync and triggers confetti
    private func checkForNewlyCompletedHabits() {
        let currentlyCompleted = Set(manager.todayLog.completions.filter { $0.isCompleted }.map { $0.habitType })
        let newlyCompleted = currentlyCompleted.subtracting(previouslyCompletedHabits)

        // Trigger confetti for each newly completed auto-tracked habit
        for habitType in newlyCompleted {
            // Only celebrate auto-tracked habits here (steps, sleep, and workout)
            if habitType == .morningSteps || habitType == .sleepDuration || habitType == .morningWorkout {
                celebrateAutoCompletedHabit(habitType)
            }
        }

        // Update tracking
        previouslyCompletedHabits = currentlyCompleted
    }

    /// Triggers celebration for an auto-completed habit
    private func celebrateAutoCompletedHabit(_ habitType: HabitType) {
        // Add to recently completed for scale animation
        recentlyCompletedHabits.insert(habitType)

        // Trigger flash effect
        habitRowFlash[habitType] = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            habitRowFlash[habitType] = false
        }

        // Trigger glow effect
        habitRowGlow[habitType] = 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            habitRowGlow[habitType] = 0
        }

        // Show premium burst confetti (haptic handled by burst view)
        showConfettiForHabit = habitType

        // Clear confetti after burst animation (1.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            showConfettiForHabit = nil
        }

        // Remove from recently completed after animation settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            recentlyCompletedHabits.remove(habitType)
        }
    }

    // MARK: - Header

    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: MPSpacing.xs) {
                Text(greeting)
                    .font(MPFont.headingMedium())
                    .foregroundColor(MPColors.textPrimary)

                Text(dateString)
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textTertiary)
            }

            Spacer()
        }
        .padding(.top, MPSpacing.sm)
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = manager.settings.userName.isEmpty ? "" : ", \(manager.settings.userName)"

        switch hour {
        case 5..<12:
            return "Good morning\(name) ☀️"
        case 12..<17:
            return "Good afternoon\(name) 🌤️"
        case 17..<21:
            return "Good evening\(name) 🌙"
        default:
            return "Good night\(name) 🌙"
        }
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    // MARK: - Habits Section (Apple-Style Redesign)

    @ViewBuilder
    func habitsSection(layout: DynamicHabitLayout) -> some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            // Section header with completion status
            HStack {
                Text("Habits")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(MPColors.textPrimary)

                Spacer()

                // Completion indicator (minimal, Apple-style)
                if manager.completedCount == manager.totalEnabled {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(MPColors.success)
                        Text("Complete")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(MPColors.success)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Text("\(manager.completedCount)/\(manager.totalEnabled)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(MPColors.textSecondary)
                }

                // Edit button
                Button {
                    showHabitEditor = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(MPColors.primary)
                }
            }
            .padding(.horizontal, 4)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: manager.completedCount == manager.totalEnabled)

            // Apple-style list container (single rounded rectangle with all habits inside)
            VStack(spacing: 0) {
                // All habits sorted by verification type with dividers between them
                let allConfigs = sortedHabitConfigs()

                ForEach(Array(allConfigs.enumerated()), id: \.element.id) { index, item in
                    switch item {
                    case .predefined(let config):
                        appleStyleHabitRow(for: config, layout: layout)

                        if index < allConfigs.count - 1 {
                            Divider()
                                .padding(.leading, 52)  // Aligns with text, not icon
                        }

                    case .custom(let customHabit):
                        appleStyleCustomHabitRow(for: customHabit, layout: layout)

                        if index < allConfigs.count - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .mpShadow(.medium)  // One shadow for entire container

            // Lock In Day Button
            HStack {
                Spacer()
                LockInDayButton(
                    isEnabled: manager.canLockInDay,
                    isLockedIn: manager.todayLog.isDayLockedIn,
                    onLockIn: {
                        triggerLockInCelebration()
                    },
                    buttonWidth: layout.lockButtonWidth,
                    buttonHeight: layout.lockButtonHeight
                )
                .background(
                    GeometryReader { geo in
                        Color.clear.onAppear {
                            lockButtonFrame = geo.frame(in: .global)
                        }
                        .onChange(of: geo.frame(in: .global)) { _, newFrame in
                            lockButtonFrame = newFrame
                        }
                    }
                )
                Spacer()
            }
            .padding(.top, layout.lockButtonPadding)
        }
    }

    // MARK: - Apple-Style Habit Row Helpers

    /// Enum to unify predefined and custom habits for sorted list
    private enum HabitItem: Identifiable {
        case predefined(HabitConfig)
        case custom(CustomHabit)

        var id: String {
            switch self {
            case .predefined(let config):
                return config.id
            case .custom(let habit):
                return habit.id.uuidString
            }
        }

        var tierRawValue: Int {
            switch self {
            case .predefined(let config):
                return config.habitType.tier.rawValue
            case .custom(let habit):
                // Map CustomVerificationType to HabitVerificationTier equivalent
                switch habit.verificationType {
                case .aiVerified:
                    return HabitVerificationTier.aiVerified.rawValue
                case .honorSystem:
                    return HabitVerificationTier.honorSystem.rawValue
                }
            }
        }
    }

    /// Returns all enabled habits sorted by verification tier
    private func sortedHabitConfigs() -> [HabitItem] {
        var items: [HabitItem] = []

        // Add all predefined habits
        items.append(contentsOf: manager.enabledHabits.map { .predefined($0) })

        // Add all custom habits
        items.append(contentsOf: manager.enabledCustomHabits.map { .custom($0) })

        // Sort by verification tier (AI → Auto → Journaling → Honor)
        return items.sorted { $0.tierRawValue < $1.tierRawValue }
    }

    /// Determines if a habit is a "hold to complete" type (not a special input type)
    /// Only habits with special input UIs (camera, sheets, auto-progress, text entry) are excluded
    private func isHoldToCompleteHabit(_ habitType: HabitType) -> Bool {
        // These habits have special input types and don't use hold-to-complete:
        // - madeBed, sunlightExposure, hydration: original camera verification
        // - healthyBreakfast, morningJournal, vitamins, skincare, mealPrep: new AI camera verification
        // - gratitude, dailyPlanning: text entry
        // - sleepDuration: sleep input sheet
        // - morningSteps: auto-tracked with circular progress
        // Everything else uses hold-to-complete for manual confirmation
        let specialInputHabits: Set<HabitType> = [
            .madeBed, .sleepDuration, .morningSteps, .sunlightExposure, .hydration,
            .healthyBreakfast, .morningJournal, .vitamins, .skincare, .mealPrep,
            .gratitude, .dailyPlanning
        ]
        return !specialInputHabits.contains(habitType)
    }

    /// Returns true if completing this habit would complete ALL habits (final habit)
    private func isCompletingFinalHabit() -> Bool {
        manager.completedCount == manager.totalEnabled - 1
    }

    // MARK: - Apple-Style Habit Rows (Clean, No Card Effects)

    func appleStyleHabitRow(for config: HabitConfig, layout: DynamicHabitLayout) -> some View {
        let completion = manager.getCompletion(for: config.habitType)
        let isCompleted = completion?.isCompleted ?? false
        let progress = holdProgress[config.habitType] ?? 0
        let isHoldType = isHoldToCompleteHabit(config.habitType)

        return Button {
            handleHabitTap(config)
        } label: {
            HStack(spacing: 12) {
                // Status indicator (left)
                appleStyleStatusIndicator(isCompleted: isCompleted, icon: config.habitType.icon)
                    .frame(width: 28, height: 28)

                // Info (middle)
                VStack(alignment: .leading, spacing: 2) {
                    Text(config.habitType.displayName)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(isCompleted ? MPColors.textSecondary : MPColors.textPrimary)

                    appleStyleSubtitle(for: config, completion: completion, isCompleted: isCompleted)
                }

                Spacer()

                // Action indicator (right)
                appleStyleTrailingContent(for: config, isCompleted: isCompleted, progress: progress, completion: completion)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .holdToComplete(
            isEnabled: isHoldType && !isCompleted,
            progress: Binding(
                get: { holdProgress[config.habitType] ?? 0 },
                set: { holdProgress[config.habitType] = $0 }
            ),
            holdDuration: 1.0,
            onCompleted: {
                completeHabitSimple(config.habitType)
            }
        )
    }

    func appleStyleCustomHabitRow(for customHabit: CustomHabit, layout: DynamicHabitLayout) -> some View {
        let completion = manager.getCustomCompletion(for: customHabit.id)
        let isCompleted = completion?.isCompleted ?? false
        let progress = customHoldProgress[customHabit.id] ?? 0
        let isHoldType = customHabit.verificationType == .honorSystem

        return Button {
            handleCustomHabitTap(customHabit)
        } label: {
            HStack(spacing: 12) {
                appleStyleStatusIndicator(isCompleted: isCompleted, icon: customHabit.icon)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(customHabit.name)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(isCompleted ? MPColors.textSecondary : MPColors.textPrimary)

                    appleStyleCustomSubtitle(for: customHabit, completion: completion, isCompleted: isCompleted)
                }

                Spacer()

                appleStyleCustomTrailingContent(for: customHabit, isCompleted: isCompleted, progress: progress)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .holdToComplete(
            isEnabled: isHoldType && !isCompleted,
            progress: Binding(
                get: { customHoldProgress[customHabit.id] ?? 0 },
                set: { customHoldProgress[customHabit.id] = $0 }
            ),
            holdDuration: 1.0,
            onCompleted: {
                completeCustomHabitSimple(customHabit.id)
            }
        )
    }

    // MARK: - Old Card-Style Habit Row (Keep for reference, will remove after testing)

    func habitRow(for config: HabitConfig, layout: DynamicHabitLayout) -> some View {
        let completion = manager.getCompletion(for: config.habitType)
        let isCompleted = completion?.isCompleted ?? false
        let justCompleted = recentlyCompletedHabits.contains(config.habitType)
        let isFlashing = habitRowFlash[config.habitType] ?? false
        let glowIntensity = habitRowGlow[config.habitType] ?? 0
        let progress = holdProgress[config.habitType] ?? 0
        let isHoldType = isHoldToCompleteHabit(config.habitType)

        return habitRowContent(
            config: config,
            completion: completion,
            isCompleted: isCompleted,
            progress: progress,
            layout: layout
        )
        .frame(height: layout.habitHeight)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
        // Enhanced glow shadow when completing
        .shadow(color: MPColors.success.opacity(glowIntensity), radius: 12, x: 0, y: 2)
        // Enhanced scale effect (1.05 instead of 1.03)
        .scaleEffect(justCompleted ? 1.05 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: justCompleted)
        .animation(.easeOut(duration: 0.15), value: isFlashing)
        .animation(.easeOut(duration: 0.3), value: glowIntensity)
        // Use UIKit-based hold gesture that properly coordinates with ScrollView
        .holdToComplete(
            isEnabled: isHoldType && !isCompleted,
            progress: Binding(
                get: { holdProgress[config.habitType] ?? 0 },
                set: { holdProgress[config.habitType] = $0 }
            ),
            holdDuration: 1.0,
            onCompleted: {
                completeHabitWithCelebration(config.habitType)
            }
        )
        .overlay(
            // Premium burst confetti overlay
            Group {
                if showConfettiForHabit == config.habitType {
                    HabitCompletionBurstView()
                        .allowsHitTesting(false)
                }
            }
        )
    }

    /// The visual content of a habit row (extracted for use with HoldToCompleteModifier)
    @ViewBuilder
    private func habitRowContent(
        config: HabitConfig,
        completion: HabitCompletion?,
        isCompleted: Bool,
        progress: CGFloat,
        layout: DynamicHabitLayout
    ) -> some View {
        let isFlashing = habitRowFlash[config.habitType] ?? false
        let iconSize = layout.habitIconSize
        let padding = layout.habitInternalPadding

        ZStack {
            // Base background
            RoundedRectangle(cornerRadius: MPRadius.lg)
                .fill(MPColors.surface)

            // Green fill progress overlay (fills from left to right, or full for completed)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: MPRadius.lg)
                    .fill(isCompleted ? MPColors.successLight : MPColors.success.opacity(0.25))
                    .frame(width: geo.size.width * (isCompleted ? 1.0 : progress))
            }

            HStack(spacing: MPSpacing.md) {
                // Icon with dark prominent background
                ZStack {
                    Circle()
                        .fill(isCompleted ? MPColors.success.opacity(0.2) : Color.white.opacity(0.12))
                        .frame(width: iconSize, height: iconSize)
                    Image(systemName: config.habitType.icon)
                        .font(.system(size: iconSize * 0.45, weight: .medium))
                        .foregroundColor(isCompleted ? MPColors.success : MPColors.textPrimary)
                }

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(config.habitType.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MPColors.textPrimary)

                    // Only show status text if there's meaningful info
                    statusText(for: config, completion: completion)
                }

                Spacer()

                // Action indicators (subtle, Apple-style)
                if !isCompleted {
                    if config.habitType == .madeBed || config.habitType == .sunlightExposure || config.habitType == .hydration ||
                       [.healthyBreakfast, .morningJournal, .vitamins, .skincare, .mealPrep].contains(config.habitType) {
                        // Camera shutter button - Apple style
                        Button {
                            switch config.habitType {
                            case .madeBed: showBedCamera = true
                            case .sunlightExposure: showSunlightCamera = true
                            case .hydration: showHydrationCamera = true
                            default: genericCameraHabitType = config.habitType
                            }
                        } label: {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(MPColors.primary)
                        }
                    } else if [.gratitude, .dailyPlanning].contains(config.habitType) {
                        // Journal icon - clean
                        Button {
                            textEntryHabitType = config.habitType
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(MPColors.primary)
                        }
                    } else if config.habitType == .sleepDuration {
                        if completion?.verificationData?.sleepHours == nil {
                            // No sleep data yet
                            EmptyView()
                        } else {
                            // Show edit button
                            Button {
                                showSleepInput = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(MPColors.textSecondary)
                            }
                        }
                    } else if config.habitType == .morningSteps {
                        let score = completion?.score ?? 0
                        PillProgressView(progress: CGFloat(score) / 100)
                    }
                } else {
                    // Checkmark for completed - more refined
                    ZStack {
                        Circle()
                            .fill(MPColors.success)
                            .frame(width: 28, height: 28)
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(padding + 2)

            // Flash overlay for completion celebration
            RoundedRectangle(cornerRadius: MPRadius.lg)
                .fill(MPColors.success.opacity(isFlashing ? 0.25 : 0))
        }
    }

    // MARK: - Custom Habit Row

    func customHabitRow(for customHabit: CustomHabit, layout: DynamicHabitLayout) -> some View {
        let completion = manager.getCustomCompletion(for: customHabit.id)
        let isCompleted = completion?.isCompleted ?? false
        let justCompleted = recentlyCompletedCustomHabits.contains(customHabit.id)
        let glowIntensity = customHabitRowGlow[customHabit.id] ?? 0
        let progress = customHoldProgress[customHabit.id] ?? 0
        let isHoldType = customHabit.verificationType == .honorSystem

        return customHabitRowContent(
            customHabit: customHabit,
            completion: completion,
            isCompleted: isCompleted,
            progress: progress,
            layout: layout
        )
        .frame(height: layout.habitHeight)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
        // Enhanced glow shadow when completing
        .shadow(color: MPColors.success.opacity(glowIntensity), radius: 12, x: 0, y: 2)
        // Enhanced scale effect (1.05 instead of 1.03)
        .scaleEffect(justCompleted ? 1.05 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: justCompleted)
        .animation(.easeOut(duration: 0.15), value: customHabitRowFlash[customHabit.id] ?? false)
        .animation(.easeOut(duration: 0.3), value: glowIntensity)
        // Use UIKit-based hold gesture that properly coordinates with ScrollView
        .holdToComplete(
            isEnabled: isHoldType && !isCompleted,
            progress: Binding(
                get: { customHoldProgress[customHabit.id] ?? 0 },
                set: { customHoldProgress[customHabit.id] = $0 }
            ),
            holdDuration: 1.0,
            onCompleted: {
                completeCustomHabitWithCelebration(customHabit.id)
            }
        )
        .overlay(
            // Premium burst confetti overlay
            Group {
                if showConfettiForCustomHabit == customHabit.id {
                    HabitCompletionBurstView()
                        .allowsHitTesting(false)
                }
            }
        )
    }

    /// The visual content of a custom habit row (extracted for use with HoldToCompleteModifier)
    @ViewBuilder
    private func customHabitRowContent(
        customHabit: CustomHabit,
        completion: CustomHabitCompletion?,
        isCompleted: Bool,
        progress: CGFloat,
        layout: DynamicHabitLayout
    ) -> some View {
        let isFlashing = customHabitRowFlash[customHabit.id] ?? false
        let iconSize = layout.habitIconSize
        let padding = layout.habitInternalPadding

        ZStack {
            // Base background
            RoundedRectangle(cornerRadius: MPRadius.lg)
                .fill(MPColors.surface)

            // Green fill progress overlay (fills from left to right, or full for completed)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: MPRadius.lg)
                    .fill(isCompleted ? MPColors.successLight : MPColors.success.opacity(0.25))
                    .frame(width: geo.size.width * (isCompleted ? 1.0 : progress))
            }

            HStack(spacing: MPSpacing.md) {
                // Icon with dark prominent background
                ZStack {
                    Circle()
                        .fill(isCompleted ? MPColors.success.opacity(0.2) : Color.white.opacity(0.12))
                        .frame(width: iconSize, height: iconSize)
                    Image(systemName: customHabit.icon)
                        .font(.system(size: iconSize * 0.5))
                        .foregroundColor(isCompleted ? MPColors.success : MPColors.textPrimary)
                }
                .frame(width: iconSize)

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(customHabit.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MPColors.textPrimary)

                    // Status text
                    customHabitStatusText(for: customHabit, completion: completion)
                }

                Spacer()

                // Camera/Record button for AI verified habits
                if !isCompleted && customHabit.verificationType == .aiVerified {
                    Button {
                        customHabitCameraTarget = customHabit
                    } label: {
                        Image(systemName: customHabit.mediaType == .video ? "record.circle.fill" : "circle.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(MPColors.primary)
                    }
                }

                // Checkmark indicator for completed habits
                if isCompleted {
                    let checkSize = iconSize * 0.7
                    ZStack {
                        Circle()
                            .fill(MPColors.success)
                            .frame(width: checkSize, height: checkSize)
                        Image(systemName: "checkmark")
                            .font(.system(size: checkSize * 0.5, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(padding)

            // Flash overlay for completion celebration
            RoundedRectangle(cornerRadius: MPRadius.lg)
                .fill(MPColors.success.opacity(isFlashing ? 0.25 : 0))
        }
    }

    @ViewBuilder
    func customHabitStatusText(for customHabit: CustomHabit, completion: CustomHabitCompletion?) -> some View {
        if let completion = completion, completion.isCompleted {
            Text(customHabit.verificationType == .aiVerified ? "Verified" : "Completed")
                .font(.system(size: 13))
                .foregroundColor(MPColors.textTertiary)
        } else if customHabit.verificationType == .aiVerified {
            Text("AI verified")
                .font(.system(size: 13))
                .foregroundColor(MPColors.textTertiary)
        } else {
            Text("Hold to complete")
                .font(.system(size: 13))
                .foregroundColor(MPColors.textTertiary)
        }
    }

    /// Formats the AI verification prompt into a user-friendly status text
    private func formatVerificationPrompt(_ prompt: String?) -> String {
        guard let prompt = prompt?.trimmingCharacters(in: .whitespaces), !prompt.isEmpty else {
            return "Take a photo"
        }

        var cleaned = prompt

        // Remove common AI-instruction prefixes to make it more user-facing
        let prefixesToRemove = [
            "make me show ",
            "make me ",
            "show me ",
            "show that ",
            "show ",
            "verify that ",
            "verify ",
            "check that ",
            "check if ",
            "check "
        ]

        let lowercased = cleaned.lowercased()
        for prefix in prefixesToRemove {
            if lowercased.hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count))
                break
            }
        }

        // Capitalize first letter
        if let first = cleaned.first {
            cleaned = first.uppercased() + cleaned.dropFirst()
        }

        // Truncate if too long
        if cleaned.count > 30 {
            cleaned = String(cleaned.prefix(27)) + "..."
        }

        return "Show: " + cleaned
    }

    // MARK: - Habit Completion Celebrations

    private func completeCustomHabitWithCelebration(_ habitId: UUID) {
        // Check if this is the final habit BEFORE completing
        let isFinalHabit = isCompletingFinalHabit()

        recentlyCompletedCustomHabits.insert(habitId)

        customHabitRowFlash[habitId] = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            customHabitRowFlash[habitId] = false
        }

        customHabitRowGlow[habitId] = 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            customHabitRowGlow[habitId] = 0
        }

        manager.completeCustomHabitHonorSystem(habitId)

        // Show appropriate celebration based on whether this is the final habit
        if isFinalHabit {
            // Grand Finale for final habit
            showGrandFinaleConfetti = true
            HapticManager.shared.success()

            // Clear grand finale after 2.5s
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                showGrandFinaleConfetti = false
            }
        } else {
            // Premium burst confetti for regular habits (haptic handled by burst view)
            showConfettiForCustomHabit = habitId

            // Clear confetti after burst animation (1.3s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                showConfettiForCustomHabit = nil
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            recentlyCompletedCustomHabits.remove(habitId)
        }
    }

    private func completeHabitWithCelebration(_ habitType: HabitType) {
        // Check if this is the final habit BEFORE completing
        let isFinalHabit = isCompletingFinalHabit()

        // Add to recently completed for scale animation
        recentlyCompletedHabits.insert(habitType)

        // Trigger flash effect
        habitRowFlash[habitType] = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            habitRowFlash[habitType] = false
        }

        // Trigger glow effect
        habitRowGlow[habitType] = 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            habitRowGlow[habitType] = 0
        }

        // Complete the habit (workout has special handling for manual completion)
        if habitType == .morningWorkout {
            manager.completeManualWorkout()
        } else {
            manager.completeHabit(habitType)
        }

        // Show appropriate celebration based on whether this is the final habit
        if isFinalHabit {
            // Grand Finale for final habit
            showGrandFinaleConfetti = true
            HapticManager.shared.success()

            // Clear grand finale after 2.5s
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                showGrandFinaleConfetti = false
            }
        } else {
            // Premium burst confetti for regular habits (haptic handled by burst view)
            showConfettiForHabit = habitType

            // Clear confetti after burst animation (1.3s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                showConfettiForHabit = nil
            }
        }

        // Remove from recently completed after animation settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            recentlyCompletedHabits.remove(habitType)
        }
    }

    @ViewBuilder
    func statusText(for config: HabitConfig, completion: HabitCompletion?) -> some View {
        if let completion = completion {
            switch config.habitType {
            case .morningSteps:
                let steps = completion.verificationData?.stepCount ?? 0
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(MPColors.healthRed)
                    Text("Health")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(MPColors.textTertiary)
                    Text("·")
                        .font(.system(size: 13))
                        .foregroundColor(MPColors.textTertiary.opacity(0.5))
                    Text("\(steps)/\(config.goal) steps")
                        .font(.system(size: 13))
                        .foregroundColor(MPColors.textTertiary)
                }

            case .sleepDuration:
                if let hours = completion.verificationData?.sleepHours {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(MPColors.healthRed)
                        Text("Health")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(MPColors.textTertiary)
                        Text("·")
                            .font(.system(size: 13))
                            .foregroundColor(MPColors.textTertiary.opacity(0.5))
                        Text("\(formatHours(hours))/\(config.goal)h sleep")
                            .font(.system(size: 13))
                            .foregroundColor(MPColors.textTertiary)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(MPColors.healthRed)
                        Text("Health")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(MPColors.textTertiary)
                    }
                }

            case .morningWorkout:
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(MPColors.healthRed)
                    Text("Health")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(completion.isCompleted ? MPColors.textSecondary : MPColors.textTertiary)
                    if completion.isCompleted {
                        Text("·")
                            .font(.system(size: 13))
                            .foregroundColor(MPColors.textSecondary.opacity(0.5))
                        Text("Verified")
                            .font(.system(size: 13))
                            .foregroundColor(MPColors.textSecondary)
                    }
                }

            case .madeBed, .sunlightExposure, .hydration, .healthyBreakfast, .morningJournal, .vitamins, .skincare, .mealPrep:
                if completion.isCompleted {
                    Text("Verified")
                        .font(.system(size: 13))
                        .foregroundColor(MPColors.textSecondary)
                } else {
                    Text("AI verified")
                        .font(.system(size: 13))
                        .foregroundColor(MPColors.textTertiary)
                }

            case .gratitude, .dailyPlanning:
                if completion.isCompleted {
                    Text("Logged")
                        .font(.system(size: 13))
                        .foregroundColor(MPColors.textSecondary)
                }

            default:
                if completion.isCompleted {
                    Text("Verified")
                        .font(.system(size: 13))
                        .foregroundColor(MPColors.textSecondary)
                }
            }
        }
    }

    /// Formats hours nicely: 8 instead of 8.0, but 8.5 stays 8.5
    private func formatHours(_ hours: Double) -> String {
        if hours == floor(hours) {
            return "\(Int(hours))h"
        } else {
            return String(format: "%.1fh", hours)
        }
    }

    // MARK: - Apple-Style Component Builders

    @ViewBuilder
    private func appleStyleStatusIndicator(isCompleted: Bool, icon: String) -> some View {
        if isCompleted {
            // Green checkmark for completed
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(MPColors.success)
                .symbolRenderingMode(.hierarchical)
        } else {
            // Neutral gray circle with icon for incomplete
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(MPColors.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func appleStyleSubtitle(for config: HabitConfig, completion: HabitCompletion?, isCompleted: Bool) -> some View {
        if let completion = completion {
            switch config.habitType {
            case .morningSteps:
                let steps = completion.verificationData?.stepCount ?? 0
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.pink.opacity(0.8))
                    Text("\(steps.formatted())/\(config.goal) steps")
                        .font(.system(size: 15))
                        .foregroundColor(MPColors.textTertiary)
                }

            case .sleepDuration:
                if let hours = completion.verificationData?.sleepHours {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.pink.opacity(0.8))
                        Text("\(formatHours(hours))/\(config.goal)h sleep")
                            .font(.system(size: 15))
                            .foregroundColor(MPColors.textTertiary)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.pink.opacity(0.8))
                        Text("Syncs from Health")
                            .font(.system(size: 15))
                            .foregroundColor(MPColors.textTertiary)
                    }
                }

            case .morningWorkout:
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.pink.opacity(0.8))
                    if isCompleted {
                        Text("Workout detected")
                            .font(.system(size: 15))
                            .foregroundColor(MPColors.textTertiary)
                    } else {
                        Text("Syncs from Health")
                            .font(.system(size: 15))
                            .foregroundColor(MPColors.textTertiary)
                    }
                }

            case .madeBed, .sunlightExposure, .hydration, .healthyBreakfast, .morningJournal, .vitamins, .skincare, .mealPrep:
                if isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(MPColors.success.opacity(0.8))
                        Text("AI verified")
                            .font(.system(size: 15))
                            .foregroundColor(MPColors.textTertiary)
                    }
                } else {
                    Text("Take photo to verify")
                        .font(.system(size: 15))
                        .foregroundColor(MPColors.textTertiary)
                }

            case .gratitude, .dailyPlanning:
                if isCompleted {
                    Text("Entry saved")
                        .font(.system(size: 15))
                        .foregroundColor(MPColors.textTertiary)
                } else {
                    Text("Tap to add entry")
                        .font(.system(size: 15))
                        .foregroundColor(MPColors.textTertiary)
                }

            default:
                if isCompleted {
                    // For honor system habits, checkmark is enough - no text needed
                    EmptyView()
                } else {
                    Text("Hold to complete")
                        .font(.system(size: 15))
                        .foregroundColor(MPColors.textTertiary)
                }
            }
        }
    }

    @ViewBuilder
    private func appleStyleCustomSubtitle(for habit: CustomHabit, completion: CustomHabitCompletion?, isCompleted: Bool) -> some View {
        if isCompleted {
            if habit.verificationType == .aiVerified {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(MPColors.success.opacity(0.8))
                    Text("AI verified")
                        .font(.system(size: 15))
                        .foregroundColor(MPColors.textTertiary)
                }
            }
        } else {
            switch habit.verificationType {
            case .aiVerified:
                Text("Take photo to verify")
                    .font(.system(size: 15))
                    .foregroundColor(MPColors.textTertiary)
            case .honorSystem:
                Text("Hold to complete")
                    .font(.system(size: 15))
                    .foregroundColor(MPColors.textTertiary)
            }
        }
    }

    @ViewBuilder
    private func appleStyleTrailingContent(for config: HabitConfig, isCompleted: Bool, progress: CGFloat, completion: HabitCompletion?) -> some View {
        if isCompleted {
            EmptyView()
        } else if config.habitType == .morningSteps {
            let score = completion?.score ?? 0
            appleStyleProgressRing(progress: CGFloat(score) / 100.0)
        } else if config.habitType.tier == .aiVerified {
            Image(systemName: "camera.fill")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(.systemGray3))
        } else if config.habitType.tier == .journaling {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(.systemGray3))
        } else if config.habitType.tier == .autoTracked {
            Image(systemName: "heart.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.pink.opacity(0.6))
        } else if progress > 0 {
            appleStyleProgressRing(progress: progress)
        } else {
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.systemGray4))
        }
    }

    @ViewBuilder
    private func appleStyleCustomTrailingContent(for habit: CustomHabit, isCompleted: Bool, progress: CGFloat) -> some View {
        if isCompleted {
            EmptyView()
        } else if habit.verificationType == .aiVerified {
            Image(systemName: "camera.fill")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(.systemGray3))
        } else if progress > 0 {
            appleStyleProgressRing(progress: progress)
        } else {
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.systemGray4))
        }
    }

    @ViewBuilder
    private func appleStyleProgressRing(progress: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 2)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(MPColors.accent, lineWidth: 2)
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 24, height: 24)
    }

    private func handleHabitTap(_ config: HabitConfig) {
        let completion = manager.getCompletion(for: config.habitType)
        guard !(completion?.isCompleted ?? false) else { return }

        switch config.habitType {
        case .madeBed:
            showBedCamera = true
        case .sunlightExposure:
            showSunlightCamera = true
        case .hydration:
            showHydrationCamera = true
        case .healthyBreakfast, .morningJournal, .vitamins, .skincare, .mealPrep:
            genericCameraHabitType = config.habitType
        case .gratitude, .dailyPlanning:
            textEntryHabitType = config.habitType
        case .sleepDuration:
            showSleepInput = true
        default:
            break
        }
    }

    private func handleCustomHabitTap(_ habit: CustomHabit) {
        let completion = manager.getCustomCompletion(for: habit.id)
        guard !(completion?.isCompleted ?? false) else { return }

        if habit.verificationType == .aiVerified {
            customHabitCameraTarget = habit
        }
    }

    /// Simplified completion - no per-habit effects, only global celebration when all complete
    private func completeHabitSimple(_ habitType: HabitType) {
        let wasLastHabit = isCompletingFinalHabit()

        manager.completeHabit(habitType)

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // If this was the final habit, trigger global celebration
        if wasLastHabit {
            showGrandFinaleConfetti = true

            // Clear confetti after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                showGrandFinaleConfetti = false
            }
        }
    }

    /// Simplified completion for custom habits
    private func completeCustomHabitSimple(_ habitId: UUID) {
        let wasLastHabit = isCompletingFinalHabit()

        manager.completeCustomHabitHonorSystem(habitId)

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // If this was the final habit, trigger global celebration
        if wasLastHabit {
            showGrandFinaleConfetti = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                showGrandFinaleConfetti = false
            }
        }
    }
}

// MARK: - Supporting Views

struct CircularProgressView: View {
    let progress: CGFloat
    let size: CGFloat
    let showPercentage: Bool

    init(progress: CGFloat, size: CGFloat, showPercentage: Bool = true) {
        self.progress = progress
        self.size = size
        self.showPercentage = showPercentage
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(MPColors.progressBg, lineWidth: 3)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(MPColors.success, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))

            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(MPColors.textSecondary)
            }
        }
        .frame(width: size, height: size)
    }
}

struct PillProgressView: View {
    let progress: CGFloat
    let width: CGFloat
    let height: CGFloat

    init(progress: CGFloat, width: CGFloat = 56, height: CGFloat = 8) {
        self.progress = progress
        self.width = width
        self.height = height
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Track
            Capsule()
                .fill(MPColors.progressBg)
                .frame(width: width, height: height)

            // Fill
            Capsule()
                .fill(MPColors.success)
                .frame(width: max(height, width * progress), height: height)  // min width = height for rounded ends
        }
    }
}

/// Apple Health badge with heart icon (always visible on auto-tracked habits)
/// Adapts colors based on completion state and color scheme for readability
private struct HealthBadge: View {
    var isCompleted: Bool = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "heart.fill")
                .font(.system(size: 8))
            Text("Health")
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(badgeForegroundColor)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(badgeBackgroundColor)
        .cornerRadius(4)
    }

    /// In light mode, keep red even when completed (green bg is light enough for contrast)
    /// In dark mode, switch to white when completed for readability
    private var badgeForegroundColor: Color {
        if isCompleted {
            return colorScheme == .light ? MPColors.healthRed : .white.opacity(0.9)
        } else {
            return MPColors.healthRed
        }
    }

    private var badgeBackgroundColor: Color {
        if isCompleted {
            return colorScheme == .light ? MPColors.healthRed.opacity(0.15) : Color.white.opacity(0.2)
        } else {
            return MPColors.healthRed.opacity(0.15)
        }
    }
}

#Preview {
    DashboardView(manager: MorningProofManager.shared)
}
