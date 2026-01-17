import SwiftUI

/// A wheel-style time picker presented as a sheet
/// Provides the classic iOS slot-machine interface for selecting hours and minutes
struct TimeWheelPicker: View {
    @Binding var selectedMinutes: Int
    @Environment(\.dismiss) var dismiss

    let title: String
    let subtitle: String?
    let timeOptions: [Int]  // Available times in minutes since midnight

    @State private var selectedHour: Int = 6
    @State private var selectedMinute: Int = 0
    @State private var selectedPeriod: String = "AM"

    init(
        selectedMinutes: Binding<Int>,
        title: String,
        subtitle: String? = nil,
        timeOptions: [Int]
    ) {
        self._selectedMinutes = selectedMinutes
        self.title = title
        self.subtitle = subtitle
        self.timeOptions = timeOptions

        // Initialize state from binding value
        let mins = selectedMinutes.wrappedValue
        let hour24 = mins / 60
        let minute = mins % 60

        _selectedHour = State(initialValue: hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24))
        _selectedMinute = State(initialValue: minute)
        _selectedPeriod = State(initialValue: hour24 >= 12 ? "PM" : "AM")
    }

    // Available hours (1-12)
    private let hours = Array(1...12)

    // Available minutes (0, 15, 30, 45 or 0, 30 depending on options)
    private var availableMinutes: [Int] {
        // Deduce minute intervals from timeOptions
        let minuteSet = Set(timeOptions.map { $0 % 60 })
        return Array(minuteSet).sorted()
    }

    private let periods = ["AM", "PM"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: MPSpacing.xs) {
                    Text(title)
                        .font(MPFont.headingSmall())
                        .foregroundColor(MPColors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textSecondary)
                    }
                }
                .padding(.top, MPSpacing.xl)
                .padding(.bottom, MPSpacing.lg)

                // Wheel pickers
                HStack(spacing: 0) {
                    // Hour picker
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

                    // Minute picker
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

                    // AM/PM picker
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
                .frame(height: 180)
                .padding(.horizontal, MPSpacing.xl)

                // Current selection display
                Text(formattedTime)
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .foregroundColor(MPColors.primary)
                    .padding(.vertical, MPSpacing.xl)

                Spacer()

                // Confirm button
                Button {
                    applySelection()
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

    private var formattedTime: String {
        String(format: "%d:%02d %@", selectedHour, selectedMinute, selectedPeriod)
    }

    private func applySelection() {
        // Convert to 24-hour minutes since midnight
        var hour24 = selectedHour
        if selectedPeriod == "AM" {
            if selectedHour == 12 {
                hour24 = 0  // 12 AM = midnight = 0
            }
        } else {
            if selectedHour != 12 {
                hour24 = selectedHour + 12  // PM, not noon
            }
            // 12 PM = noon = 12, no change needed
        }

        let totalMinutes = hour24 * 60 + selectedMinute

        // Snap to nearest available option if exact match not available
        if timeOptions.contains(totalMinutes) {
            selectedMinutes = totalMinutes
        } else {
            // Find closest available option
            let closest = timeOptions.min(by: { abs($0 - totalMinutes) < abs($1 - totalMinutes) }) ?? totalMinutes
            selectedMinutes = closest
        }
    }
}

// MARK: - Time Picker Row (for use in settings)

/// A tappable row that displays current time and opens TimeWheelPicker when tapped
struct TimePickerRow: View {
    let label: String
    let subtitle: String?
    @Binding var selectedMinutes: Int
    let timeOptions: [Int]
    let pickerTitle: String
    let pickerSubtitle: String?

    @State private var showPicker = false

    init(
        label: String,
        subtitle: String? = nil,
        selectedMinutes: Binding<Int>,
        timeOptions: [Int],
        pickerTitle: String? = nil,
        pickerSubtitle: String? = nil
    ) {
        self.label = label
        self.subtitle = subtitle
        self._selectedMinutes = selectedMinutes
        self.timeOptions = timeOptions
        self.pickerTitle = pickerTitle ?? label
        self.pickerSubtitle = pickerSubtitle
    }

    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: MPSpacing.xs) {
                    Text(label)
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textTertiary)
                    }
                }

                Spacer()

                Text(formatTime(selectedMinutes))
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(MPColors.primary)
                    .padding(.horizontal, MPSpacing.md)
                    .padding(.vertical, MPSpacing.sm)
                    .background(MPColors.primaryLight)
                    .cornerRadius(MPRadius.md)
            }
        }
        .sheet(isPresented: $showPicker) {
            TimeWheelPicker(
                selectedMinutes: $selectedMinutes,
                title: pickerTitle,
                subtitle: pickerSubtitle,
                timeOptions: timeOptions
            )
            .presentationDetents([.medium])
        }
    }

    private func formatTime(_ minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }
}

// MARK: - Time Options Generators

struct TimeOptions {
    /// Blocking start time options: 12:00 AM (midnight) through 10:00 AM in 30-min intervals
    /// This allows users to start blocking at midnight for a "clean slate" each day
    static let blockingStartTime: [Int] = {
        // Midnight (0) through 10 AM (600), 30-minute intervals
        Array(stride(from: 0, through: 600, by: 30))
    }()

    /// Morning cutoff time options: 5:00 AM through 1:00 PM in 15-min intervals
    static let cutoffTime: [Int] = {
        Array(stride(from: 300, through: 780, by: 15))
    }()

    /// Morning reminder time options: 5:00 AM through 12:00 PM in 30-min intervals
    static let reminderTime: [Int] = {
        Array(stride(from: 300, through: 720, by: 30))
    }()

    /// Format minutes since midnight to display string
    static func formatTime(_ minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }
}

// MARK: - Sleep Goal Picker

struct SleepGoalPicker: View {
    @Binding var sleepGoal: Double
    @Environment(\.dismiss) var dismiss

    @State private var selectedHours: Int = 7
    @State private var selectedMinutes: Int = 0

    private let hours = Array(5...10)
    private let minutes = [0, 30]

    init(sleepGoal: Binding<Double>) {
        self._sleepGoal = sleepGoal
        let totalMinutes = Int(sleepGoal.wrappedValue * 60)
        _selectedHours = State(initialValue: totalMinutes / 60)
        _selectedMinutes = State(initialValue: (totalMinutes % 60) >= 30 ? 30 : 0)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: MPSpacing.xs) {
                    Text("Sleep Goal")
                        .font(MPFont.headingSmall())
                        .foregroundColor(MPColors.textPrimary)

                    Text("How many hours of sleep do you want each night?")
                        .font(MPFont.bodyMedium())
                        .foregroundColor(MPColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, MPSpacing.xl)
                .padding(.bottom, MPSpacing.lg)
                .padding(.horizontal, MPSpacing.xl)

                // Wheel pickers
                HStack(spacing: 0) {
                    Picker("Hours", selection: $selectedHours) {
                        ForEach(hours, id: \.self) { hour in
                            Text("\(hour)")
                                .font(.system(size: 22, weight: .medium, design: .rounded))
                                .tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)
                    .clipped()

                    Text("h")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundColor(MPColors.textSecondary)

                    Picker("Minutes", selection: $selectedMinutes) {
                        ForEach(minutes, id: \.self) { minute in
                            Text(String(format: "%02d", minute))
                                .font(.system(size: 22, weight: .medium, design: .rounded))
                                .tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)
                    .clipped()

                    Text("m")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundColor(MPColors.textSecondary)
                }
                .frame(height: 180)

                // Current selection display
                Text(formattedGoal)
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .foregroundColor(MPColors.primary)
                    .padding(.vertical, MPSpacing.xl)

                Spacer()

                // Confirm button
                Button {
                    sleepGoal = Double(selectedHours) + Double(selectedMinutes) / 60.0
                    dismiss()
                } label: {
                    Text("Set Goal")
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

    private var formattedGoal: String {
        if selectedMinutes == 0 {
            return "\(selectedHours)h"
        } else {
            return "\(selectedHours)h \(selectedMinutes)m"
        }
    }
}

// MARK: - Step Goal Picker

struct StepGoalPicker: View {
    @Binding var stepGoal: Int
    @Environment(\.dismiss) var dismiss

    @State private var selectedSteps: Int = 500

    private let stepOptions = Array(stride(from: 100, through: 5000, by: 50))

    init(stepGoal: Binding<Int>) {
        self._stepGoal = stepGoal
        _selectedSteps = State(initialValue: stepGoal.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: MPSpacing.xs) {
                    Text("Step Goal")
                        .font(MPFont.headingSmall())
                        .foregroundColor(MPColors.textPrimary)

                    Text("How many steps do you want to hit each morning?")
                        .font(MPFont.bodyMedium())
                        .foregroundColor(MPColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, MPSpacing.xl)
                .padding(.bottom, MPSpacing.lg)
                .padding(.horizontal, MPSpacing.xl)

                // Wheel picker
                Picker("Steps", selection: $selectedSteps) {
                    ForEach(stepOptions, id: \.self) { steps in
                        Text("\(steps)")
                            .font(.system(size: 22, weight: .medium, design: .rounded))
                            .tag(steps)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 180)

                // Current selection display
                HStack(spacing: 4) {
                    Text("\(selectedSteps)")
                        .font(.system(size: 48, weight: .semibold, design: .rounded))
                        .foregroundColor(MPColors.primary)

                    Text("steps")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(MPColors.textSecondary)
                }
                .padding(.vertical, MPSpacing.xl)

                Spacer()

                // Confirm button
                Button {
                    stepGoal = selectedSteps
                    dismiss()
                } label: {
                    Text("Set Goal")
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

#Preview("Time Wheel Picker") {
    struct PreviewWrapper: View {
        @State var minutes = 360  // 6 AM

        var body: some View {
            TimeWheelPicker(
                selectedMinutes: $minutes,
                title: "Block Apps Starting At",
                subtitle: "When should blocking begin?",
                timeOptions: TimeOptions.blockingStartTime
            )
        }
    }
    return PreviewWrapper()
}

#Preview("Time Picker Row") {
    struct PreviewWrapper: View {
        @State var minutes = 360  // 6 AM

        var body: some View {
            VStack {
                TimePickerRow(
                    label: "Block Apps Starting At",
                    subtitle: "When should blocking begin?",
                    selectedMinutes: $minutes,
                    timeOptions: TimeOptions.blockingStartTime
                )
                .padding()
            }
            .background(MPColors.background)
        }
    }
    return PreviewWrapper()
}
