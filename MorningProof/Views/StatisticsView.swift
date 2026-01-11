import SwiftUI

struct StatisticsView: View {
    @ObservedObject var manager: MorningProofManager
    @Environment(\.dismiss) var dismiss

    private let calendar = Calendar.current

    // Calculate stats for last 30 days
    private var last30Days: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<30).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
    }

    private var completionStats: (perfect: Int, partial: Int, missed: Int) {
        var perfect = 0
        var partial = 0
        var missed = 0

        for date in last30Days {
            if let log = manager.getDailyLog(for: date) {
                let completed = log.completions.filter { $0.isCompleted }.count
                let total = log.completions.count

                if total > 0 {
                    if completed == total {
                        perfect += 1
                    } else if completed > 0 {
                        partial += 1
                    } else {
                        missed += 1
                    }
                }
            }
        }

        return (perfect, partial, missed)
    }

    private var overallCompletionRate: Double {
        var totalCompleted = 0
        var totalHabits = 0

        for date in last30Days {
            if let log = manager.getDailyLog(for: date) {
                totalCompleted += log.completions.filter { $0.isCompleted }.count
                totalHabits += log.completions.count
            }
        }

        guard totalHabits > 0 else { return 0 }
        return Double(totalCompleted) / Double(totalHabits) * 100
    }

    private var weeklyData: [Int] {
        // Last 7 days completion counts
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
            let log = manager.getDailyLog(for: date)
            return log?.completions.filter { $0.isCompleted }.count ?? 0
        }.reversed()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: MPSpacing.xl) {
                        // Overall completion rate
                        overallRateCard

                        // Streak info
                        streakCard

                        // Last 30 days summary
                        monthSummaryCard

                        // Weekly chart
                        weeklyChartCard

                        // Per-habit stats
                        habitStatsCard
                    }
                    .padding(.horizontal, MPSpacing.xl)
                    .padding(.top, MPSpacing.lg)
                    .padding(.bottom, MPSpacing.xxxl)
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(MPColors.primary)
                }
            }
        }
    }

    var overallRateCard: some View {
        VStack(spacing: MPSpacing.lg) {
            Text("Completion Rate")
                .font(MPFont.labelMedium())
                .foregroundColor(MPColors.textTertiary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(overallCompletionRate))")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(completionRateColor)

                Text("%")
                    .font(MPFont.headingMedium())
                    .foregroundColor(MPColors.textTertiary)
            }

            Text("Last 30 days")
                .font(MPFont.bodySmall())
                .foregroundColor(MPColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MPSpacing.xxl)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.xl)
        .mpShadow(.medium)
    }

    var completionRateColor: Color {
        if overallCompletionRate >= 80 {
            return MPColors.success
        } else if overallCompletionRate >= 50 {
            return MPColors.warning
        } else {
            return MPColors.error
        }
    }

    var streakCard: some View {
        HStack(spacing: MPSpacing.xl) {
            VStack(spacing: MPSpacing.sm) {
                HStack(spacing: MPSpacing.xs) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(MPColors.accent)
                    Text("\(manager.currentStreak)")
                        .font(MPFont.displaySmall())
                        .foregroundColor(MPColors.textPrimary)
                }
                Text("Current")
                    .font(MPFont.labelSmall())
                    .foregroundColor(MPColors.textTertiary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 50)

            VStack(spacing: MPSpacing.sm) {
                HStack(spacing: MPSpacing.xs) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(MPColors.accentGold)
                    Text("\(manager.longestStreak)")
                        .font(MPFont.displaySmall())
                        .foregroundColor(MPColors.textPrimary)
                }
                Text("Best")
                    .font(MPFont.labelSmall())
                    .foregroundColor(MPColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(MPSpacing.xl)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
    }

    var monthSummaryCard: some View {
        VStack(alignment: .leading, spacing: MPSpacing.lg) {
            Text("Last 30 Days")
                .font(MPFont.labelMedium())
                .foregroundColor(MPColors.textPrimary)

            HStack(spacing: MPSpacing.md) {
                statBadge(value: completionStats.perfect, label: "Perfect", color: MPColors.success)
                statBadge(value: completionStats.partial, label: "Partial", color: MPColors.warning)
                statBadge(value: completionStats.missed, label: "Missed", color: MPColors.error)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MPSpacing.lg)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
    }

    func statBadge(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: MPSpacing.xs) {
            Text("\(value)")
                .font(MPFont.headingSmall())
                .foregroundColor(color)

            Text(label)
                .font(MPFont.labelTiny())
                .foregroundColor(MPColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MPSpacing.md)
        .background(color.opacity(0.1))
        .cornerRadius(MPRadius.md)
    }

    var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: MPSpacing.lg) {
            Text("This Week")
                .font(MPFont.labelMedium())
                .foregroundColor(MPColors.textPrimary)

            HStack(alignment: .bottom, spacing: MPSpacing.sm) {
                ForEach(Array(weeklyData.enumerated()), id: \.offset) { index, count in
                    VStack(spacing: MPSpacing.xs) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor(for: count))
                            .frame(width: 30, height: max(8, CGFloat(count) * 12))

                        Text(dayLabel(for: 6 - index))
                            .font(MPFont.labelTiny())
                            .foregroundColor(MPColors.textTertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(MPSpacing.lg)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
    }

    func barColor(for count: Int) -> Color {
        if count >= manager.enabledHabits.count {
            return MPColors.success
        } else if count > 0 {
            return MPColors.warning
        } else {
            return MPColors.progressBg
        }
    }

    func dayLabel(for daysAgo: Int) -> String {
        if daysAgo == 0 { return "Today" }
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    var habitStatsCard: some View {
        VStack(alignment: .leading, spacing: MPSpacing.lg) {
            Text("Per Habit")
                .font(MPFont.labelMedium())
                .foregroundColor(MPColors.textPrimary)

            ForEach(manager.enabledHabits) { config in
                habitStatRow(config)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MPSpacing.lg)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
    }

    func habitStatRow(_ config: HabitConfig) -> some View {
        let rate = habitCompletionRate(for: config.habitType)

        return HStack(spacing: MPSpacing.md) {
            Image(systemName: config.habitType.icon)
                .font(.system(size: 14))
                .foregroundColor(MPColors.textTertiary)
                .frame(width: 20)

            Text(config.habitType.displayName)
                .font(MPFont.bodySmall())
                .foregroundColor(MPColors.textPrimary)

            Spacer()

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(MPColors.progressBg)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor(forRate: rate))
                        .frame(width: geo.size.width * CGFloat(rate / 100), height: 6)
                }
            }
            .frame(width: 60, height: 6)

            Text("\(Int(rate))%")
                .font(MPFont.labelSmall())
                .foregroundColor(MPColors.textSecondary)
                .frame(width: 40, alignment: .trailing)
        }
    }

    func habitCompletionRate(for habitType: HabitType) -> Double {
        var completed = 0
        var total = 0

        for date in last30Days {
            if let log = manager.getDailyLog(for: date),
               let completion = log.completions.first(where: { $0.habitType == habitType }) {
                total += 1
                if completion.isCompleted {
                    completed += 1
                }
            }
        }

        guard total > 0 else { return 0 }
        return Double(completed) / Double(total) * 100
    }

    func barColor(forRate rate: Double) -> Color {
        if rate >= 80 {
            return MPColors.success
        } else if rate >= 50 {
            return MPColors.warning
        } else {
            return MPColors.error
        }
    }
}

#Preview {
    StatisticsView(manager: MorningProofManager.shared)
}
