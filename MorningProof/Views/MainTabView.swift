import SwiftUI

struct MainTabView: View {
    @ObservedObject var manager: MorningProofManager
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home = "Home"
        case routine = "Routine"
        case stats = "Progress"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .routine: return "sunrise.fill"
            case .stats: return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardContentView(manager: manager)
                .tabItem {
                    Label(Tab.home.rawValue, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)

            RoutineTabView(manager: manager)
                .tabItem {
                    Label(Tab.routine.rawValue, systemImage: Tab.routine.icon)
                }
                .tag(Tab.routine)

            StatsTabView(manager: manager)
                .tabItem {
                    Label(Tab.stats.rawValue, systemImage: Tab.stats.icon)
                }
                .tag(Tab.stats)

            SettingsTabView(manager: manager)
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
        .tint(MPColors.primary)
    }
}

// MARK: - Home Tab (Main Dashboard Content)
struct DashboardContentView: View {
    @ObservedObject var manager: MorningProofManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var showBedCamera = false
    @State private var showSunlightCamera = false
    @State private var showHydrationCamera = false
    @State private var showSleepInput = false

    // Hold-to-complete state (progress tracked for UI, logic handled by HoldToCompleteModifier)
    @State private var holdProgress: [HabitType: CGFloat] = [:]
    private let habitHoldDuration: Double = 1.0

    // Celebration state
    @State private var recentlyCompletedHabits: Set<HabitType> = []
    @State private var showConfettiForHabit: HabitType? = nil
    @State private var showPerfectMorningCelebration = false
    @State private var triggerStreakPulse = false
    @State private var flameFrame: CGRect = .zero
    @State private var showLockInCelebration = false
    @State private var habitRowFlash: [HabitType: Bool] = [:]
    @State private var habitRowGlow: [HabitType: CGFloat] = [:]

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: MPSpacing.xl) {
                        // Streak Hero Card
                        StreakHeroCard(
                            currentStreak: manager.currentStreak,
                            completedToday: manager.completedCount,
                            totalHabits: manager.totalEnabled,
                            isPerfectMorning: manager.isPerfectMorning,
                            timeUntilCutoff: manager.isPastCutoff ? nil : manager.timeUntilCutoff,
                            cutoffTimeFormatted: manager.settings.cutoffTimeFormatted,
                            hasOverdueHabits: manager.hasOverdueHabits,
                            triggerPulse: $triggerStreakPulse,
                            flameFrame: $flameFrame
                        )

                        // Habits List
                        habitsSection

                        Spacer(minLength: MPSpacing.xxxl)
                    }
                    .padding(.horizontal, MPSpacing.xl)
                    .padding(.top, MPSpacing.sm)
                }
                // Perfect Morning celebration overlay
                if showPerfectMorningCelebration {
                    FullScreenConfettiView(isShowing: $showPerfectMorningCelebration)
                }

                // Lock-in celebration overlay
                if showLockInCelebration {
                    LockInCelebrationView(
                        isShowing: $showLockInCelebration,
                        buttonPosition: CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 200),
                        streakFlamePosition: CGPoint(x: flameFrame.midX, y: flameFrame.midY),
                        onFlameArrived: {
                            triggerStreakPulse = true
                        }
                    )
                }
            }
            .navigationTitle(greeting)
            .navigationBarTitleDisplayMode(.large)
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
            .task {
                await manager.syncHealthData()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        await manager.syncHealthData()
                    }
                }
            }
            .onChange(of: manager.isPerfectMorning) { _, newValue in
                if newValue && !showPerfectMorningCelebration {
                    showPerfectMorningCelebration = true
                    HapticManager.shared.perfectMorning()
                }
            }
        }
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

    // MARK: - Habits Section

    var habitsSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            // Section header
            Text("Today's Habits")
                .font(MPFont.headingSmall())
                .foregroundColor(MPColors.textPrimary)
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
                Spacer()
            }
            .padding(.top, MPSpacing.lg)
        }
    }

    private func triggerLockInCelebration() {
        manager.lockInDay()
        showLockInCelebration = true
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

                    statusText(for: config, completion: completion)
                }

                Spacer()

                actionButton(for: config, completion: completion, isCompleted: isCompleted)
            }
            .padding(MPSpacing.lg)

            // Flash overlay for completion celebration
            RoundedRectangle(cornerRadius: MPRadius.lg)
                .fill(MPColors.success.opacity(isFlashing ? 0.25 : 0))

            if showConfettiForHabit == config.habitType {
                MiniConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
        // Enhanced glow shadow when completing
        .shadow(color: MPColors.success.opacity(glowIntensity), radius: 12, x: 0, y: 2)
        // Enhanced scale effect
        .scaleEffect(justCompleted ? 1.05 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: justCompleted)
        .animation(.easeOut(duration: 0.15), value: isFlashing)
        .animation(.easeOut(duration: 0.3), value: glowIntensity)
        // Make entire row tappable for hold-to-complete habits
        .contentShape(Rectangle())
        // UIKit-based hold gesture that properly coordinates with ScrollView
        // Uses UILongPressGestureRecognizer with cancelsTouchesInView=false
        // and shouldRequireFailureOf for pan gestures to give scrolling priority
        .holdToComplete(
            isEnabled: isHoldType && !isCompleted,
            progress: Binding(
                get: { holdProgress[config.habitType] ?? 0 },
                set: { holdProgress[config.habitType] = $0 }
            ),
            holdDuration: habitHoldDuration,
            onCompleted: {
                completeHabitWithCelebration(config.habitType)
            }
        )
    }

    // MARK: - Habit Completion Celebration

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

        // Complete the habit (workout has special handling for manual completion)
        if habitType == .morningWorkout {
            manager.completeManualWorkout()
        } else {
            manager.completeHabit(habitType)
        }

        // Clear confetti after animation
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

            case .morningWorkout:
                if completion.isCompleted {
                    Text("Completed")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.success)
                } else {
                    Text("Hold to complete")
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

            case .sunlightExposure:
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

            case .hydration:
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
                    let score = completion?.score ?? 0
                    CircularProgressView(progress: CGFloat(score) / 100, size: MPButtonHeight.sm)
                }

            case .morningSteps:
                let score = completion?.score ?? 0
                CircularProgressView(progress: CGFloat(score) / 100, size: MPButtonHeight.sm)

            default:
                // Hold-to-complete habits don't need an action button
                // The green fill serves as the indicator
                EmptyView()
            }
        }
    }
}

// MARK: - Calendar Tab
struct CalendarTabView: View {
    @ObservedObject var manager: MorningProofManager
    @State private var selectedMonth = Date()
    @State private var selectedDate: Date?

    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: MPSpacing.xl) {
                        // Month navigation
                        HStack {
                            Button {
                                withAnimation {
                                    selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                                    .foregroundColor(MPColors.primary)
                            }

                            Spacer()

                            Text(monthYearString)
                                .font(MPFont.headingSmall())
                                .foregroundColor(MPColors.textPrimary)

                            Spacer()

                            Button {
                                withAnimation {
                                    selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.title3)
                                    .foregroundColor(MPColors.primary)
                            }
                        }
                        .padding(.horizontal, MPSpacing.md)

                        // Day headers
                        HStack(spacing: 0) {
                            ForEach(daysOfWeek, id: \.self) { day in
                                Text(day)
                                    .font(MPFont.labelSmall())
                                    .foregroundColor(MPColors.textTertiary)
                                    .frame(maxWidth: .infinity)
                            }
                        }

                        // Calendar grid
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: MPSpacing.sm) {
                            ForEach(daysInMonth, id: \.self) { date in
                                if let date = date {
                                    CalendarDayCell(
                                        date: date,
                                        isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
                                        log: manager.getDailyLog(for: date),
                                        enabledCount: manager.totalEnabled
                                    ) {
                                        withAnimation {
                                            selectedDate = date
                                        }
                                    }
                                } else {
                                    Color.clear
                                        .aspectRatio(1, contentMode: .fit)
                                }
                            }
                        }

                        // Selected date details
                        if let date = selectedDate, let log = manager.getDailyLog(for: date) {
                            VStack(alignment: .leading, spacing: MPSpacing.md) {
                                Text(dateString(for: date))
                                    .font(MPFont.labelMedium())
                                    .foregroundColor(MPColors.textPrimary)

                                HStack(spacing: MPSpacing.lg) {
                                    VStack {
                                        Text("\(log.completions.filter { $0.isCompleted }.count)")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(MPColors.success)
                                        Text("Completed")
                                            .font(MPFont.bodySmall())
                                            .foregroundColor(MPColors.textTertiary)
                                    }

                                    VStack {
                                        Text("\(log.morningScore)%")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(MPColors.primary)
                                        Text("Score")
                                            .font(MPFont.bodySmall())
                                            .foregroundColor(MPColors.textTertiary)
                                    }

                                    if log.allCompletedBeforeCutoff {
                                        VStack {
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.yellow)
                                            Text("Perfect")
                                                .font(MPFont.bodySmall())
                                                .foregroundColor(MPColors.textTertiary)
                                        }
                                    }
                                }
                            }
                            .padding(MPSpacing.lg)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(MPColors.surface)
                            .cornerRadius(MPRadius.lg)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, MPSpacing.xl)
                    .padding(.top, MPSpacing.lg)
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var days: [Date?] = []
        var currentDate = monthFirstWeek.start

        while currentDate < monthInterval.end || days.count % 7 != 0 {
            if currentDate >= monthInterval.start && currentDate < monthInterval.end {
                days.append(currentDate)
            } else {
                days.append(nil)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return days
    }

    func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
}

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let log: DailyLog?
    let enabledCount: Int
    let onTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .aspectRatio(1, contentMode: .fit)

                VStack(spacing: 2) {
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 14, weight: isToday ? .bold : .medium))
                        .foregroundColor(textColor)

                    if let log = log, log.completions.contains(where: { $0.isCompleted }) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    var isToday: Bool {
        calendar.isDateInToday(date)
    }

    var backgroundColor: Color {
        if isSelected {
            return MPColors.primary
        } else if isToday {
            return MPColors.primary.opacity(0.2)
        }
        return Color.clear
    }

    var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return MPColors.primary
        }
        return MPColors.textPrimary
    }

    var statusColor: Color {
        guard let log = log else { return Color.clear }
        let completed = log.completions.filter { $0.isCompleted }.count

        if log.allCompletedBeforeCutoff {
            return .yellow
        } else if completed == enabledCount {
            return MPColors.success
        } else if completed > 0 {
            return MPColors.accent
        }
        return Color.clear
    }
}

// MARK: - Stats Tab
struct StatsTabView: View {
    @ObservedObject var manager: MorningProofManager
    @State private var showAchievements = false

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MPSpacing.xl) {
                    // This Week section with trend
                    VStack(alignment: .leading, spacing: MPSpacing.md) {
                        HStack {
                            Text("This Week")
                                .font(MPFont.headingSmall())
                                .foregroundColor(MPColors.textPrimary)

                            Spacer()

                            TrendIndicator(
                                thisWeekRate: calculateThisWeekRate(),
                                lastWeekRate: calculateLastWeekRate()
                            )
                        }

                        ProgressHeroCard(manager: manager)
                    }

                    // Records: Best Streak + Perfect Days
                    RecordsCard(
                        bestStreak: manager.longestStreak,
                        perfectDays: manager.settings.totalPerfectMornings
                    )

                    // Habit Breakdown (last 30 days)
                    HabitBreakdownCard(manager: manager)

                    // Achievements Link
                    Button {
                        showAchievements = true
                    } label: {
                        HStack {
                            Image(systemName: "medal.fill")
                                .foregroundColor(.yellow)
                            Text("View Achievements")
                                .font(MPFont.labelMedium())
                                .foregroundColor(MPColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(MPColors.textTertiary)
                        }
                        .padding(MPSpacing.lg)
                        .background(MPColors.surface)
                        .cornerRadius(MPRadius.lg)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.top, MPSpacing.lg)
                .padding(.bottom, MPSpacing.xxxl)
            }
            .background(MPColors.background)
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAchievements) {
                AchievementsView()
                    .environmentObject(BedVerificationViewModel())
            }
        }
    }

    // MARK: - Stats Calculations

    private func calculateThisWeekRate() -> Double {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        guard let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) else {
            return 0
        }

        var completed = 0
        var total = 0

        // Only count days up to and including today
        for dayOffset in 0..<weekday {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else { continue }
            if let log = manager.getDailyLog(for: date) {
                let dayCompleted = log.completions.filter { $0.isCompleted }.count
                let dayTotal = log.completions.count
                completed += dayCompleted
                total += dayTotal
            }
        }

        return total > 0 ? Double(completed) / Double(total) * 100 : 0
    }

    private func calculateLastWeekRate() -> Double {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        guard let startOfThisWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today),
              let startOfLastWeek = calendar.date(byAdding: .day, value: -7, to: startOfThisWeek) else {
            return 0
        }

        var completed = 0
        var total = 0

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfLastWeek) else { continue }
            if let log = manager.getDailyLog(for: date) {
                let dayCompleted = log.completions.filter { $0.isCompleted }.count
                let dayTotal = log.completions.count
                completed += dayCompleted
                total += dayTotal
            }
        }

        return total > 0 ? Double(completed) / Double(total) * 100 : 0
    }

    private func calculatePerfectDaysThisWeek() -> Int {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        guard let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) else {
            return 0
        }

        var perfectDays = 0

        for dayOffset in 0..<weekday {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else { continue }
            if let log = manager.getDailyLog(for: date) {
                let completed = log.completions.filter { $0.isCompleted }.count
                let total = log.completions.count
                if completed == total && total > 0 {
                    perfectDays += 1
                }
            }
        }

        return perfectDays
    }
}

// MARK: - Settings Tab
struct SettingsTabView: View {
    @ObservedObject var manager: MorningProofManager

    var body: some View {
        NavigationStack {
            MorningProofSettingsView(manager: manager)
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Habit Editor Sheet
struct HabitEditorSheet: View {
    @ObservedObject var manager: MorningProofManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: MPSpacing.md) {
                        ForEach(HabitType.allCases) { habitType in
                            habitToggleRow(habitType)
                        }
                    }
                    .padding(MPSpacing.xl)
                }
            }
            .navigationTitle("Edit Habits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(MPColors.primary)
                }
            }
        }
    }

    func habitToggleRow(_ habitType: HabitType) -> some View {
        let config = manager.habitConfigs.first { $0.habitType == habitType }
        let isEnabled = config?.isEnabled ?? false

        return Button {
            manager.updateHabitConfig(habitType, isEnabled: !isEnabled)
        } label: {
            HStack(spacing: MPSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(isEnabled ? MPColors.successLight : MPColors.surfaceSecondary)
                        .frame(width: 44, height: 44)

                    Image(systemName: habitType.icon)
                        .font(.system(size: MPIconSize.sm))
                        .foregroundColor(isEnabled ? MPColors.success : MPColors.textTertiary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(habitType.displayName)
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.textPrimary)

                    Text(habitType.tier.description)
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }

                Spacer()

                Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isEnabled ? MPColors.success : MPColors.border)
            }
            .padding(MPSpacing.lg)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView(manager: MorningProofManager.shared)
}
