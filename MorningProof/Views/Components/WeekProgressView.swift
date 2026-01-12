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
                SelectedDayPlaceholder(date: date, isFuture: date > Date())
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
        } else if completed >= enabledCount && enabledCount > 0 {
            return .complete
        } else if completed > 0 {
            return .partial
        } else {
            return .missed
        }
    }

    enum DayStatus {
        case complete
        case partial
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

            // Show progress for today
            if case .today(let count) = status, count > 0 && enabledCount > 0 {
                Text("\(count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
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
            return MPColors.accent
        case .missed:
            return MPColors.surfaceSecondary
        case .today:
            return MPColors.primary.opacity(0.15)
        case .future:
            return MPColors.surfaceSecondary.opacity(0.4)
        }
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

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.sm) {
            Text(formattedDate)
                .font(MPFont.labelMedium())
                .foregroundColor(MPColors.textPrimary)

            HStack(spacing: MPSpacing.lg) {
                Label("\(completedCount)/\(totalCount) completed", systemImage: "checkmark.circle.fill")
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.success)

                if log.allCompletedBeforeCutoff && completedCount == totalCount && totalCount > 0 {
                    Label("Perfect", systemImage: "star.fill")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.accentGold)
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

// MARK: - Selected Day Placeholder

struct SelectedDayPlaceholder: View {
    let date: Date
    let isFuture: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.sm) {
            Text(formattedDate)
                .font(MPFont.labelMedium())
                .foregroundColor(MPColors.textPrimary)

            Text(isFuture ? "Coming up" : "No data")
                .font(MPFont.bodySmall())
                .foregroundColor(MPColors.textTertiary)
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

// MARK: - Preview

#Preview {
    WeekProgressView(
        manager: MorningProofManager.shared,
        selectedDate: .constant(nil)
    )
    .padding()
    .background(MPColors.surface)
}
