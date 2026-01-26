import SwiftUI

struct MainTabView: View {
    @ObservedObject var manager: MorningProofManager
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home = "Home"
        case stats = "Progress"
        case routine = "Routine"
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
            DashboardView(manager: manager)
                .tabItem {
                    Label(Tab.home.rawValue, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)

            StatsTabView(manager: manager)
                .tabItem {
                    Label(Tab.stats.rawValue, systemImage: Tab.stats.icon)
                }
                .tag(Tab.stats)

            RoutineTabView(manager: manager)
                .tabItem {
                    Label(Tab.routine.rawValue, systemImage: Tab.routine.icon)
                }
                .tag(Tab.routine)

            SettingsTabView(manager: manager)
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
        .tint(MPColors.primary)
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
}

// MARK: - Settings Tab
struct SettingsTabView: View {
    @ObservedObject var manager: MorningProofManager

    var body: some View {
        NavigationStack {
            MorningProofSettingsView(manager: manager)
        }
    }
}

// MARK: - Habit Editor Sheet
struct HabitEditorSheet: View {
    @ObservedObject var manager: MorningProofManager
    @Environment(\.dismiss) var dismiss
    @State private var showCreateCustomHabit = false

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: MPSpacing.xl) {
                        // MARK: - Predefined Habits Section
                        VStack(alignment: .leading, spacing: MPSpacing.md) {
                            Text("MORNING HABITS")
                                .font(MPFont.labelSmall())
                                .foregroundColor(MPColors.textTertiary)
                                .padding(.horizontal, MPSpacing.sm)

                            VStack(spacing: MPSpacing.md) {
                                ForEach(HabitType.allCases) { habitType in
                                    habitToggleRow(habitType)
                                }
                            }
                        }

                        // MARK: - Custom Habits Section
                        VStack(alignment: .leading, spacing: MPSpacing.md) {
                            Text("CUSTOM HABITS")
                                .font(MPFont.labelSmall())
                                .foregroundColor(MPColors.textTertiary)
                                .padding(.horizontal, MPSpacing.sm)

                            VStack(spacing: MPSpacing.md) {
                                ForEach(manager.customHabits.filter { $0.isActive }) { habit in
                                    customHabitToggleRow(habit)
                                }

                                // Add Custom Habit Button
                                Button {
                                    showCreateCustomHabit = true
                                } label: {
                                    HStack(spacing: MPSpacing.lg) {
                                        ZStack {
                                            Circle()
                                                .fill(MPColors.primaryLight)
                                                .frame(width: 44, height: 44)

                                            Image(systemName: "plus")
                                                .font(.system(size: MPIconSize.sm, weight: .medium))
                                                .foregroundColor(MPColors.primary)
                                        }

                                        Text("Add Custom Habit")
                                            .font(MPFont.labelMedium())
                                            .foregroundColor(MPColors.primary)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(MPColors.textTertiary)
                                    }
                                    .padding(MPSpacing.lg)
                                    .background(MPColors.surface)
                                    .cornerRadius(MPRadius.lg)
                                }
                                .buttonStyle(.plain)
                            }
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
            .sheet(isPresented: $showCreateCustomHabit) {
                CustomHabitCreationSheet(manager: manager)
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

    func customHabitToggleRow(_ habit: CustomHabit) -> some View {
        let config = manager.customHabitConfigs.first { $0.customHabitId == habit.id }
        let isEnabled = config?.isEnabled ?? false

        return Button {
            manager.toggleCustomHabit(habit.id, isEnabled: !isEnabled)
        } label: {
            HStack(spacing: MPSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(isEnabled ? MPColors.successLight : MPColors.surfaceSecondary)
                        .frame(width: 44, height: 44)

                    Image(systemName: habit.icon)
                        .font(.system(size: MPIconSize.sm))
                        .foregroundColor(isEnabled ? MPColors.success : MPColors.textTertiary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.textPrimary)

                    Text(habit.verificationType.displayName)
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
