import SwiftUI

struct ProgressHeroCard: View {
    @ObservedObject var manager: MorningProofManager
    @State private var selectedWeekDay: Date? = nil
    @State private var animateStreak = false

    var body: some View {
        VStack(spacing: MPSpacing.xl) {
            // Streak + Today
            VStack(spacing: MPSpacing.sm) {
                // Streak row
                HStack(spacing: MPSpacing.sm) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            LinearGradient(
                                colors: manager.currentStreak > 0 ? [.orange, .red] : [.gray, .gray],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(animateStreak ? 1.0 : 0.8)

                    Text("\(manager.currentStreak)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)
                        .scaleEffect(animateStreak ? 1.0 : 0.8)

                    Text("day streak")
                        .font(MPFont.bodyLarge())
                        .foregroundColor(MPColors.textTertiary)
                        .padding(.top, 14)
                }

                // Today's progress
                Text("\(manager.completedCount)/\(manager.totalEnabled) completed today")
                    .font(MPFont.labelMedium())
                    .foregroundColor(MPColors.textSecondary)
            }

            Divider()
                .background(MPColors.divider)

            // Week Progress
            WeekProgressView(manager: manager, selectedDate: $selectedWeekDay)
        }
        .padding(MPSpacing.xl)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.xl)
        .mpShadow(.medium)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                animateStreak = true
            }
        }
    }
}

// MARK: - Records Card

struct RecordsCard: View {
    let bestStreak: Int
    let perfectDays: Int

    var body: some View {
        HStack(spacing: MPSpacing.lg) {
            // Best Streak
            VStack(spacing: MPSpacing.xs) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 20))
                    .foregroundColor(MPColors.accentGold)

                Text("\(bestStreak)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                Text("Best Streak")
                    .font(MPFont.labelSmall())
                    .foregroundColor(MPColors.textTertiary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 50)
                .background(MPColors.divider)

            // Perfect Days
            VStack(spacing: MPSpacing.xs) {
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundColor(MPColors.accentGold)

                Text("\(perfectDays)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                Text("Perfect Days")
                    .font(MPFont.labelSmall())
                    .foregroundColor(MPColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(MPSpacing.lg)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
    }
}

// MARK: - Habit Breakdown Card

struct HabitBreakdownCard: View {
    @ObservedObject var manager: MorningProofManager

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.lg) {
            Text("Last 30 Days")
                .font(MPFont.labelMedium())
                .foregroundColor(MPColors.textTertiary)

            ForEach(manager.enabledHabits) { config in
                let stats = calculateStats(for: config.habitType)
                HabitProgressRow(
                    habitType: config.habitType,
                    completionRate: stats.rate,
                    hasData: stats.hasData,
                    missedDays: stats.missedDays
                )
            }
        }
        .padding(MPSpacing.lg)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
    }

    private func calculateStats(for habitType: HabitType) -> (rate: Double, hasData: Bool, missedDays: Int) {
        let today = calendar.startOfDay(for: Date())
        let last30 = (0..<30).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }

        var completed = 0
        var total = 0

        for date in last30 {
            if let log = manager.getDailyLog(for: date),
               let completion = log.completions.first(where: { $0.habitType == habitType }) {
                total += 1
                if completion.isCompleted {
                    completed += 1
                }
            }
        }

        let hasData = total > 0
        let rate = hasData ? Double(completed) / Double(total) * 100 : 0
        let missedDays = total - completed
        return (rate, hasData, missedDays)
    }
}

// MARK: - Habit Progress Row

struct HabitProgressRow: View {
    let habitType: HabitType
    let completionRate: Double
    var hasData: Bool = true
    var missedDays: Int = 0

    var body: some View {
        HStack(spacing: MPSpacing.md) {
            // Icon with color based on rate
            ZStack {
                Circle()
                    .fill(progressColor.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: habitType.icon)
                    .font(.system(size: 14))
                    .foregroundColor(progressColor)
            }

            Text(habitType.displayName)
                .font(MPFont.bodySmall())
                .foregroundColor(MPColors.textPrimary)

            Spacer()

            // Circular progress indicator
            ZStack {
                Circle()
                    .stroke(MPColors.progressBg, lineWidth: 3)
                    .frame(width: 40, height: 40)

                Circle()
                    .trim(from: 0, to: completionRate / 100)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 40, height: 40)

                Text("\(Int(completionRate))%")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(progressColor)
            }
        }
    }

    private var progressColor: Color {
        // Show grey if no data (new user hasn't done any habits yet)
        if !hasData {
            return MPColors.textMuted
        }
        // 3-tier system: green (80%+), yellow (20-79%), red (<20%)
        // But only show red if user has missed at least 2 days (to be fair to new users)
        if completionRate >= 80 {
            return MPColors.success
        } else if completionRate >= 20 {
            return MPColors.warning
        } else if missedDays >= 2 {
            return MPColors.error
        } else {
            // Less than 20% but fewer than 2 missed days - show grey instead of red
            return MPColors.textMuted
        }
    }
}

// MARK: - Quick Stats Card

struct QuickStatsCard: View {
    let currentStreak: Int
    let thisWeekRate: Double
    let perfectDaysThisWeek: Int

    var body: some View {
        HStack(spacing: 0) {
            // Streak
            StatPill(
                icon: "flame.fill",
                iconColor: MPColors.accent,
                value: "\(currentStreak)",
                label: "Streak"
            )

            Divider()
                .frame(height: 40)

            // This Week Rate
            StatPill(
                icon: "chart.line.uptrend.xyaxis",
                iconColor: MPColors.success,
                value: "\(Int(thisWeekRate))%",
                label: "This Week"
            )

            Divider()
                .frame(height: 40)

            // Perfect Days
            StatPill(
                icon: "star.fill",
                iconColor: MPColors.accentGold,
                value: "\(perfectDaysThisWeek)",
                label: "Perfect"
            )
        }
        .padding(.vertical, MPSpacing.lg)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
    }
}

struct StatPill: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: MPSpacing.xs) {
            HStack(spacing: MPSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)
            }
            Text(label)
                .font(MPFont.labelTiny())
                .foregroundColor(MPColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Trend Indicator

struct TrendIndicator: View {
    let thisWeekRate: Double
    let lastWeekRate: Double

    private var trend: Trend {
        let diff = thisWeekRate - lastWeekRate
        if diff > 5 { return .improving }
        else if diff < -5 { return .declining }
        else { return .stable }
    }

    enum Trend {
        case improving, stable, declining

        var icon: String {
            switch self {
            case .improving: return "arrow.up.right"
            case .stable: return "arrow.right"
            case .declining: return "arrow.down.right"
            }
        }

        var color: Color {
            switch self {
            case .improving: return MPColors.success
            case .stable: return MPColors.textSecondary
            case .declining: return MPColors.error
            }
        }

        var label: String {
            switch self {
            case .improving: return "Improving"
            case .stable: return "Steady"
            case .declining: return "Needs focus"
            }
        }
    }

    var body: some View {
        HStack(spacing: MPSpacing.xs) {
            Image(systemName: trend.icon)
                .font(.system(size: 12, weight: .medium))
            Text(trend.label)
                .font(MPFont.labelSmall())
        }
        .foregroundColor(trend.color)
        .padding(.horizontal, MPSpacing.sm)
        .padding(.vertical, MPSpacing.xs)
        .background(trend.color.opacity(0.1))
        .cornerRadius(MPRadius.full)
    }
}

// MARK: - Previews

#Preview("Progress Hero Card") {
    ProgressHeroCard(manager: MorningProofManager.shared)
        .padding()
        .background(MPColors.background)
}

#Preview("Records Card") {
    RecordsCard(bestStreak: 15, perfectDays: 47)
        .padding()
        .background(MPColors.background)
}

#Preview("Habit Breakdown") {
    HabitBreakdownCard(manager: MorningProofManager.shared)
        .padding()
        .background(MPColors.background)
}
