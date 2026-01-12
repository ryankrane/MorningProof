import SwiftUI

struct MainTabView: View {
    @ObservedObject var manager: MorningProofManager
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home = "Home"
        case calendar = "Calendar"
        case stats = "Progress"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .calendar: return "calendar"
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
    @State private var showBedCamera = false
    @State private var showSleepInput = false
    @State private var showHabitEditor = false

    // Celebration state
    @State private var recentlyCompletedHabits: Set<HabitType> = []
    @State private var showConfettiForHabit: HabitType? = nil
    @State private var showPerfectMorningCelebration = false

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
            .navigationTitle(greeting)
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showBedCamera) {
                BedCameraView(manager: manager)
            }
            .sheet(isPresented: $showSleepInput) {
                SleepInputSheet(manager: manager)
            }
            .sheet(isPresented: $showHabitEditor) {
                HabitEditorSheet(manager: manager)
            }
            .task {
                await manager.syncHealthData()
            }
            .onChange(of: manager.isPerfectMorning) { newValue in
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

                    statusText(for: config, completion: completion)
                }

                Spacer()

                actionButton(for: config, completion: completion, isCompleted: isCompleted)
            }
            .padding(MPSpacing.lg)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .mpShadow(.small)
            .scaleEffect(justCompleted ? 1.03 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: justCompleted)

            if showConfettiForHabit == config.habitType {
                MiniConfettiView()
                    .allowsHitTesting(false)
            }
        }
    }

    private func completeHabitWithCelebration(_ habitType: HabitType) {
        recentlyCompletedHabits.insert(habitType)
        showConfettiForHabit = habitType
        HapticManager.shared.habitCompleted()
        manager.completeHabit(habitType)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showConfettiForHabit = nil
        }

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
                    let score = completion?.score ?? 0
                    CircularProgressView(progress: CGFloat(score) / 100, size: MPButtonHeight.sm)
                }

            case .morningSteps, .morningWorkout:
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

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MPSpacing.xl) {
                    // Hero: Streak + Week visualization
                    ProgressHeroCard(manager: manager)

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
