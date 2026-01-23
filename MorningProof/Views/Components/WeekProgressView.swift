import SwiftUI

// MARK: - Week Progress View

struct WeekProgressView: View {
    @ObservedObject var manager: MorningProofManager
    @Binding var selectedDate: Date?

    private let calendar = Calendar.current
    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    var weekDates: [Date] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        guard let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) else {
            return []
        }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    var body: some View {
        VStack(spacing: MPSpacing.md) {
            // Day labels
            HStack(spacing: 0) {
                ForEach(Array(dayLabels.enumerated()), id: \.offset) { index, label in
                    Text(label)
                        .font(MPFont.labelTiny())
                        .foregroundColor(MPColors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day dots
            HStack(spacing: 0) {
                ForEach(weekDates, id: \.self) { date in
                    WeekDayDot(
                        date: date,
                        log: manager.getDailyLog(for: date),
                        enabledCount: manager.totalEnabled,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate ?? .distantPast),
                        isToday: calendar.isDateInToday(date)
                    )
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if let selected = selectedDate, calendar.isDate(date, inSameDayAs: selected) {
                                selectedDate = nil
                            } else {
                                selectedDate = date
                            }
                        }
                    }
                }
            }

            // Selected day details
            if let date = selectedDate, let log = manager.getDailyLog(for: date) {
                SelectedDayDetails(date: date, log: log)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if let date = selectedDate {
                // Day exists but no log (future or no data)
                SelectedDayPlaceholder(
                    date: date,
                    isFuture: date > Date(),
                    enabledHabits: manager.enabledHabits
                )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
}

// MARK: - Week Day Dot

struct WeekDayDot: View {
    let date: Date
    let log: DailyLog?
    let enabledCount: Int
    let isSelected: Bool
    let isToday: Bool

    private let calendar = Calendar.current

    /// Returns the correct denominator for the fraction display.
    /// For today: use current enabled count (day is still in progress).
    /// For past days: use the historical count from the log (habits may have changed since then).
    private var totalForDay: Int {
        if isToday {
            return enabledCount
        } else {
            return log?.completions.count ?? 0
        }
    }

    var status: DayStatus {
        let isFutureDay = date > Date()

        guard let log = log else {
            if isToday {
                return .today(0)
            } else if isFutureDay {
                return .future
            } else {
                return .missed
            }
        }

        let completed = log.completions.filter { $0.isCompleted }.count

        if isToday {
            return .today(completed)
        } else if completed >= totalForDay && totalForDay > 0 {
            return .complete
        } else if completed > 0 {
            return .partial(completed)
        } else {
            return .missed
        }
    }

    enum DayStatus {
        case complete
        case partial(Int)
        case missed
        case today(Int)
        case future
    }

    var body: some View {
        ZStack {
            // Base circle
            Circle()
                .fill(fillColor)
                .frame(width: 32, height: 32)

            // Today ring
            if isToday {
                Circle()
                    .stroke(MPColors.primary, lineWidth: 2)
                    .frame(width: 32, height: 32)
            }

            // Selection ring
            if isSelected {
                Circle()
                    .stroke(MPColors.primary, lineWidth: 2.5)
                    .frame(width: 40, height: 40)
            }

            // Checkmark for complete days, fraction for partial/today progress
            if case .complete = status {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            } else if case .today(let count) = status, count > 0 && totalForDay > 0 {
                FractionView(numerator: count, denominator: totalForDay)
                    .foregroundColor(MPColors.primary)
            } else if case .partial(let count) = status, totalForDay > 0 {
                FractionView(numerator: count, denominator: totalForDay)
                    .foregroundColor(MPColors.primary)
            }
        }
        .frame(width: 44, height: 44) // Touch target
    }

    var fillColor: Color {
        switch status {
        case .complete:
            return MPColors.accentGold
        case .partial:
            return MPColors.accent.opacity(0.15)
        case .missed:
            return MPColors.surfaceSecondary
        case .today:
            return MPColors.primary.opacity(0.15)
        case .future:
            return MPColors.surfaceSecondary.opacity(0.4)
        }
    }
}

// MARK: - Fraction View

/// A styled fraction display (e.g., "3/4") for week progress circles
struct FractionView: View {
    let numerator: Int
    let denominator: Int

    var body: some View {
        HStack(spacing: 0) {
            Text("\(numerator)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
            Text("/")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .offset(y: -0.5)
            Text("\(denominator)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .rotationEffect(.degrees(-55))
    }
}

// MARK: - Selected Day Details

struct SelectedDayDetails: View {
    let date: Date
    let log: DailyLog

    private var completedCount: Int {
        log.completions.filter { $0.isCompleted }.count
    }

    private var totalCount: Int {
        log.completions.count
    }

    private var isPerfectDay: Bool {
        completedCount == totalCount && totalCount > 0
    }

    // Sort completions: completed first, then incomplete
    private var sortedCompletions: [HabitCompletion] {
        log.completions.sorted { $0.isCompleted && !$1.isCompleted }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            // Header row with date and perfect badge
            HStack {
                Text(formattedDate)
                    .font(MPFont.labelMedium())
                    .foregroundColor(MPColors.textPrimary)

                Spacer()

                // Perfect day badge
                if isPerfectDay {
                    HStack(spacing: MPSpacing.xs) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                        Text("Perfect")
                            .font(MPFont.labelSmall())
                    }
                    .foregroundColor(MPColors.accentGold)
                    .padding(.horizontal, MPSpacing.sm)
                    .padding(.vertical, MPSpacing.xs)
                    .background(MPColors.accentGold.opacity(0.15))
                    .cornerRadius(MPRadius.sm)
                }
            }

            // Summary line
            Text("\(completedCount)/\(totalCount) completed")
                .font(MPFont.bodySmall())
                .foregroundColor(MPColors.textSecondary)

            // Habit completion list with icons
            if !log.completions.isEmpty {
                VStack(alignment: .leading, spacing: MPSpacing.sm) {
                    ForEach(sortedCompletions) { completion in
                        HabitCompletionRow(completion: completion)
                    }
                }
            }
        }
        .padding(MPSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MPColors.surfaceSecondary)
        .cornerRadius(MPRadius.md)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Habit Completion Row

struct HabitCompletionRow: View {
    let completion: HabitCompletion

    var body: some View {
        HStack(spacing: MPSpacing.sm) {
            // Habit icon
            Image(systemName: completion.habitType.icon)
                .font(.system(size: 14))
                .foregroundColor(completion.isCompleted ? MPColors.success : MPColors.textMuted)
                .frame(width: 20)

            // Habit name
            Text(completion.habitType.displayName)
                .font(MPFont.bodySmall())
                .foregroundColor(completion.isCompleted ? MPColors.textPrimary : MPColors.textMuted)

            Spacer()

            // Completion status
            Image(systemName: completion.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(completion.isCompleted ? MPColors.success : MPColors.textMuted)
        }
        .accessibilityLabel("\(completion.habitType.displayName), \(completion.isCompleted ? "completed" : "not completed")")
    }
}

// MARK: - Selected Day Placeholder

struct SelectedDayPlaceholder: View {
    let date: Date
    let isFuture: Bool
    let enabledHabits: [HabitConfig]

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            // Header row
            HStack {
                Text(formattedDate)
                    .font(MPFont.labelMedium())
                    .foregroundColor(MPColors.textPrimary)

                Spacer()

                if isFuture {
                    Text("Upcoming")
                        .font(MPFont.labelSmall())
                        .foregroundColor(MPColors.primary)
                        .padding(.horizontal, MPSpacing.sm)
                        .padding(.vertical, MPSpacing.xs)
                        .background(MPColors.primary.opacity(0.1))
                        .cornerRadius(MPRadius.sm)
                }
            }

            // Show scheduled habits for future days
            if isFuture && !enabledHabits.isEmpty {
                Text("\(enabledHabits.count) habits scheduled")
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.textSecondary)

                // Habit list preview
                VStack(alignment: .leading, spacing: MPSpacing.sm) {
                    ForEach(enabledHabits) { config in
                        ScheduledHabitRow(config: config)
                    }
                }
            } else if !isFuture {
                Text("No data")
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.textTertiary)
            }
        }
        .padding(MPSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MPColors.surfaceSecondary)
        .cornerRadius(MPRadius.md)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Scheduled Habit Row

struct ScheduledHabitRow: View {
    let config: HabitConfig

    var body: some View {
        HStack(spacing: MPSpacing.sm) {
            // Habit icon in a subtle circle
            ZStack {
                Circle()
                    .fill(MPColors.primary.opacity(0.1))
                    .frame(width: 28, height: 28)

                Image(systemName: config.habitType.icon)
                    .font(.system(size: 12))
                    .foregroundColor(MPColors.primary)
            }

            // Habit name
            Text(config.habitType.displayName)
                .font(MPFont.bodySmall())
                .foregroundColor(MPColors.textPrimary)

            Spacer()

            // Empty circle to indicate pending
            Circle()
                .stroke(MPColors.border, lineWidth: 1.5)
                .frame(width: 16, height: 16)
        }
    }
}

// MARK: - Preview

#Preview {
    WeekProgressView(
        manager: MorningProofManager.shared,
        selectedDate: .constant(nil)
    )
    .padding()
    .background(MPColors.surface)
}
