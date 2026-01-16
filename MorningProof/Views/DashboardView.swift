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
    @State private var isHoldingHabit: HabitType? = nil
    @State private var holdStartTime: [HabitType: Date] = [:]
    @State private var holdTimers: [HabitType: Timer] = [:]

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
    @State private var previousCompletedCount = 0
    @State private var previouslyCompletedHabits: Set<HabitType> = []

    // Enhanced animation state
    @State private var habitRowFlash: [HabitType: Bool] = [:]
    @State private var habitRowGlow: [HabitType: CGFloat] = [:]
    @State private var triggerStreakPulse = false

    // Lock-in button position tracking
    @State private var lockButtonFrame: CGRect = .zero
    @State private var streakFlameFrame: CGRect = .zero

    var body: some View {
        ZStack {
            // Background
            MPColors.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: MPSpacing.xl) {
                    // Header
                    headerSection

                    // Streak Hero Card with flame position tracking
                    StreakHeroCard(
                        currentStreak: manager.currentStreak,
                        completedToday: manager.completedCount,
                        totalHabits: manager.totalEnabled,
                        isPerfectMorning: manager.isPerfectMorning,
                        timeUntilCutoff: manager.isPastCutoff ? nil : manager.timeUntilCutoff,
                        cutoffTimeFormatted: manager.settings.cutoffTimeFormatted,
                        triggerPulse: $triggerStreakPulse,
                        flameFrame: $streakFlameFrame
                    )

                    // Habits List
                    habitsSection

                    Spacer(minLength: MPSpacing.xxxl)
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.top, MPSpacing.sm)
            }
            .refreshable {
                await manager.syncHealthData()
            }

            // Lock-in celebration overlay (when user locks in their day)
            if showLockInCelebration {
                LockInCelebrationView(
                    isShowing: $showLockInCelebration,
                    buttonPosition: lockButtonFrame.origin,
                    streakFlamePosition: streakFlameFrame.origin,
                    onFlameArrived: {
                        // Trigger StreakHeroCard pulse when flame arrives
                        triggerStreakPulse = true
                    }
                )
            }

            // Side menu overlay
            SideMenuView(
                manager: manager,
                isShowing: $showSideMenu,
                selectedItem: $selectedMenuItem,
                onDismiss: { showSideMenu = false },
                onSelectSettings: { showSettings = true }
            )
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
        .task {
            // Track which habits were completed before sync
            previouslyCompletedHabits = Set(manager.todayLog.completions.filter { $0.isCompleted }.map { $0.habitType })
            previousCompletedCount = manager.completedCount

            await manager.syncHealthData()

            // Check for newly auto-completed habits after sync
            checkForNewlyCompletedHabits()
        }
    }

    private func triggerLockInCelebration() {
        manager.lockInDay()
        showLockInCelebration = true
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

        // Show confetti
        showConfettiForHabit = habitType

        // Enhanced haptic feedback
        HapticManager.shared.habitCompletedEnhanced()

        // Clear confetti after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
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

    var habitsSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
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

            // All habits in a single unified list
            ForEach(manager.enabledHabits) { config in
                habitRow(for: config)
            }

            // Lock In Day Button
            HStack {
                Spacer()
                LockInDayButton(
                    isEnabled: manager.canLockInDay,
                    isLockedIn: manager.todayLog.isDayLockedIn,
                    onLockIn: {
                        triggerLockInCelebration()
                    }
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
            .padding(.top, MPSpacing.lg)
        }
    }

    /// Determines if a habit is a "hold to complete" type (not a special input type)
    private func isHoldToCompleteHabit(_ habitType: HabitType) -> Bool {
        habitType != .madeBed && habitType != .sleepDuration && habitType != .morningSteps && habitType != .morningWorkout && habitType != .sunlightExposure && habitType != .hydration
    }

    func habitRow(for config: HabitConfig) -> some View {
        let completion = manager.getCompletion(for: config.habitType)
        let isCompleted = completion?.isCompleted ?? false
        let justCompleted = recentlyCompletedHabits.contains(config.habitType)
        let isFlashing = habitRowFlash[config.habitType] ?? false
        let glowIntensity = habitRowGlow[config.habitType] ?? 0
        let progress = holdProgress[config.habitType] ?? 0
        let isHoldType = isHoldToCompleteHabit(config.habitType)

        return ZStack {
            // Base background
            RoundedRectangle(cornerRadius: MPRadius.lg)
                .fill(MPColors.surface)

            // Green fill progress overlay (fills from left to right, or full for completed)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: MPRadius.lg)
                    .fill(isCompleted ? MPColors.success.opacity(0.4) : MPColors.success.opacity(0.3))
                    .frame(width: geo.size.width * (isCompleted ? 1.0 : progress))
            }

            HStack(spacing: MPSpacing.lg) {
                // Icon (no circle background)
                Image(systemName: config.habitType.icon)
                    .font(.system(size: MPIconSize.md))
                    .foregroundColor(isCompleted ? MPColors.success : MPColors.textSecondary)
                    .frame(width: 32)

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
                            .background(MPColors.accentGold)
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
                    CircularProgressView(progress: CGFloat(score) / 100, size: MPButtonHeight.sm)
                } else if !isCompleted && config.habitType == .morningWorkout {
                    // Workout: show mark complete button if not auto-detected
                    Button {
                        HapticManager.shared.success()
                        completeHabitWithCelebration(.morningWorkout)
                        manager.completeManualWorkout()
                    } label: {
                        Text("Mark Complete")
                            .font(MPFont.labelSmall())
                            .foregroundColor(MPColors.primary)
                            .padding(.horizontal, MPSpacing.md)
                            .padding(.vertical, MPSpacing.sm)
                            .background(MPColors.surfaceSecondary)
                            .cornerRadius(MPRadius.sm)
                    }
                }
                // No indicator for hold-to-complete habits or completed habits - the green fill is the indicator
            }
            .padding(MPSpacing.lg)

            // Flash overlay for completion celebration
            RoundedRectangle(cornerRadius: MPRadius.lg)
                .fill(MPColors.success.opacity(isFlashing ? 0.25 : 0))
        }
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
        // Enhanced glow shadow when completing
        .shadow(color: MPColors.success.opacity(glowIntensity), radius: 12, x: 0, y: 2)
        // Enhanced scale effect (1.05 instead of 1.03)
        .scaleEffect(justCompleted ? 1.05 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: justCompleted)
        .animation(.easeOut(duration: 0.15), value: isFlashing)
        .animation(.easeOut(duration: 0.3), value: glowIntensity)
        // Make entire row tappable for hold-to-complete habits
        .contentShape(Rectangle())
        .gesture(
            isHoldType && !isCompleted ?
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if isHoldingHabit != config.habitType {
                        startHabitHold(config.habitType)
                    }
                }
                .onEnded { _ in
                    endHabitHold(config.habitType, isCompleted: isCompleted)
                }
            : nil
        )
        .overlay(
            // Mini confetti overlay
            Group {
                if showConfettiForHabit == config.habitType {
                    MiniConfettiView()
                        .allowsHitTesting(false)
                }
            }
        )
    }

    private func completeHabitWithCelebration(_ habitType: HabitType) {
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

        // Show confetti
        showConfettiForHabit = habitType

        // Enhanced haptic feedback
        HapticManager.shared.habitCompletedEnhanced()

        // Complete the habit
        manager.completeHabit(habitType)

        // Clear confetti after animation (longer for enhanced confetti)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showConfettiForHabit = nil
        }

        // Remove from recently completed after animation settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            recentlyCompletedHabits.remove(habitType)
        }
    }

    // MARK: - Habit Hold Gesture Handling

    private let habitHoldDuration: Double = 1.0

    private func startHabitHold(_ habitType: HabitType) {
        isHoldingHabit = habitType
        holdProgress[habitType] = 0
        holdStartTime[habitType] = Date()

        // Initial haptic feedback
        HapticManager.shared.lightTap()

        // Animate progress
        withAnimation(.linear(duration: habitHoldDuration)) {
            holdProgress[habitType] = 1.0
        }

        // Start timer for haptic ticks and completion check
        let tickInterval = 0.1
        let timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [self] t in
            guard isHoldingHabit == habitType, let startTime = holdStartTime[habitType] else {
                t.invalidate()
                holdTimers[habitType] = nil
                return
            }

            let elapsed = Date().timeIntervalSince(startTime)

            // Haptic tick every ~0.2s
            if Int(elapsed / 0.2) > Int((elapsed - tickInterval) / 0.2) {
                HapticManager.shared.lightTap()
            }

            // Check if hold duration is complete
            if elapsed >= habitHoldDuration {
                t.invalidate()
                holdTimers[habitType] = nil
                completeHabitHold(habitType)
            }
        }
        holdTimers[habitType] = timer
    }

    private func endHabitHold(_ habitType: HabitType, isCompleted: Bool) {
        // Cancel the timer
        holdTimers[habitType]?.invalidate()
        holdTimers[habitType] = nil

        guard isHoldingHabit == habitType else { return }

        // Check if hold was long enough
        if let startTime = holdStartTime[habitType] {
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= habitHoldDuration {
                completeHabitHold(habitType)
                return
            }
        }

        // Not long enough - cancel with haptic and animate back
        cancelHabitHold(habitType)
    }

    private func completeHabitHold(_ habitType: HabitType) {
        guard isHoldingHabit == habitType else { return }

        isHoldingHabit = nil
        holdStartTime[habitType] = nil
        holdProgress[habitType] = 0

        // Complete the habit with celebration
        completeHabitWithCelebration(habitType)
    }

    private func cancelHabitHold(_ habitType: HabitType) {
        isHoldingHabit = nil
        holdStartTime[habitType] = nil

        // Animate progress back to 0
        let currentProgress = holdProgress[habitType] ?? 0
        let unwindDuration = Double(currentProgress) * 0.5 + 0.15
        withAnimation(.easeOut(duration: unwindDuration)) {
            holdProgress[habitType] = 0
        }

        // Haptic feedback on cancel
        HapticManager.shared.lightTap()
    }

    @ViewBuilder
    func statusText(for config: HabitConfig, completion: HabitCompletion?) -> some View {
        if let completion = completion {
            switch config.habitType {
            case .morningSteps:
                let steps = completion.verificationData?.stepCount ?? 0
                Text("\(steps)/\(config.goal) steps")
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.textTertiary)

            case .sleepDuration:
                if let hours = completion.verificationData?.sleepHours {
                    let isFromHealth = completion.verificationData?.isFromHealthKit == true
                    HStack(spacing: MPSpacing.xs) {
                        Text(String(format: "%.1f/\(config.goal)h sleep", hours))
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textTertiary)
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
                } else {
                    Text("Tap to enter sleep")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }

            case .morningWorkout:
                if completion.isCompleted {
                    let isFromHealth = completion.verificationData?.workoutDetected == true
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
                } else {
                    Text("Tap to mark complete")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }

            case .madeBed:
                if completion.isCompleted {
                    Text("Verified")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.success)
                } else {
                    Text("Take a photo to verify")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }

            case .sunlightExposure:
                if completion.isCompleted {
                    Text("Verified")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.success)
                } else {
                    Text("Take a photo outside")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }

            case .hydration:
                if completion.isCompleted {
                    Text("Verified")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.success)
                } else {
                    Text("Take a photo of your water")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }

            default:
                if completion.isCompleted {
                    Text("Completed")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.success)
                } else {
                    Text("Hold to complete")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }
            }
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

#Preview {
    DashboardView(manager: MorningProofManager.shared)
}
