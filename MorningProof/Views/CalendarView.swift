import SwiftUI

struct CalendarView: View {
    @ObservedObject var manager: MorningProofManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedMonth = Date()
    @State private var selectedDate: Date?

    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                VStack(spacing: MPSpacing.xl) {
                    // Month navigation
                    monthHeader

                    // Day of week headers
                    dayOfWeekHeaders

                    // Calendar grid
                    calendarGrid

                    // Selected date details
                    if let date = selectedDate {
                        selectedDateDetails(date)
                    }

                    Spacer()
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.top, MPSpacing.lg)
            }
            .navigationTitle("Calendar")
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

    var monthHeader: some View {
        HStack {
            Button {
                withAnimation {
                    selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(MPColors.primary)
                    .frame(width: 44, height: 44)
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
                    .foregroundColor(canGoForward ? MPColors.primary : MPColors.textMuted)
                    .frame(width: 44, height: 44)
            }
            .disabled(!canGoForward)
        }
    }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    var canGoForward: Bool {
        let today = calendar.startOfDay(for: Date())
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
        return nextMonth <= today
    }

    var dayOfWeekHeaders: some View {
        HStack(spacing: 0) {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(MPFont.labelSmall())
                    .foregroundColor(MPColors.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    var calendarGrid: some View {
        let daysInMonth = getDaysInMonth()

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
            ForEach(daysInMonth, id: \.self) { date in
                if let date = date {
                    dayCell(date)
                } else {
                    Color.clear
                        .frame(height: 44)
                }
            }
        }
    }

    func getDaysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: selectedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }

        return days
    }

    func dayCell(_ date: Date) -> some View {
        let log = manager.getDailyLog(for: date)
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedDate != nil && calendar.isDate(date, inSameDayAs: selectedDate!)
        let isFuture = date > Date()

        let completedCount = log?.completions.filter { $0.isCompleted }.count ?? 0
        let totalCount = log?.completions.count ?? 0
        let isPerfect = completedCount == totalCount && totalCount > 0
        let isPartial = completedCount > 0 && completedCount < totalCount

        return Button {
            if !isFuture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedDate = date
                }
            }
        } label: {
            ZStack {
                // Background
                if isSelected {
                    Circle()
                        .fill(MPColors.primary)
                } else if isToday {
                    Circle()
                        .stroke(MPColors.primary, lineWidth: 2)
                } else if isPerfect {
                    Circle()
                        .fill(MPColors.successLight)
                } else if isPartial {
                    Circle()
                        .fill(MPColors.warningLight)
                }

                // Day number
                Text("\(calendar.component(.day, from: date))")
                    .font(MPFont.labelMedium())
                    .foregroundColor(
                        isSelected ? .white :
                        isFuture ? MPColors.textMuted :
                        MPColors.textPrimary
                    )
            }
            .frame(width: 40, height: 40)
        }
        .disabled(isFuture)
    }

    func selectedDateDetails(_ date: Date) -> some View {
        let log = manager.getDailyLog(for: date)
        let completedCount = log?.completions.filter { $0.isCompleted }.count ?? 0
        let totalCount = log?.completions.count ?? 0

        return VStack(alignment: .leading, spacing: MPSpacing.md) {
            HStack {
                Text(dateDetailString(date))
                    .font(MPFont.labelMedium())
                    .foregroundColor(MPColors.textPrimary)

                Spacer()

                if totalCount > 0 {
                    Text("\(completedCount)/\(totalCount) completed")
                        .font(MPFont.bodySmall())
                        .foregroundColor(completedCount == totalCount ? MPColors.success : MPColors.textSecondary)
                }
            }

            if let log = log, !log.completions.isEmpty {
                // Habit completion details
                ForEach(log.completions) { completion in
                    HStack(spacing: MPSpacing.md) {
                        Image(systemName: completion.habitType.icon)
                            .font(.system(size: 14))
                            .foregroundColor(completion.isCompleted ? MPColors.success : MPColors.textMuted)
                            .frame(width: 20)

                        Text(completion.habitType.displayName)
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textPrimary)

                        Spacer()

                        if completion.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundColor(MPColors.success)
                        }
                    }
                }
            } else {
                Text("No data for this day")
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.textMuted)
            }
        }
        .padding(MPSpacing.lg)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
    }

    func dateDetailString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    CalendarView(manager: MorningProofManager.shared)
}
