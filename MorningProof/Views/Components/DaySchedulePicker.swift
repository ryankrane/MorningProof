import SwiftUI

/// A picker for selecting which days of the week a habit is active
struct DaySchedulePicker: View {
    @Binding var activeDays: Set<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.lg) {
            // Quick presets
            HStack(spacing: MPSpacing.sm) {
                PresetButton(
                    title: "Every day",
                    isSelected: activeDays == DaySchedule.allDays,
                    action: { activeDays = DaySchedule.allDays }
                )

                PresetButton(
                    title: "Weekdays",
                    isSelected: activeDays == DaySchedule.weekdays,
                    action: { activeDays = DaySchedule.weekdays }
                )

                PresetButton(
                    title: "Weekends",
                    isSelected: activeDays == DaySchedule.weekends,
                    action: { activeDays = DaySchedule.weekends }
                )
            }

            // Individual day toggles
            HStack(spacing: MPSpacing.sm) {
                ForEach(DaySchedule.shortDayNames, id: \.day) { dayInfo in
                    DayToggleCircle(
                        day: dayInfo.day,
                        label: dayInfo.name,
                        isSelected: activeDays.contains(dayInfo.day),
                        onToggle: { toggleDay(dayInfo.day) }
                    )
                }
            }
        }
    }

    private func toggleDay(_ day: Int) {
        if activeDays.contains(day) {
            // Don't allow deselecting all days
            if activeDays.count > 1 {
                activeDays.remove(day)
            }
        } else {
            activeDays.insert(day)
        }
    }
}

// MARK: - Preset Button

private struct PresetButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(MPFont.labelSmall())
                .foregroundColor(isSelected ? .white : MPColors.textSecondary)
                .padding(.horizontal, MPSpacing.md)
                .padding(.vertical, MPSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: MPRadius.sm)
                        .fill(isSelected ? MPColors.primary : MPColors.surfaceSecondary)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Day Toggle Circle

private struct DayToggleCircle: View {
    let day: Int
    let label: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : MPColors.textSecondary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isSelected ? MPColors.primary : MPColors.surfaceSecondary)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Day Schedule Display

/// A compact inline display of the day schedule (for use in list rows)
struct DayScheduleLabel: View {
    let activeDays: Set<Int>

    var body: some View {
        Text(DaySchedule.displayString(for: activeDays))
            .font(MPFont.bodySmall())
            .foregroundColor(MPColors.textTertiary)
    }
}

// MARK: - Day Schedule Sheet

/// A sheet for editing the day schedule with full UI
struct DayScheduleSheet: View {
    @Binding var activeDays: Set<Int>
    @Environment(\.dismiss) var dismiss

    let habitName: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: MPSpacing.xs) {
                    Text("Schedule")
                        .font(MPFont.headingSmall())
                        .foregroundColor(MPColors.textPrimary)

                    Text("Which days should \"\(habitName)\" be active?")
                        .font(MPFont.bodyMedium())
                        .foregroundColor(MPColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, MPSpacing.xl)
                .padding(.bottom, MPSpacing.xxl)
                .padding(.horizontal, MPSpacing.xl)

                VStack(spacing: MPSpacing.xl) {
                    DaySchedulePicker(activeDays: $activeDays)
                        .padding(.horizontal, MPSpacing.xl)

                    // Current selection display
                    Text(DaySchedule.displayString(for: activeDays))
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(MPColors.primary)
                        .padding(.top, MPSpacing.lg)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(MPFont.labelLarge())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: MPButtonHeight.lg)
                        .background(MPColors.primary)
                        .cornerRadius(MPRadius.lg)
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.bottom, MPSpacing.xxxl)
            }
            .background(MPColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(MPColors.textSecondary)
                }
            }
        }
    }
}

#Preview("Day Schedule Picker") {
    struct PreviewWrapper: View {
        @State var days: Set<Int> = DaySchedule.weekdays

        var body: some View {
            VStack(spacing: 20) {
                DaySchedulePicker(activeDays: $days)

                Text("Selected: \(DaySchedule.displayString(for: days))")
                    .foregroundColor(MPColors.textSecondary)
            }
            .padding()
            .background(MPColors.background)
        }
    }
    return PreviewWrapper()
}

#Preview("Day Schedule Sheet") {
    struct PreviewWrapper: View {
        @State var days: Set<Int> = DaySchedule.allDays
        @State var showSheet = true

        var body: some View {
            Button("Show Sheet") {
                showSheet = true
            }
            .sheet(isPresented: $showSheet) {
                DayScheduleSheet(activeDays: $days, habitName: "Made Bed")
                    .presentationDetents([.medium])
            }
        }
    }
    return PreviewWrapper()
}
