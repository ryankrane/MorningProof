import SwiftUI

// MARK: - Customization Mode

/// Kept for backward compatibility with existing saved data
enum DeadlineCustomizationMode: Int, CaseIterable {
    case sameEveryDay = 0
    case weekdayWeekend = 1  // No longer shown in UI, but data may exist
    case eachDay = 2

    var displayName: String {
        switch self {
        case .sameEveryDay: return "Same every day"
        case .weekdayWeekend: return "Weekdays/Weekends"
        case .eachDay: return "Each day"
        }
    }
}

// MARK: - Main Card View

/// Apple-style deadline picker with progressive disclosure.
/// Shows a compact collapsed row by default, expands to full sheet on tap.
struct DeadlineCardView: View {
    // Single deadline (used when mode is .sameEveryDay)
    @Binding var cutoffMinutes: Int

    // Customization mode (0 = same every day, 1 = weekday/weekend, 2 = each day)
    @Binding var customizationMode: Int

    // Weekday/weekend deadlines (kept for backward compatibility)
    @Binding var weekdayDeadlineMinutes: Int
    @Binding var weekendDeadlineMinutes: Int

    // Per-day deadlines (used when mode is .eachDay)
    // Index 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    @Binding var perDayDeadlineMinutes: [Int]

    @State private var showDeadlineSheet = false

    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    private var isPerDayMode: Bool {
        customizationMode == DeadlineCustomizationMode.eachDay.rawValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.sm) {
            // Section header
            Text("DEADLINE")
                .font(MPFont.labelSmall())
                .foregroundColor(MPColors.textTertiary)
                .tracking(0.5)
                .padding(.leading, MPSpacing.xs)

            // Collapsed row - tap to expand
            Button {
                showDeadlineSheet = true
            } label: {
                collapsedRowView
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showDeadlineSheet) {
                DeadlinePickerSheet(
                    cutoffMinutes: $cutoffMinutes,
                    customizationMode: $customizationMode,
                    perDayDeadlineMinutes: $perDayDeadlineMinutes
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Collapsed Row View

    private var collapsedRowView: some View {
        HStack {
            Text("Complete by")
                .font(.system(size: 17))
                .foregroundColor(MPColors.textPrimary)

            Spacer()

            if isPerDayMode {
                // Mini week strip preview
                miniWeekStrip
            } else {
                // Single time display
                Text(formatTime(cutoffMinutes))
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(MPColors.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(MPColors.textTertiary)
        }
        .padding(.horizontal, MPSpacing.lg)
        .padding(.vertical, 14)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
    }

    // MARK: - Mini Week Strip (for per-day mode collapsed view)

    private var miniWeekStrip: some View {
        HStack(spacing: 3) {
            ForEach(0..<7, id: \.self) { index in
                VStack(spacing: 1) {
                    Text(dayLabels[index])
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(MPColors.textTertiary)

                    Text(shortTime(perDayDeadlineMinutes[index]))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(MPColors.textSecondary)
                }
                .frame(width: 22)
            }
        }
    }

    // MARK: - Helper Functions

    private func formatTime(_ minutes: Int) -> String {
        let hour24 = minutes / 60
        let minute = minutes % 60
        let hour = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24)
        let period = hour24 >= 12 ? "PM" : "AM"
        return String(format: "%d:%02d %@", hour, minute, period)
    }

    private func shortTime(_ minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        let period = hour >= 12 ? "p" : "a"

        if minute == 0 {
            return "\(displayHour)\(period)"
        } else {
            return "\(displayHour):\(String(format: "%02d", minute))\(period)"
        }
    }
}

// MARK: - Deadline Picker Sheet

struct DeadlinePickerSheet: View {
    @Binding var cutoffMinutes: Int
    @Binding var customizationMode: Int
    @Binding var perDayDeadlineMinutes: [Int]

    @Environment(\.dismiss) private var dismiss

    // Local state for editing (applied on "Set Time")
    @State private var localCutoffMinutes: Int = 540
    @State private var localPerDayMinutes: [Int] = Array(repeating: 540, count: 7)
    @State private var customizeEnabled: Bool = false
    @State private var selectedDayIndex: Int = 0

    // Picker state
    @State private var selectedHour: Int = 9
    @State private var selectedMinute: Int = 0
    @State private var selectedPeriod: String = "AM"

    private let hours = Array(1...12)
    private let availableMinutes = [0, 15, 30, 45]
    private let periods = ["AM", "PM"]
    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    private let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    private var todayIndex: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday - 1
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Wheel picker
                inlineWheelPicker
                    .padding(.top, MPSpacing.md)

                // Large time display
                timeDisplayView
                    .padding(.top, MPSpacing.sm)
                    .padding(.bottom, MPSpacing.lg)

                Divider()
                    .background(MPColors.divider)
                    .padding(.horizontal, MPSpacing.lg)

                // Week strip (only when customizing)
                if customizeEnabled {
                    weekStripView
                        .padding(.vertical, MPSpacing.md)
                        .padding(.horizontal, MPSpacing.lg)
                        .transition(.opacity.combined(with: .move(edge: .top)))

                    Divider()
                        .background(MPColors.divider)
                        .padding(.horizontal, MPSpacing.lg)
                }

                // Toggle row
                customizeToggleRow
                    .padding(.horizontal, MPSpacing.lg)
                    .padding(.vertical, 14)

                Spacer()

                // Set Time button
                Button {
                    applyChanges()
                    dismiss()
                } label: {
                    Text("Set Time")
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
            .navigationTitle("Morning Deadline")
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
        .onAppear {
            initializeLocalState()
        }
    }

    // MARK: - Inline Wheel Picker

    private var inlineWheelPicker: some View {
        HStack(spacing: 0) {
            Picker("Hour", selection: $selectedHour) {
                ForEach(hours, id: \.self) { hour in
                    Text("\(hour)")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .tag(hour)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 70)
            .clipped()

            Text(":")
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundColor(MPColors.textPrimary)

            Picker("Minute", selection: $selectedMinute) {
                ForEach(availableMinutes, id: \.self) { minute in
                    Text(String(format: "%02d", minute))
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 70)
            .clipped()

            Picker("Period", selection: $selectedPeriod) {
                ForEach(periods, id: \.self) { period in
                    Text(period)
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .tag(period)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 70)
            .clipped()
        }
        .frame(height: 150)
        .onChange(of: selectedHour) { syncPickerToLocal() }
        .onChange(of: selectedMinute) { syncPickerToLocal() }
        .onChange(of: selectedPeriod) { syncPickerToLocal() }
    }

    // MARK: - Time Display

    private var timeDisplayView: some View {
        VStack(spacing: 4) {
            Text(formattedPickerTime)
                .font(.system(size: 48, weight: .semibold, design: .rounded))
                .foregroundColor(MPColors.primary)

            if customizeEnabled {
                Text("for \(dayNames[selectedDayIndex])")
                    .font(.system(size: 15))
                    .foregroundColor(MPColors.textSecondary)
            }
        }
    }

    // MARK: - Week Strip

    private var weekStripView: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                dayCircle(index: index)
            }
        }
    }

    private func dayCircle(index: Int) -> some View {
        let isSelected = selectedDayIndex == index
        let minutes = localPerDayMinutes[index]

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDayIndex = index
            }
            syncPickerFromDay(index)
        } label: {
            VStack(spacing: 6) {
                Text(dayLabels[index])
                    .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .white : MPColors.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? MPColors.primary : MPColors.surfaceSecondary)
                    )

                Text(shortTime(minutes))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? MPColors.primary : MPColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Customize Toggle Row

    private var customizeToggleRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Customize by day")
                    .font(.system(size: 17))
                    .foregroundColor(MPColors.textPrimary)

                Text(customizeEnabled ? "Tap a day to change its time" : "Set different times for each day")
                    .font(.system(size: 13))
                    .foregroundColor(MPColors.textTertiary)
            }

            Spacer()

            Toggle("", isOn: $customizeEnabled)
                .labelsHidden()
                .tint(MPColors.primary)
        }
        .animation(.easeInOut(duration: 0.25), value: customizeEnabled)
        .onChange(of: customizeEnabled) { _, newValue in
            handleToggleChange(enabled: newValue)
        }
    }

    // MARK: - Helper Functions

    private var formattedPickerTime: String {
        String(format: "%d:%02d %@", selectedHour, selectedMinute, selectedPeriod)
    }

    private func shortTime(_ minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        let period = hour >= 12 ? "p" : "a"

        if minute == 0 {
            return "\(displayHour)\(period)"
        } else {
            return "\(displayHour):\(String(format: "%02d", minute))\(period)"
        }
    }

    private func pickerToMinutes() -> Int {
        var hour24 = selectedHour
        if selectedPeriod == "AM" {
            if selectedHour == 12 { hour24 = 0 }
        } else {
            if selectedHour != 12 { hour24 = selectedHour + 12 }
        }
        return hour24 * 60 + selectedMinute
    }

    private func minutesToPicker(_ minutes: Int) -> (hour: Int, minute: Int, period: String) {
        let hour24 = minutes / 60
        let minute = minutes % 60
        let hour = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24)
        let period = hour24 >= 12 ? "PM" : "AM"
        return (hour, minute, period)
    }

    private func initializeLocalState() {
        // Copy current values to local state
        localCutoffMinutes = cutoffMinutes
        localPerDayMinutes = perDayDeadlineMinutes

        // Set toggle state from customization mode
        let mode = DeadlineCustomizationMode(rawValue: customizationMode) ?? .sameEveryDay
        customizeEnabled = mode == .eachDay

        if customizeEnabled {
            selectedDayIndex = todayIndex
            syncPickerFromDay(todayIndex)
        } else {
            let components = minutesToPicker(localCutoffMinutes)
            selectedHour = components.hour
            selectedMinute = components.minute
            selectedPeriod = components.period
        }
    }

    private func syncPickerFromDay(_ dayIndex: Int) {
        let minutes = localPerDayMinutes[dayIndex]
        let components = minutesToPicker(minutes)
        selectedHour = components.hour
        selectedMinute = components.minute
        selectedPeriod = components.period
    }

    private func syncPickerToLocal() {
        let mins = pickerToMinutes()

        if customizeEnabled {
            localPerDayMinutes[selectedDayIndex] = mins
        } else {
            localCutoffMinutes = mins
        }
    }

    private func handleToggleChange(enabled: Bool) {
        withAnimation(.easeInOut(duration: 0.25)) {
            if enabled {
                // Initialize all per-day times from current cutoff
                for i in 0..<7 {
                    localPerDayMinutes[i] = localCutoffMinutes
                }
                selectedDayIndex = todayIndex
                syncPickerFromDay(todayIndex)
            }
        }
    }

    private func applyChanges() {
        if customizeEnabled {
            customizationMode = DeadlineCustomizationMode.eachDay.rawValue
            perDayDeadlineMinutes = localPerDayMinutes
        } else {
            customizationMode = DeadlineCustomizationMode.sameEveryDay.rawValue
            cutoffMinutes = localCutoffMinutes
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State var cutoffMinutes = 540  // 9:00 AM
        @State var mode = 0
        @State var weekdayMinutes = 540
        @State var weekendMinutes = 660
        @State var perDayMinutes = [660, 540, 540, 540, 540, 540, 660]

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    DeadlineCardView(
                        cutoffMinutes: $cutoffMinutes,
                        customizationMode: $mode,
                        weekdayDeadlineMinutes: $weekdayMinutes,
                        weekendDeadlineMinutes: $weekendMinutes,
                        perDayDeadlineMinutes: $perDayMinutes
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Debug Info")
                            .font(.caption.bold())
                        Text("Mode: \(mode)")
                        Text("Cutoff: \(cutoffMinutes) (\(TimeOptions.formatTime(cutoffMinutes)))")
                        Text("Per-day: \(perDayMinutes.map { "\($0)" }.joined(separator: ", "))")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(MPColors.surfaceSecondary)
                    .cornerRadius(8)
                }
                .padding()
            }
            .background(MPColors.background)
        }
    }
    return PreviewWrapper()
}
