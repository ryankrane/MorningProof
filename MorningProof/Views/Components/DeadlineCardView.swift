import SwiftUI

// MARK: - Customization Mode

enum DeadlineCustomizationMode: Int, CaseIterable {
    case sameEveryDay = 0
    case weekdayWeekend = 1
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

/// A settings-style card for deadline selection with three customization modes.
/// Clean main card design with a full-featured picker sheet.
struct DeadlineCardView: View {
    // Single deadline (used when mode is .sameEveryDay)
    @Binding var cutoffMinutes: Int

    // Customization mode (0 = same every day, 1 = weekday/weekend, 2 = each day)
    @Binding var customizationMode: Int

    // Weekday/weekend deadlines (used when mode is .weekdayWeekend)
    @Binding var weekdayDeadlineMinutes: Int
    @Binding var weekendDeadlineMinutes: Int

    // Per-day deadlines (used when mode is .eachDay)
    // Index 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    @Binding var perDayDeadlineMinutes: [Int]

    @State private var showDeadlineSheet = false

    private var mode: DeadlineCustomizationMode {
        DeadlineCustomizationMode(rawValue: customizationMode) ?? .sameEveryDay
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.sm) {
            Text("DEADLINE")
                .font(MPFont.labelSmall())
                .foregroundColor(MPColors.textTertiary)
                .tracking(0.5)
                .padding(.leading, MPSpacing.xs)

            Button {
                showDeadlineSheet = true
            } label: {
                VStack(spacing: 0) {
                    switch mode {
                    case .sameEveryDay:
                        singleDeadlineRow
                    case .weekdayWeekend:
                        weekdayWeekendSummaryRow
                    case .eachDay:
                        perDaySummaryRow
                    }
                }
                .background(MPColors.surface)
                .cornerRadius(MPRadius.lg)
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showDeadlineSheet) {
            DeadlinePickerSheet(
                cutoffMinutes: $cutoffMinutes,
                customizationMode: $customizationMode,
                weekdayDeadlineMinutes: $weekdayDeadlineMinutes,
                weekendDeadlineMinutes: $weekendDeadlineMinutes,
                perDayDeadlineMinutes: $perDayDeadlineMinutes
            )
            .presentationDetents([.large])
        }
    }

    // MARK: - Main Card Rows

    /// Row for same every day: "Complete by   9:00 AM  >"
    private var singleDeadlineRow: some View {
        HStack {
            Text("Complete by")
                .font(.system(size: 17))
                .foregroundColor(MPColors.textPrimary)

            Spacer()

            Text(TimeOptions.formatTime(cutoffMinutes))
                .font(.system(size: 17))
                .foregroundColor(MPColors.primary)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MPColors.textMuted)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, MPSpacing.lg)
    }

    /// Row for weekday/weekend mode showing both times
    private var weekdayWeekendSummaryRow: some View {
        HStack(alignment: .top) {
            Text("Complete by")
                .font(.system(size: 17))
                .foregroundColor(MPColors.textPrimary)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Weekdays")
                        .font(.system(size: 15))
                        .foregroundColor(MPColors.textSecondary)
                    Text(TimeOptions.formatTime(weekdayDeadlineMinutes))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(MPColors.primary)
                }

                HStack(spacing: 6) {
                    Text("Weekends")
                        .font(.system(size: 15))
                        .foregroundColor(MPColors.textSecondary)
                    Text(TimeOptions.formatTime(weekendDeadlineMinutes))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(MPColors.primary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MPColors.textMuted)
                .padding(.leading, 4)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, MPSpacing.lg)
    }

    /// Row for per-day mode showing week strip preview
    private var perDaySummaryRow: some View {
        HStack(alignment: .center) {
            Text("Complete by")
                .font(.system(size: 17))
                .foregroundColor(MPColors.textPrimary)

            Spacer()

            // Compact week preview
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 2) {
                        Text(dayLabels[index])
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(MPColors.textTertiary)
                        Text(shortTime(perDayDeadlineMinutes[index]))
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(MPColors.primary)
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MPColors.textMuted)
                .padding(.leading, 8)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, MPSpacing.lg)
    }

    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    private func shortTime(_ minutes: Int) -> String {
        let hour = minutes / 60
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        let period = hour >= 12 ? "p" : "a"
        return "\(displayHour)\(period)"
    }
}

// MARK: - Deadline Picker Sheet

/// Full-featured sheet for configuring morning deadline with three modes
private struct DeadlinePickerSheet: View {
    @Binding var cutoffMinutes: Int
    @Binding var customizationMode: Int
    @Binding var weekdayDeadlineMinutes: Int
    @Binding var weekendDeadlineMinutes: Int
    @Binding var perDayDeadlineMinutes: [Int]

    @Environment(\.dismiss) var dismiss

    // Local state copies - only applied when "Set Time" is pressed
    @State private var localCutoffMinutes: Int
    @State private var localMode: DeadlineCustomizationMode
    @State private var localWeekdayMinutes: Int
    @State private var localWeekendMinutes: Int
    @State private var localPerDayMinutes: [Int]

    // Picker state
    @State private var selectedHour: Int = 9
    @State private var selectedMinute: Int = 0
    @State private var selectedPeriod: String = "AM"

    // Track which day is being edited (for per-day mode)
    // nil = editing "main" time, 0-6 = editing specific day
    @State private var editingDayIndex: Int? = nil

    // Sub-picker sheet for individual day editing
    @State private var showDayPicker = false
    @State private var dayPickerIndex: Int = 0

    private let hours = Array(1...12)
    private let availableMinutes = [0, 15, 30, 45]
    private let periods = ["AM", "PM"]
    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    private let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    init(
        cutoffMinutes: Binding<Int>,
        customizationMode: Binding<Int>,
        weekdayDeadlineMinutes: Binding<Int>,
        weekendDeadlineMinutes: Binding<Int>,
        perDayDeadlineMinutes: Binding<[Int]>
    ) {
        self._cutoffMinutes = cutoffMinutes
        self._customizationMode = customizationMode
        self._weekdayDeadlineMinutes = weekdayDeadlineMinutes
        self._weekendDeadlineMinutes = weekendDeadlineMinutes
        self._perDayDeadlineMinutes = perDayDeadlineMinutes

        // Initialize local state
        let mode = DeadlineCustomizationMode(rawValue: customizationMode.wrappedValue) ?? .sameEveryDay
        _localCutoffMinutes = State(initialValue: cutoffMinutes.wrappedValue)
        _localMode = State(initialValue: mode)
        _localWeekdayMinutes = State(initialValue: weekdayDeadlineMinutes.wrappedValue)
        _localWeekendMinutes = State(initialValue: weekendDeadlineMinutes.wrappedValue)
        _localPerDayMinutes = State(initialValue: perDayDeadlineMinutes.wrappedValue)

        // Initialize picker from current mode's primary time
        let mins: Int
        switch mode {
        case .sameEveryDay:
            mins = cutoffMinutes.wrappedValue
        case .weekdayWeekend:
            mins = weekdayDeadlineMinutes.wrappedValue
        case .eachDay:
            mins = perDayDeadlineMinutes.wrappedValue[1] // Monday
        }

        let hour24 = mins / 60
        let minute = mins % 60
        _selectedHour = State(initialValue: hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24))
        _selectedMinute = State(initialValue: minute)
        _selectedPeriod = State(initialValue: hour24 >= 12 ? "PM" : "AM")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: MPSpacing.xs) {
                        Text("Morning Deadline")
                            .font(MPFont.headingSmall())
                            .foregroundColor(MPColors.textPrimary)

                        Text("Finish your routine by this time")
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textSecondary)
                    }
                    .padding(.top, MPSpacing.xl)
                    .padding(.bottom, MPSpacing.lg)

                    // Wheel pickers
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
                    .padding(.horizontal, MPSpacing.xl)
                    .onChange(of: selectedHour) { syncPickerToLocal() }
                    .onChange(of: selectedMinute) { syncPickerToLocal() }
                    .onChange(of: selectedPeriod) { syncPickerToLocal() }

                    // Large time display with editing context
                    VStack(spacing: 4) {
                        Text(formattedPickerTime)
                            .font(.system(size: 48, weight: .semibold, design: .rounded))
                            .foregroundColor(MPColors.primary)

                        if let dayIndex = editingDayIndex {
                            Text("for \(dayNames[dayIndex])")
                                .font(.system(size: 15))
                                .foregroundColor(MPColors.textSecondary)
                        }
                    }
                    .padding(.top, MPSpacing.sm)
                    .padding(.bottom, MPSpacing.lg)

                    // Mode selection and configuration
                    VStack(spacing: 0) {
                        // Mode picker
                        Picker("Schedule", selection: $localMode) {
                            ForEach(DeadlineCustomizationMode.allCases, id: \.rawValue) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, MPSpacing.lg)
                        .padding(.vertical, 14)
                        .onChange(of: localMode) { _, newMode in
                            handleModeChange(to: newMode)
                        }

                        // Mode-specific content
                        switch localMode {
                        case .sameEveryDay:
                            // No additional content needed - picker controls everything
                            EmptyView()

                        case .weekdayWeekend:
                            weekdayWeekendContent

                        case .eachDay:
                            eachDayContent
                        }
                    }
                    .background(MPColors.surface)
                    .cornerRadius(MPRadius.lg)
                    .padding(.horizontal, MPSpacing.lg)

                    Spacer(minLength: MPSpacing.xxxl)

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
        .sheet(isPresented: $showDayPicker) {
            DayTimePickerSheet(
                dayName: dayNames[dayPickerIndex],
                minutes: Binding(
                    get: { localPerDayMinutes[dayPickerIndex] },
                    set: { localPerDayMinutes[dayPickerIndex] = $0 }
                )
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Weekday/Weekend Content

    private var weekdayWeekendContent: some View {
        VStack(spacing: 0) {
            Divider()
                .background(MPColors.divider)
                .padding(.leading, MPSpacing.lg)

            // Week strip visualization
            weekStripView(mode: .weekdayWeekend)
                .padding(.vertical, 14)
                .padding(.horizontal, MPSpacing.lg)

            Divider()
                .background(MPColors.divider)
                .padding(.leading, MPSpacing.lg)

            // Weekday row
            Button {
                editingDayIndex = nil
                syncLocalToPicker(localWeekdayMinutes)
            } label: {
                timeRow(
                    label: "Weekdays",
                    time: TimeOptions.formatTime(localWeekdayMinutes),
                    isSelected: editingDayIndex == nil && localMode == .weekdayWeekend
                )
            }
            .buttonStyle(.plain)

            Divider()
                .background(MPColors.divider)
                .padding(.leading, MPSpacing.lg)

            // Weekend row
            Button {
                // For weekends, we'll use day index 0 (Sunday) as marker
                editingDayIndex = 0
                syncLocalToPicker(localWeekendMinutes)
            } label: {
                timeRow(
                    label: "Weekends",
                    time: TimeOptions.formatTime(localWeekendMinutes),
                    isSelected: editingDayIndex == 0 && localMode == .weekdayWeekend
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Each Day Content

    private var eachDayContent: some View {
        VStack(spacing: 0) {
            Divider()
                .background(MPColors.divider)
                .padding(.leading, MPSpacing.lg)

            // Week strip visualization (tappable)
            weekStripView(mode: .eachDay)
                .padding(.vertical, 14)
                .padding(.horizontal, MPSpacing.lg)

            // All 7 days
            ForEach(0..<7, id: \.self) { index in
                VStack(spacing: 0) {
                    Divider()
                        .background(MPColors.divider)
                        .padding(.leading, MPSpacing.lg)

                    Button {
                        editingDayIndex = index
                        syncLocalToPicker(localPerDayMinutes[index])
                    } label: {
                        timeRow(
                            label: dayNames[index],
                            time: TimeOptions.formatTime(localPerDayMinutes[index]),
                            isSelected: editingDayIndex == index && localMode == .eachDay
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Week Strip View

    private func weekStripView(mode: DeadlineCustomizationMode) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(0..<7), id: \.self) { index in
                weekStripDay(index: index, mode: mode)
            }
        }
    }

    @ViewBuilder
    private func weekStripDay(index: Int, mode: DeadlineCustomizationMode) -> some View {
        let isWeekend = index == 0 || index == 6
        let minutes = minutesForDay(index: index, mode: mode)
        let isSelected = isDaySelected(index: index, mode: mode, isWeekend: isWeekend)

        VStack(spacing: 4) {
            Text(dayLabels[index])
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? MPColors.primary : MPColors.textSecondary)

            Text(shortTime(minutes))
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? MPColors.primary : MPColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(isSelected ? MPColors.primaryLight : Color.clear)
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            handleDayTap(index: index, mode: mode, isWeekend: isWeekend)
        }
    }

    private func minutesForDay(index: Int, mode: DeadlineCustomizationMode) -> Int {
        let isWeekend = index == 0 || index == 6
        switch mode {
        case .sameEveryDay:
            return localCutoffMinutes
        case .weekdayWeekend:
            return isWeekend ? localWeekendMinutes : localWeekdayMinutes
        case .eachDay:
            return localPerDayMinutes[index]
        }
    }

    private func isDaySelected(index: Int, mode: DeadlineCustomizationMode, isWeekend: Bool) -> Bool {
        (mode == .eachDay && editingDayIndex == index) ||
        (mode == .weekdayWeekend && editingDayIndex == nil && !isWeekend) ||
        (mode == .weekdayWeekend && editingDayIndex == 0 && isWeekend)
    }

    private func handleDayTap(index: Int, mode: DeadlineCustomizationMode, isWeekend: Bool) {
        if mode == .eachDay {
            editingDayIndex = index
            syncLocalToPicker(localPerDayMinutes[index])
        } else if mode == .weekdayWeekend {
            if isWeekend {
                editingDayIndex = 0
                syncLocalToPicker(localWeekendMinutes)
            } else {
                editingDayIndex = nil
                syncLocalToPicker(localWeekdayMinutes)
            }
        }
    }

    // MARK: - Time Row

    private func timeRow(label: String, time: String, isSelected: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 17))
                .foregroundColor(MPColors.textPrimary)

            Spacer()

            Text(time)
                .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                .foregroundColor(MPColors.primary)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MPColors.primary)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, MPSpacing.lg)
        .background(isSelected ? MPColors.primaryLight.opacity(0.3) : Color.clear)
    }

    // MARK: - Helper Functions

    private var formattedPickerTime: String {
        String(format: "%d:%02d %@", selectedHour, selectedMinute, selectedPeriod)
    }

    private func shortTime(_ minutes: Int) -> String {
        let hour = minutes / 60
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        let period = hour >= 12 ? "p" : "a"
        return "\(displayHour)\(period)"
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

    private func syncPickerToLocal() {
        let mins = pickerToMinutes()

        switch localMode {
        case .sameEveryDay:
            localCutoffMinutes = mins

        case .weekdayWeekend:
            if editingDayIndex == 0 {
                // Editing weekends
                localWeekendMinutes = mins
            } else {
                // Editing weekdays (nil or any weekday index)
                localWeekdayMinutes = mins
            }

        case .eachDay:
            if let dayIndex = editingDayIndex {
                localPerDayMinutes[dayIndex] = mins
            }
        }
    }

    private func syncLocalToPicker(_ minutes: Int) {
        let hour24 = minutes / 60
        let minute = minutes % 60

        selectedHour = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24)
        selectedMinute = minute
        selectedPeriod = hour24 >= 12 ? "PM" : "AM"
    }

    private func handleModeChange(to newMode: DeadlineCustomizationMode) {
        editingDayIndex = nil

        switch newMode {
        case .sameEveryDay:
            // Use current cutoff or average
            syncLocalToPicker(localCutoffMinutes)

        case .weekdayWeekend:
            // Initialize from current cutoff if switching from same every day
            if localWeekdayMinutes == localWeekendMinutes {
                localWeekdayMinutes = localCutoffMinutes
            }
            syncLocalToPicker(localWeekdayMinutes)

        case .eachDay:
            // Initialize all days from weekday/weekend values if not already customized
            let allSame = Set(localPerDayMinutes).count == 1
            if allSame {
                for i in 0..<7 {
                    let isWeekend = i == 0 || i == 6
                    localPerDayMinutes[i] = isWeekend ? localWeekendMinutes : localWeekdayMinutes
                }
            }
            editingDayIndex = 1 // Start with Monday
            syncLocalToPicker(localPerDayMinutes[1])
        }
    }

    private func applyChanges() {
        customizationMode = localMode.rawValue
        cutoffMinutes = localCutoffMinutes
        weekdayDeadlineMinutes = localWeekdayMinutes
        weekendDeadlineMinutes = localWeekendMinutes
        perDayDeadlineMinutes = localPerDayMinutes
    }
}

// MARK: - Day Time Picker Sheet

/// Simple time picker for a single day
private struct DayTimePickerSheet: View {
    let dayName: String
    @Binding var minutes: Int
    @Environment(\.dismiss) var dismiss

    @State private var selectedHour: Int
    @State private var selectedMinute: Int
    @State private var selectedPeriod: String

    private let hours = Array(1...12)
    private let availableMinutes = [0, 15, 30, 45]
    private let periods = ["AM", "PM"]

    init(dayName: String, minutes: Binding<Int>) {
        self.dayName = dayName
        self._minutes = minutes

        let hour24 = minutes.wrappedValue / 60
        let minute = minutes.wrappedValue % 60

        _selectedHour = State(initialValue: hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24))
        _selectedMinute = State(initialValue: minute)
        _selectedPeriod = State(initialValue: hour24 >= 12 ? "PM" : "AM")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: MPSpacing.xs) {
                    Text(dayName)
                        .font(MPFont.headingSmall())
                        .foregroundColor(MPColors.textPrimary)

                    Text("Set deadline for this day")
                        .font(MPFont.bodyMedium())
                        .foregroundColor(MPColors.textSecondary)
                }
                .padding(.top, MPSpacing.xl)
                .padding(.bottom, MPSpacing.lg)

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
                .frame(height: 180)

                Text(formattedTime)
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .foregroundColor(MPColors.primary)
                    .padding(.vertical, MPSpacing.xl)

                Spacer()

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
        var hour24 = selectedHour
        if selectedPeriod == "AM" {
            if selectedHour == 12 { hour24 = 0 }
        } else {
            if selectedHour != 12 { hour24 = selectedHour + 12 }
        }
        minutes = hour24 * 60 + selectedMinute
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State var cutoffMinutes = 540
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

                    Picker("Mode", selection: $mode) {
                        Text("Same every day").tag(0)
                        Text("Weekdays/Weekends").tag(1)
                        Text("Each day").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cutoff: \(cutoffMinutes)")
                        Text("Weekday: \(weekdayMinutes)")
                        Text("Weekend: \(weekendMinutes)")
                        Text("Per-day: \(perDayMinutes.map { "\($0)" }.joined(separator: ", "))")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .background(MPColors.background)
        }
    }
    return PreviewWrapper()
}
