import SwiftUI

struct DashboardView: View {
    @ObservedObject var manager: MorningProofManager
    @State private var showSettings = false
    @State private var showBedCamera = false
    @State private var showSunlightCamera = false
    @State private var showHydrationCamera = false
    @State private var showSleepInput = false
    @State private var showHabitEditor = false
    @State private var holdProgress: [HabitType: CGFloat] = [:]

    // Custom habit states
    @State private var customHabitCameraTarget: CustomHabit? = nil
    @State private var customHoldProgress: [UUID: CGFloat] = [:]
    @State private var recentlyCompletedCustomHabits: Set<UUID> = []
    @State private var customHabitRowFlash: [UUID: Bool] = [:]
    @State private var customHabitRowGlow: [UUID: CGFloat] = [:]
    @State private var showConfettiForCustomHabit: UUID? = nil

    // Side menu state
    @State private var showSideMenu = false
    @State private var selectedMenuItem: SideMenuItem?
    @State private var showHistory = false
    @State private var showCalendar = false
    @State private var showAchievements = false
    @State private var showStatistics = false

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

    // Undo state for honor system habits
    @State private var undoableHabit: HabitType? = nil
    @State private var undoableCustomHabit: UUID? = nil
    @State private var undoWorkItem: DispatchWorkItem? = nil

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

                // Undo toast for honor system habits
                VStack {
                    Spacer()
                    if let habitType = undoableHabit {
                        UndoToastView(
                            habitName: habitType.displayName,
                            onUndo: {
                                manager.undoHabitCompletion(habitType)
                                undoableHabit = nil
                                undoWorkItem?.cancel()
                            },
                            onDismiss: {
                                undoableHabit = nil
                                undoWorkItem?.cancel()
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, MPSpacing.xl)
                    } else if let customId = undoableCustomHabit,
                              let habit = manager.getCustomHabit(id: customId) {
                        UndoToastView(
                            habitName: habit.name,
                            onUndo: {
                                manager.undoCustomHabitCompletion(customId)
                                undoableCustomHabit = nil
                                undoWorkItem?.cancel()
                            },
                            onDismiss: {
                                undoableCustomHabit = nil
                                undoWorkItem?.cancel()
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, MPSpacing.xl)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: undoableHabit)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: undoableCustomHabit)

                // Side menu overlay
                SideMenuView(
                    manager: manager,
                    isShowing: $showSideMenu,
                    selectedItem: $selectedMenuItem,
                    onDismiss: { showSideMenu = false },
                    onSelectSettings: { showSettings = true }
                )
            }
        }
        .onChange(of: selectedMenuItem) { _, item in
            guard let item = item else { return }
            switch item {
            case .history:
                showHistory = true
            case .calendar:
                showCalendar = true
            case .achievements:
                showAchievements = true
            case .statistics:
                showStatistics = true
            default:
                break
            }
            // Reset selection after handling
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                selectedMenuItem = nil
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
        .sheet(isPresented: $showHistory) {
            HistoryView(manager: manager)
        }
        .sheet(isPresented: $showCalendar) {
            CalendarView(manager: manager)
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
                .environmentObject(BedVerificationViewModel())
        }
        .sheet(isPresented: $showStatistics) {
            StatisticsView(manager: manager)
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
                impactShake: $streakShakeOffset
            )

            // Habits List
            habitsSection(layout: layout)

            // Add spacer at the bottom if scrolling
            if layout.needsScrolling {
                Spacer(minLength: MPSpacing.xxxl)
            }
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

            MPIconButton(icon: "line.3.horizontal", size: MPIconSize.md) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showSideMenu = true
                }
            }
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

    // MARK: - Habits Section

    @ViewBuilder
    func habitsSection(layout: DynamicHabitLayout) -> some View {
        VStack(alignment: .leading, spacing: layout.habitRowSpacing) {
            // Section header with edit button
            HStack {
                Text("Today's Habits")
                    .font(MPFont.headingSmall())
                    .foregroundColor(MPColors.textPrimary)

                Spacer()

                Button {
                    showHabitEditor = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(MPColors.primary)
                }
            }
            .padding(.leading, MPSpacing.xs)

            // All habits sorted by verification type:
            // 1. AI Verified (camera) - both predefined and custom
            // 2. Auto-Tracked (Apple Health)
            // 3. Honor System (hold to complete) - both predefined and custom

            // AI Verified predefined habits
            ForEach(manager.enabledHabits.filter { $0.habitType.tier == .aiVerified }) { config in
                habitRow(for: config, layout: layout)
            }

            // AI Verified custom habits
            ForEach(manager.enabledCustomHabits.filter { $0.verificationType == .aiVerified }) { customHabit in
                customHabitRow(for: customHabit, layout: layout)
            }

            // Auto-Tracked (Apple Health) habits
            ForEach(manager.enabledHabits.filter { $0.habitType.tier == .autoTracked }) { config in
                habitRow(for: config, layout: layout)
            }

            // Honor System predefined habits
            ForEach(manager.enabledHabits.filter { $0.habitType.tier == .honorSystem }) { config in
                habitRow(for: config, layout: layout)
            }

            // Honor System custom habits
            ForEach(manager.enabledCustomHabits.filter { $0.verificationType == .honorSystem }) { customHabit in
                customHabitRow(for: customHabit, layout: layout)
            }

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

    /// Determines if a habit is a "hold to complete" type (not a special input type)
    /// Only habits with special input UIs (camera, sheets, auto-progress) are excluded
    private func isHoldToCompleteHabit(_ habitType: HabitType) -> Bool {
        // These habits have special input types and don't use hold-to-complete:
        // - madeBed, sunlightExposure, hydration: camera verification
        // - sleepDuration: sleep input sheet
        // - morningSteps: auto-tracked with circular progress
        // Everything else uses hold-to-complete for manual confirmation
        let specialInputHabits: Set<HabitType> = [.madeBed, .sleepDuration, .morningSteps, .sunlightExposure, .hydration]
        return !specialInputHabits.contains(habitType)
    }

    /// Returns true if completing this habit would complete ALL habits (final habit)
    private func isCompletingFinalHabit() -> Bool {
        manager.completedCount == manager.totalEnabled - 1
    }

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
        // Use ButtonStyle-based hold for hold-type habits (doesn't block scroll)
        .modifier(HoldToCompleteModifier(
            isEnabled: isHoldType && !isCompleted,
            progress: Binding(
                get: { holdProgress[config.habitType] ?? 0 },
                set: { holdProgress[config.habitType] = $0 }
            ),
            onCompleted: {
                completeHabitWithCelebration(config.habitType)
            }
        ))
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

            HStack(spacing: MPSpacing.lg) {
                // Icon with circular background
                ZStack {
                    Circle()
                        .fill(isCompleted ? MPColors.success.opacity(0.15) : MPColors.surfaceSecondary)
                        .frame(width: iconSize, height: iconSize)
                    Image(systemName: config.habitType.icon)
                        .font(.system(size: iconSize * 0.5))
                        .foregroundColor(isCompleted ? MPColors.success : MPColors.textSecondary)
                }
                .frame(width: iconSize)

                // Info
                VStack(alignment: .leading, spacing: MPSpacing.xs) {
                    Text(config.habitType.displayName)
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.textPrimary)

                    // Status text
                    statusText(for: config, completion: completion)
                }

                Spacer()

                // Action buttons (only for special types that need them, when not completed)
                if !isCompleted && config.habitType == .madeBed {
                    Button {
                        showBedCamera = true
                    } label: {
                        Image(systemName: "camera.fill")
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(width: MPButtonHeight.sm, height: MPButtonHeight.sm)
                            .background(MPColors.primary)
                            .cornerRadius(MPRadius.sm)
                    }
                } else if !isCompleted && config.habitType == .sunlightExposure {
                    Button {
                        showSunlightCamera = true
                    } label: {
                        Image(systemName: "camera.fill")
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(width: MPButtonHeight.sm, height: MPButtonHeight.sm)
                            .background(MPColors.primary)
                            .cornerRadius(MPRadius.sm)
                    }
                } else if !isCompleted && config.habitType == .hydration {
                    Button {
                        showHydrationCamera = true
                    } label: {
                        Image(systemName: "camera.fill")
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(width: MPButtonHeight.sm, height: MPButtonHeight.sm)
                            .background(MPColors.primary)
                            .cornerRadius(MPRadius.sm)
                    }
                } else if !isCompleted && config.habitType == .sleepDuration {
                    if completion?.verificationData?.sleepHours == nil {
                        Button {
                            showSleepInput = true
                        } label: {
                            Text("Enter")
                                .font(MPFont.labelSmall())
                                .foregroundColor(MPColors.primary)
                                .padding(.horizontal, MPSpacing.md)
                                .padding(.vertical, MPSpacing.sm)
                                .background(MPColors.surfaceSecondary)
                                .cornerRadius(MPRadius.sm)
                        }
                    } else {
                        HStack(spacing: MPSpacing.sm) {
                            let score = completion?.score ?? 0
                            CircularProgressView(progress: CGFloat(score) / 100, size: MPButtonHeight.sm)

                            // Edit button to allow manual override
                            Button {
                                showSleepInput = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12))
                                    .foregroundColor(MPColors.textTertiary)
                            }
                        }
                    }
                } else if !isCompleted && config.habitType == .morningSteps {
                    let score = completion?.score ?? 0
                    PillProgressView(progress: CGFloat(score) / 100)
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
        // Use ButtonStyle-based hold for hold-type habits (doesn't block scroll)
        .modifier(HoldToCompleteModifier(
            isEnabled: isHoldType && !isCompleted,
            progress: Binding(
                get: { customHoldProgress[customHabit.id] ?? 0 },
                set: { customHoldProgress[customHabit.id] = $0 }
            ),
            onCompleted: {
                completeCustomHabitWithCelebration(customHabit.id)
            }
        ))
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

            HStack(spacing: MPSpacing.lg) {
                // Icon with circular background
                ZStack {
                    Circle()
                        .fill(isCompleted ? MPColors.success.opacity(0.15) : MPColors.surfaceSecondary)
                        .frame(width: iconSize, height: iconSize)
                    Image(systemName: customHabit.icon)
                        .font(.system(size: iconSize * 0.5))
                        .foregroundColor(isCompleted ? MPColors.success : MPColors.textSecondary)
                }
                .frame(width: iconSize)

                // Info
                VStack(alignment: .leading, spacing: MPSpacing.xs) {
                    Text(customHabit.name)
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.textPrimary)

                    // Status text
                    customHabitStatusText(for: customHabit, completion: completion)
                }

                Spacer()

                // Camera button for AI verified habits
                if !isCompleted && customHabit.verificationType == .aiVerified {
                    Button {
                        customHabitCameraTarget = customHabit
                    } label: {
                        Image(systemName: "camera.fill")
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(width: MPButtonHeight.sm, height: MPButtonHeight.sm)
                            .background(MPColors.primary)
                            .cornerRadius(MPRadius.sm)
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
            if wasCustomHabitCompletedLate(completion) {
                Text(customHabit.verificationType == .aiVerified ? "Verified Late" : "Completed Late")
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.warning)
            } else {
                Text(customHabit.verificationType == .aiVerified ? "Verified" : "Completed")
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.success)
            }
        } else if manager.isPastCutoff && manager.hasCustomHabitEverBeenCompleted(customHabit.id) {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.circle.fill")
                Text("LATE")
            }
            .font(MPFont.bodySmall())
            .foregroundColor(MPColors.error)
        } else if customHabit.verificationType == .aiVerified {
            Text(formatVerificationPrompt(customHabit.aiPrompt))
                .font(MPFont.bodySmall())
                .foregroundColor(MPColors.textTertiary)
                .lineLimit(1)
        } else {
            Text("Hold to complete")
                .font(MPFont.bodySmall())
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

        // Check if this is an honor system habit (only honor system custom habits use this function)
        let isHonorSystem = manager.getCustomHabit(id: habitId)?.verificationType == .honorSystem

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

        // Show undo toast for honor system habits (not for final habit)
        if isHonorSystem && !isFinalHabit {
            showUndoToast(for: habitId)
        }
    }

    /// Shows undo toast for custom habit and auto-dismisses after 5 seconds
    private func showUndoToast(for customHabitId: UUID) {
        // Cancel any existing undo work item
        undoWorkItem?.cancel()
        undoableHabit = nil

        // Show undo toast
        undoableCustomHabit = customHabitId

        // Auto-dismiss after 5 seconds
        let workItem = DispatchWorkItem { [self] in
            undoableCustomHabit = nil
        }
        undoWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: workItem)
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

        // Show undo toast for honor system habits (not for auto-tracked or final habit)
        if habitType.tier == .honorSystem && !isFinalHabit {
            showUndoToast(for: habitType)
        }
    }

    /// Shows undo toast for predefined habit and auto-dismisses after 5 seconds
    private func showUndoToast(for habitType: HabitType) {
        // Cancel any existing undo work item
        undoWorkItem?.cancel()
        undoableCustomHabit = nil

        // Show undo toast
        undoableHabit = habitType

        // Auto-dismiss after 5 seconds
        let workItem = DispatchWorkItem { [self] in
            undoableHabit = nil
        }
        undoWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: workItem)
    }

    /// Returns true if the habit was completed after the cutoff time
    private func wasCompletedLate(_ completion: HabitCompletion) -> Bool {
        guard let completedAt = completion.completedAt else { return false }
        return completedAt > manager.cutoffTime
    }

    /// Returns true if the custom habit was completed after the cutoff time
    private func wasCustomHabitCompletedLate(_ completion: CustomHabitCompletion) -> Bool {
        guard let completedAt = completion.completedAt else { return false }
        return completedAt > manager.cutoffTime
    }

    @ViewBuilder
    func statusText(for config: HabitConfig, completion: HabitCompletion?) -> some View {
        if let completion = completion {
            switch config.habitType {
            case .morningSteps:
                let steps = completion.verificationData?.stepCount ?? 0
                if completion.isCompleted {
                    if wasCompletedLate(completion) {
                        HStack(spacing: MPSpacing.xs) {
                            Text("\(steps)/\(config.goal) steps")
                            Text("Late")
                        }
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.warning)
                    } else {
                        Text("\(steps)/\(config.goal) steps")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textTertiary)
                    }
                } else if manager.isPastCutoff && manager.hasHabitEverBeenCompleted(config.habitType) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text("LATE - \(steps)/\(config.goal)")
                    }
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.error)
                } else {
                    Text("\(steps)/\(config.goal) steps")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }

            case .sleepDuration:
                if let hours = completion.verificationData?.sleepHours {
                    let isFromHealth = completion.verificationData?.isFromHealthKit == true
                    if completion.isCompleted && wasCompletedLate(completion) {
                        HStack(spacing: MPSpacing.xs) {
                            Text("\(formatHours(hours))/\(config.goal)h sleep")
                            Text("Late")
                            if isFromHealth {
                                Text("from Health")
                                    .font(.system(size: 10))
                                    .foregroundColor(MPColors.warning.opacity(0.7))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(MPColors.surfaceSecondary)
                                    .cornerRadius(4)
                            }
                        }
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.warning)
                    } else {
                        HStack(spacing: MPSpacing.xs) {
                            Text("\(formatHours(hours))/\(config.goal)h sleep")
                                .font(MPFont.bodySmall())
                                .foregroundColor(completion.isCompleted ? MPColors.success : MPColors.textTertiary)
                            if isFromHealth {
                                Text("from Health")
                                    .font(.system(size: 10))
                                    .foregroundColor(completion.isCompleted ? MPColors.success.opacity(0.7) : MPColors.textTertiary.opacity(0.7))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(MPColors.surfaceSecondary)
                                    .cornerRadius(4)
                            }
                        }
                    }
                } else if manager.isPastCutoff && manager.hasHabitEverBeenCompleted(config.habitType) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text("LATE")
                    }
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.error)
                } else {
                    Text("Tap to enter sleep")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }

            case .morningWorkout:
                if completion.isCompleted {
                    let isFromHealth = completion.verificationData?.workoutDetected == true
                    if wasCompletedLate(completion) {
                        HStack(spacing: MPSpacing.xs) {
                            Text("Completed Late")
                                .font(MPFont.bodySmall())
                                .foregroundColor(MPColors.warning)
                            if isFromHealth {
                                Text("from Health")
                                    .font(.system(size: 10))
                                    .foregroundColor(MPColors.warning.opacity(0.7))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(MPColors.surfaceSecondary)
                                    .cornerRadius(4)
                            }
                        }
                    } else {
                        HStack(spacing: MPSpacing.xs) {
                            Text("Completed")
                                .font(MPFont.bodySmall())
                                .foregroundColor(MPColors.success)
                            if isFromHealth {
                                Text("from Health")
                                    .font(.system(size: 10))
                                    .foregroundColor(MPColors.textTertiary.opacity(0.7))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(MPColors.surfaceSecondary)
                                    .cornerRadius(4)
                            }
                        }
                    }
                } else if manager.isPastCutoff && manager.hasHabitEverBeenCompleted(config.habitType) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text("LATE")
                    }
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.error)
                } else {
                    Text("Hold to complete")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }

            case .madeBed:
                if completion.isCompleted {
                    if wasCompletedLate(completion) {
                        Text("Verified Late")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.warning)
                    } else {
                        Text("Verified")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.success)
                    }
                } else if manager.isPastCutoff && manager.hasHabitEverBeenCompleted(config.habitType) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text("LATE")
                    }
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.error)
                } else {
                    Text("Take a photo to verify")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }

            case .sunlightExposure:
                if completion.isCompleted {
                    if wasCompletedLate(completion) {
                        Text("Verified Late")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.warning)
                    } else {
                        Text("Verified")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.success)
                    }
                } else if manager.isPastCutoff && manager.hasHabitEverBeenCompleted(config.habitType) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text("LATE")
                    }
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.error)
                } else {
                    Text("Take a photo outside")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }

            case .hydration:
                if completion.isCompleted {
                    if wasCompletedLate(completion) {
                        Text("Verified Late")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.warning)
                    } else {
                        Text("Verified")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.success)
                    }
                } else if manager.isPastCutoff && manager.hasHabitEverBeenCompleted(config.habitType) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text("LATE")
                    }
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.error)
                } else {
                    Text("Take a photo of your water")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }

            default:
                if completion.isCompleted {
                    if wasCompletedLate(completion) {
                        Text("Completed Late")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.warning)
                    } else {
                        Text("Completed")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.success)
                    }
                } else if manager.isPastCutoff && manager.hasHabitEverBeenCompleted(config.habitType) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text("LATE")
                    }
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.error)
                } else {
                    Text("Hold to complete")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
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
}

// MARK: - Supporting Views

struct CircularProgressView: View {
    let progress: CGFloat
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(MPColors.progressBg, lineWidth: 3)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(MPColors.success, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))%")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(MPColors.textSecondary)
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

#Preview {
    DashboardView(manager: MorningProofManager.shared)
}
