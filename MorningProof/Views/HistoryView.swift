import SwiftUI

struct HistoryView: View {
    @ObservedObject var manager: MorningProofManager
    @Environment(\.dismiss) var dismiss

    // Generate last 30 days
    private var last30Days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<30).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: MPSpacing.md) {
                        ForEach(last30Days, id: \.self) { date in
                            historyRow(for: date)
                        }
                    }
                    .padding(.horizontal, MPSpacing.xl)
                    .padding(.top, MPSpacing.lg)
                    .padding(.bottom, MPSpacing.xxxl)
                }
            }
            .navigationTitle("History")
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

    func historyRow(for date: Date) -> some View {
        let log = manager.getDailyLog(for: date)
        let isToday = Calendar.current.isDateInToday(date)
        let completedCount = log?.completions.filter { $0.isCompleted }.count ?? 0
        let totalCount = log?.completions.count ?? manager.enabledHabits.count
        let isPerfect = completedCount == totalCount && totalCount > 0
        let hasAnyData = log != nil && totalCount > 0

        return VStack(alignment: .leading, spacing: MPSpacing.sm) {
            HStack {
                // Date
                VStack(alignment: .leading, spacing: 2) {
                    Text(isToday ? "Today" : dayString(date))
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.textPrimary)

                    Text(dateString(date))
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }

                Spacer()

                // Status
                if hasAnyData {
                    HStack(spacing: MPSpacing.sm) {
                        Text("\(completedCount)/\(totalCount)")
                            .font(MPFont.labelMedium())
                            .foregroundColor(isPerfect ? MPColors.success : MPColors.textSecondary)

                        if isPerfect {
                            Image(systemName: "star.fill")
                                .foregroundColor(MPColors.accentGold)
                        }
                    }
                } else {
                    Text("No data")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textMuted)
                }
            }

            // Habit icons row
            if let log = log, !log.completions.isEmpty {
                HStack(spacing: MPSpacing.sm) {
                    ForEach(log.completions) { completion in
                        habitIcon(for: completion)
                    }
                    Spacer()
                }
            }
        }
        .padding(MPSpacing.lg)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
    }

    func habitIcon(for completion: HabitCompletion) -> some View {
        ZStack {
            Circle()
                .fill(completion.isCompleted ? MPColors.successLight : MPColors.surfaceSecondary)
                .frame(width: 32, height: 32)

            Image(systemName: completion.habitType.icon)
                .font(.system(size: 14))
                .foregroundColor(completion.isCompleted ? MPColors.success : MPColors.textMuted)
        }
    }

    func dayString(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    HistoryView(manager: MorningProofManager.shared)
}
