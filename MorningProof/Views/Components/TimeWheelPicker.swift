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
