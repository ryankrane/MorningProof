import SwiftUI

struct DashboardView: View {
    @ObservedObject var manager: MorningProofManager
    @State private var showSettings = false
    @State private var showBedCamera = false
    @State private var showJournalEntry = false
    @State private var holdProgress: [HabitType: CGFloat] = [:]

    // Celebration state
    @State private var recentlyCompletedHabits: Set<HabitType> = []
    @State private var showConfettiForHabit: HabitType? = nil
    @State private var showPerfectMorningCelebration = false
    @State private var previousCompletedCount = 0

    var body: some View {
        ZStack {
            // Background
            MPColors.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: MPSpacing.xl) {
                    // Header
                    headerSection

                    // Streak Hero Card
                    StreakHeroCard(
                        currentStreak: manager.currentStreak,
                        completedToday: manager.completedCount,
                        totalHabits: manager.totalEnabled,
                        isPerfectMorning: manager.isPerfectMorning
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

            // Perfect Morning celebration overlay
            if showPerfectMorningCelebration {
                FullScreenConfettiView(isShowing: $showPerfectMorningCelebration)
            }
        }
        .sheet(isPresented: $showSettings) {
            MorningProofSettingsView(manager: manager)
        }
        .sheet(isPresented: $showBedCamera) {
            BedCameraView(manager: manager)
        }
        .sheet(isPresented: $showJournalEntry) {
            JournalEntryView(manager: manager)
        }
        .task {
            await manager.syncHealthData()
            previousCompletedCount = manager.completedCount
        }
        .onChange(of: manager.isPerfectMorning) { newValue in
            if newValue && !showPerfectMorningCelebration {
                triggerPerfectMorningCelebration()
            }
        }
    }

    private func triggerPerfectMorningCelebration() {
        showPerfectMorningCelebration = true
        HapticManager.shared.perfectMorning()
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

            MPIconButton(icon: "gearshape.fill", size: MPIconSize.md) {
                showSettings = true
            }
        }
        .padding(.top, MPSpacing.sm)
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = manager.settings.userName.isEmpty ? "" : ", \(manager.settings.userName)"

        switch hour {
        case 5..<12:
            return "Good morning\(name)"
        case 12..<17:
            return "Good afternoon\(name)"
        case 17..<21:
            return "Good evening\(name)"
        default:
            return "Hello\(name)"
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
            return "\(hours)h \(minutes)m until \(manager.settings.morningCutoffHour):00 AM cutoff"
        } else {
            return "\(minutes)m until \(manager.settings.morningCutoffHour):00 AM cutoff"
        }
    }

    // MARK: - Habits Section

    var habitsSection: some View {
        VStack(spacing: MPSpacing.md) {
            // Group by tier
            ForEach(HabitVerificationTier.allCases, id: \.rawValue) { tier in
                let habitsInTier = manager.enabledHabits.filter { $0.habitType.tier == tier }

                if !habitsInTier.isEmpty {
                    VStack(alignment: .leading, spacing: MPSpacing.sm) {
                        Text(tier.description)
                            .font(MPFont.labelSmall())
                            .foregroundColor(MPColors.textTertiary)
                            .padding(.leading, MPSpacing.xs)

                        ForEach(habitsInTier) { config in
                            habitRow(for: config)
                        }
                    }
                }
            }
        }
    }

    func habitRow(for config: HabitConfig) -> some View {
        let completion = manager.getCompletion(for: config.habitType)
        let isCompleted = completion?.isCompleted ?? false
        let justCompleted = recentlyCompletedHabits.contains(config.habitType)

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
            .mpShadow(.small)
            .scaleEffect(justCompleted ? 1.03 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: justCompleted)

            // Mini confetti overlay
            if showConfettiForHabit == config.habitType {
                MiniConfettiView()
                    .allowsHitTesting(false)
            }
        }
    }

    private func completeHabitWithCelebration(_ habitType: HabitType) {
        // Add to recently completed
        recentlyCompletedHabits.insert(habitType)

        // Show confetti
        showConfettiForHabit = habitType

        // Haptic feedback
        HapticManager.shared.habitCompleted()

        // Complete the habit
        manager.completeHabit(habitType)

        // Clear confetti after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
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
                } else if config.habitType.requiresHoldToConfirm {
                    Text("Hold to confirm")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
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

            case .journaling:
                Button {
                    showJournalEntry = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(width: MPButtonHeight.sm, height: MPButtonHeight.sm)
                        .background(MPColors.primary)
                        .cornerRadius(MPRadius.sm)
                }

            case .sleepDuration:
                if completion?.verificationData?.sleepHours == nil {
                    Button {
                        // Show manual sleep entry
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

                        withAnimation(.linear(duration: 2.0)) {
                            progress = 1.0
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            if isHolding {
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
