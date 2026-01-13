import SwiftUI

struct DashboardView: View {
    @ObservedObject var manager: MorningProofManager
    @State private var showSettings = false
    @State private var showBedCamera = false
    @State private var showSleepInput = false
    @State private var showHabitEditor = false
    @State private var holdProgress: [HabitType: CGFloat] = [:]

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
                        triggerPulse: $triggerStreakPulse,
                        flameFrame: $streakFlameFrame
                    )

                    // Countdown
                    if !manager.isPastCutoff {
                        countdownBanner
                    }

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
            // Only celebrate auto-tracked habits here (steps and sleep)
            if habitType == .morningSteps || habitType == .sleepDuration {
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

    // MARK: - Countdown Banner

    var countdownBanner: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundColor(MPColors.accent)

            Text(countdownText)
                .font(MPFont.labelMedium())
                .foregroundColor(MPColors.textPrimary)

            Spacer()
        }
        .padding(MPSpacing.lg)
        .background(MPColors.surfaceHighlight)
        .cornerRadius(MPRadius.md)
    }

    var countdownText: String {
        let interval = manager.timeUntilCutoff
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m until \(manager.settings.cutoffTimeFormatted) cutoff"
        } else {
            return "\(minutes)m until \(manager.settings.cutoffTimeFormatted) cutoff"
        }
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

    func habitRow(for config: HabitConfig) -> some View {
        let completion = manager.getCompletion(for: config.habitType)
        let isCompleted = completion?.isCompleted ?? false
        let justCompleted = recentlyCompletedHabits.contains(config.habitType)
        let isFlashing = habitRowFlash[config.habitType] ?? false
        let glowIntensity = habitRowGlow[config.habitType] ?? 0

        return ZStack {
            HStack(spacing: MPSpacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isCompleted ? MPColors.successLight : MPColors.surfaceSecondary)
                        .frame(width: 44, height: 44)

                    Image(systemName: config.habitType.icon)
                        .font(.system(size: MPIconSize.sm))
                        .foregroundColor(isCompleted ? MPColors.success : MPColors.textTertiary)
                }

                // Info
                VStack(alignment: .leading, spacing: MPSpacing.xs) {
                    Text(config.habitType.displayName)
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.textPrimary)

                    // Status text
                    statusText(for: config, completion: completion)
                }

                Spacer()

                // Action / Status
                actionButton(for: config, completion: completion, isCompleted: isCompleted)
            }
            .padding(MPSpacing.lg)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            // Flash overlay for completion celebration
            .overlay(
                RoundedRectangle(cornerRadius: MPRadius.lg)
                    .fill(MPColors.success.opacity(isFlashing ? 0.25 : 0))
            )
            .mpShadow(.small)
            // Enhanced glow shadow when completing
            .shadow(color: MPColors.success.opacity(glowIntensity), radius: 12, x: 0, y: 2)
            // Enhanced scale effect (1.05 instead of 1.03)
            .scaleEffect(justCompleted ? 1.05 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.55), value: justCompleted)
            .animation(.easeOut(duration: 0.15), value: isFlashing)
            .animation(.easeOut(duration: 0.3), value: glowIntensity)

            // Mini confetti overlay
            if showConfettiForHabit == config.habitType {
                MiniConfettiView()
                    .allowsHitTesting(false)
            }
        }
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
                    Text(String(format: "%.1f/\(config.goal)h sleep", hours))
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                } else {
                    Text("Tap to enter sleep")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }

            case .madeBed:
                if completion.isCompleted, let score = completion.verificationData?.aiScore {
                    Text("Score: \(score)/10")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                } else {
                    Text("Take a photo to verify")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }

            default:
                if completion.isCompleted {
                    Text("Completed")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.success)
                } else {
                    Text("Tap to complete")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }
            }
        }
    }

    @ViewBuilder
    func actionButton(for config: HabitConfig, completion: HabitCompletion?, isCompleted: Bool) -> some View {
        if isCompleted {
            CheckmarkCircle(isCompleted: true, size: 28)
        } else {
            switch config.habitType {
            case .madeBed:
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

            case .sleepDuration:
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
                    // Show progress
                    let score = completion?.score ?? 0
                    CircularProgressView(progress: CGFloat(score) / 100, size: MPButtonHeight.sm)
                }

            case .morningSteps:
                // Show progress
                let score = completion?.score ?? 0
                CircularProgressView(progress: CGFloat(score) / 100, size: MPButtonHeight.sm)

            default:
                if config.habitType.requiresHoldToConfirm {
                    HoldToConfirmButton(habitType: config.habitType) {
                        completeHabitWithCelebration(config.habitType)
                    }
                } else {
                    Button {
                        completeHabitWithCelebration(config.habitType)
                    } label: {
                        Circle()
                            .stroke(MPColors.border, lineWidth: 2)
                            .frame(width: 28, height: 28)
                    }
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

struct HoldToConfirmButton: View {
    let habitType: HabitType
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var isHolding = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(MPColors.border, lineWidth: 2)
                .frame(width: MPButtonHeight.sm, height: MPButtonHeight.sm)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(MPColors.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: MPButtonHeight.sm, height: MPButtonHeight.sm)
                .rotationEffect(.degrees(-90))
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isHolding {
                        isHolding = true
                        HapticManager.shared.lightTap()

                        withAnimation(.linear(duration: 1.0)) {
                            progress = 1.0
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            if isHolding {
                                HapticManager.shared.success()
                                onComplete()
                            }
                        }
                    }
                }
                .onEnded { _ in
                    isHolding = false
                    if progress < 1.0 {
                        withAnimation(.easeOut(duration: 0.2)) {
                            progress = 0
                        }
                        HapticManager.shared.lightTap()
                    }
                }
        )
    }
}

#Preview {
    DashboardView(manager: MorningProofManager.shared)
}
