import SwiftUI

struct RoutineTabView: View {
    @ObservedObject var manager: MorningProofManager

    @State private var cutoffMinutes: Int = 540
    @State private var customSleepGoal: Double = 7.0
    @State private var customStepGoal: Int = 500

    // Picker sheets
    @State private var showCutoffTimePicker = false
    @State private var showSleepGoalPicker = false
    @State private var showStepGoalPicker = false

    // Day schedule editing
    @State private var editingHabitSchedule: HabitType? = nil
    @State private var editingCustomHabitSchedule: CustomHabit? = nil

    // Info popups
    @State private var showingHabitInfo: HabitType? = nil
    @State private var showingCustomHabitInfo: CustomHabit? = nil

    // Custom habits
    @State private var showCreateCustomHabit = false
    @State private var editingCustomHabit: CustomHabit? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: MPSpacing.xl) {
                        // MARK: - Habit Deadline
                        deadlineSection

                        // MARK: - Habits
                        habitsSection

                        // MARK: - Custom Habits
                        customHabitsSection

                        // MARK: - Goals
                        goalsSection

                        Spacer(minLength: MPSpacing.xxxl)
                    }
                    .padding(.horizontal, MPSpacing.xl)
                    .padding(.top, MPSpacing.lg)
                }
            }
            .navigationTitle("Your Routine")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateCustomHabit = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(MPColors.primary)
                    }
                }
            }
            .onAppear {
                loadSettings()
            }
            .onDisappear {
                saveSettings()
            }
            .sheet(isPresented: $showCreateCustomHabit) {
                CustomHabitCreationSheet(manager: manager)
            }
            .sheet(item: $editingCustomHabit) { habit in
                CustomHabitCreationSheet(manager: manager, editingHabit: habit)
            }
            .sheet(item: $editingHabitSchedule) { habitType in
                DayScheduleSheetForHabit(
                    manager: manager,
                    habitType: habitType
                )
                .presentationDetents([.medium])
            }
            .sheet(item: $editingCustomHabitSchedule) { habit in
                DayScheduleSheetForCustomHabit(
                    manager: manager,
                    habit: habit
                )
                .presentationDetents([.medium])
            }
            .overlay {
                // Habit info popup overlay
                if let habitInfo = showingHabitInfo {
                    habitInfoPopup(habitInfo: habitInfo)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showingHabitInfo)
            .overlay {
                // Custom habit info popup overlay
                if let customHabit = showingCustomHabitInfo {
                    customHabitInfoPopup(customHabit: customHabit)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showingCustomHabitInfo != nil)
        }
    }

    // MARK: - Deadline Section

    var deadlineSection: some View {
        sectionContainer(title: "Schedule", icon: "clock.fill") {
            Button {
                showCutoffTimePicker = true
            } label: {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Habit Deadline")
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textPrimary)
                        Text("Complete habits by this time to lock in your day")
                            .font(MPFont.labelTiny())
                            .foregroundColor(MPColors.textTertiary)
                    }

                    Spacer()

                    Text(TimeOptions.formatTime(cutoffMinutes))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, MPSpacing.md)
                        .padding(.vertical, MPSpacing.sm)
                        .background(MPColors.primary)
                        .cornerRadius(MPRadius.md)
                }
                .padding(.vertical, MPSpacing.xs)
            }
            .sheet(isPresented: $showCutoffTimePicker) {
                TimeWheelPicker(
                    selectedMinutes: $cutoffMinutes,
                    title: "Habit Deadline",
                    subtitle: "Complete your habits by this time to lock in your day",
                    timeOptions: TimeOptions.cutoffTime
                )
                .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Habits Section

    var habitsSection: some View {
        let sortedConfigs = manager.habitConfigs.sorted { config1, config2 in
            // Enabled habits come first
            if config1.isEnabled != config2.isEnabled {
                return config1.isEnabled
            }
            // Within same enabled state, sort by verification tier
            return config1.habitType.tier.rawValue < config2.habitType.tier.rawValue
        }

        return sectionContainer(title: "Habits", icon: "checkmark.circle.fill") {
            VStack(spacing: 0) {
                ForEach(sortedConfigs) { config in
                    habitRow(config: config)

                    if config.id != sortedConfigs.last?.id {
                        Divider()
                            .padding(.leading, 46)
                    }
                }
            }
        }
    }

    func habitRow(config: HabitConfig) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: MPSpacing.lg) {
                Image(systemName: config.habitType.icon)
                    .font(.system(size: MPIconSize.sm))
                    .foregroundColor(config.isEnabled ? MPColors.primary : MPColors.textTertiary)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(config.habitType.displayName)
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textPrimary)

                        Button {
                            showingHabitInfo = config.habitType
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                                .foregroundColor(MPColors.textTertiary)
                        }
                    }

                    // Schedule indicator - tap to edit
                    Button {
                        editingHabitSchedule = config.habitType
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                            Text(DaySchedule.displayString(for: config.activeDays))
                                .font(MPFont.labelTiny())
                        }
                        .foregroundColor(config.isEnabled ? MPColors.primary : MPColors.textTertiary)
                    }
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { config.isEnabled },
                    set: { newValue in
                        manager.updateHabitConfig(config.habitType, isEnabled: newValue)
                    }
                ))
                .tint(MPColors.primary)
            }
            .padding(.vertical, MPSpacing.sm)
        }
    }

    // MARK: - Custom Habits Section

    var customHabitsSection: some View {
        sectionContainer(title: "Custom Habits", icon: "star.fill") {
            if manager.customHabits.isEmpty {
                HStack {
                    Text("No custom habits yet")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                    Spacer()
                    Button {
                        showCreateCustomHabit = true
                    } label: {
                        Text("Add")
                            .font(MPFont.labelSmall())
                            .foregroundColor(MPColors.primary)
                    }
                }
                .padding(.vertical, MPSpacing.sm)
            } else {
                let sortedCustomHabits = manager.customHabits.sorted { habit1, habit2 in
                    let config1 = manager.customHabitConfigs.first { $0.customHabitId == habit1.id }
                    let config2 = manager.customHabitConfigs.first { $0.customHabitId == habit2.id }
                    let enabled1 = config1?.isEnabled ?? true
                    let enabled2 = config2?.isEnabled ?? true

                    // Enabled habits come first
                    if enabled1 != enabled2 {
                        return enabled1
                    }
                    // Within same enabled state, sort by verification type
                    return habit1.verificationType.rawValue < habit2.verificationType.rawValue
                }

                VStack(spacing: 0) {
                    ForEach(sortedCustomHabits) { habit in
                        customHabitRow(habit: habit)

                        if habit.id != sortedCustomHabits.last?.id {
                            Divider()
                                .padding(.leading, 46)
                        }
                    }
                }
            }
        }
    }

    func customHabitRow(habit: CustomHabit) -> some View {
        let config = manager.customHabitConfigs.first { $0.customHabitId == habit.id }
        let isEnabled = config?.isEnabled ?? true

        return VStack(spacing: 0) {
            HStack(spacing: MPSpacing.lg) {
                Image(systemName: habit.icon)
                    .font(.system(size: MPIconSize.sm))
                    .foregroundColor(isEnabled ? MPColors.primary : MPColors.textTertiary)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(habit.name)
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textPrimary)

                        Button {
                            showingCustomHabitInfo = habit
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                                .foregroundColor(MPColors.textTertiary)
                        }
                    }

                    // Schedule indicator - tap to edit
                    Button {
                        editingCustomHabitSchedule = habit
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                            Text(DaySchedule.displayString(for: habit.activeDays))
                                .font(MPFont.labelTiny())
                        }
                        .foregroundColor(isEnabled ? MPColors.primary : MPColors.textTertiary)
                    }
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { isEnabled },
                    set: { newValue in
                        manager.toggleCustomHabit(habit.id, isEnabled: newValue)
                    }
                ))
                .tint(MPColors.primary)
            }
            .padding(.vertical, MPSpacing.sm)
            .contentShape(Rectangle())
            .onTapGesture {
                editingCustomHabit = habit
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                manager.deleteCustomHabit(id: habit.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Goals Section

    var goalsSection: some View {
        sectionContainer(title: "Habit Goals", icon: "target") {
            VStack(spacing: 0) {
                // Sleep goal
                Button {
                    showSleepGoalPicker = true
                } label: {
                    HStack(alignment: .center) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: MPIconSize.sm))
                            .foregroundColor(MPColors.primary)
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sleep Goal")
                                .font(MPFont.bodyMedium())
                                .foregroundColor(MPColors.textPrimary)
                            Text("Target hours of sleep")
                                .font(MPFont.labelTiny())
                                .foregroundColor(MPColors.textTertiary)
                        }

                        Spacer()

                        Text(formatSleepGoal(customSleepGoal))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, MPSpacing.md)
                            .padding(.vertical, MPSpacing.sm)
                            .background(MPColors.primary)
                            .cornerRadius(MPRadius.md)
                    }
                    .padding(.vertical, MPSpacing.xs)
                }
                .sheet(isPresented: $showSleepGoalPicker) {
                    SleepGoalPicker(sleepGoal: $customSleepGoal)
                        .presentationDetents([.medium])
                }

                Divider()
                    .padding(.leading, 46)

                // Step goal
                Button {
                    showStepGoalPicker = true
                } label: {
                    HStack(alignment: .center) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: MPIconSize.sm))
                            .foregroundColor(MPColors.primary)
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Step Goal")
                                .font(MPFont.bodyMedium())
                                .foregroundColor(MPColors.textPrimary)
                            Text("Morning steps target")
                                .font(MPFont.labelTiny())
                                .foregroundColor(MPColors.textTertiary)
                        }

                        Spacer()

                        Text("\(customStepGoal)")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, MPSpacing.md)
                            .padding(.vertical, MPSpacing.sm)
                            .background(MPColors.primary)
                            .cornerRadius(MPRadius.md)
                    }
                    .padding(.vertical, MPSpacing.xs)
                }
                .sheet(isPresented: $showStepGoalPicker) {
                    StepGoalPicker(stepGoal: $customStepGoal)
                        .presentationDetents([.medium])
                }
            }
        }
    }

    // MARK: - Info Popups

    func habitInfoPopup(habitInfo: HabitType) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showingHabitInfo = nil
                }

            VStack(spacing: MPSpacing.md) {
                HStack(spacing: MPSpacing.sm) {
                    Image(systemName: habitInfo.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(MPColors.primary)

                    Text(habitInfo.displayName)
                        .font(MPFont.labelLarge())
                        .foregroundColor(MPColors.textPrimary)
                }

                Text(habitInfo.howItWorksDetailed)
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(MPSpacing.xl)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .mpShadow(.medium)
            .padding(.horizontal, MPSpacing.xxl)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    func customHabitInfoPopup(customHabit: CustomHabit) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showingCustomHabitInfo = nil
                }

            VStack(spacing: MPSpacing.md) {
                HStack(spacing: MPSpacing.sm) {
                    Image(systemName: customHabit.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(MPColors.primary)

                    Text(customHabit.name)
                        .font(MPFont.labelLarge())
                        .foregroundColor(MPColors.textPrimary)
                }

                Text(customHabit.verificationType.displayName)
                    .font(MPFont.labelSmall())
                    .foregroundColor(MPColors.textTertiary)

                if let prompt = customHabit.aiPrompt, !prompt.isEmpty {
                    VStack(spacing: MPSpacing.xs) {
                        Text("Verification Instructions:")
                            .font(MPFont.labelSmall())
                            .foregroundColor(MPColors.textSecondary)

                        Text("\"\(prompt)\"")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textPrimary)
                            .italic()
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, MPSpacing.sm)
                }
            }
            .padding(MPSpacing.xl)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .mpShadow(.medium)
            .padding(.horizontal, MPSpacing.xxl)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    // MARK: - Helpers

    func sectionContainer<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            HStack(spacing: MPSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MPColors.textTertiary)
                Text(title.uppercased())
                    .font(MPFont.labelSmall())
                    .foregroundColor(MPColors.textTertiary)
                    .tracking(0.5)
            }
            .padding(.leading, MPSpacing.xs)

            VStack {
                content()
            }
            .padding(.horizontal, MPSpacing.lg)
            .padding(.vertical, MPSpacing.md)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .mpShadow(.small)
        }
    }

    private func formatSleepGoal(_ hours: Double) -> String {
        if hours == floor(hours) {
            return "\(Int(hours))h"
        } else {
            return String(format: "%.1fh", hours)
        }
    }

    func loadSettings() {
        cutoffMinutes = manager.settings.morningCutoffMinutes
        customSleepGoal = manager.settings.customSleepGoal
        customStepGoal = manager.settings.customStepGoal
    }

    func saveSettings() {
        manager.settings.morningCutoffMinutes = cutoffMinutes
        manager.settings.customSleepGoal = customSleepGoal
        manager.settings.customStepGoal = customStepGoal
        manager.saveCurrentState()
    }
}

// MARK: - Day Schedule Sheet for Predefined Habit

private struct DayScheduleSheetForHabit: View {
    @ObservedObject var manager: MorningProofManager
    let habitType: HabitType
    @Environment(\.dismiss) var dismiss

    @State private var activeDays: Set<Int> = Set(1...7)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: MPSpacing.xs) {
                    Text("Schedule")
                        .font(MPFont.headingSmall())
                        .foregroundColor(MPColors.textPrimary)

                    Text("Which days should \"\(habitType.displayName)\" be active?")
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

                    Text(DaySchedule.displayString(for: activeDays))
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(MPColors.primary)
                        .padding(.top, MPSpacing.lg)
                }

                Spacer()

                Button {
                    manager.updateHabitSchedule(habitType, activeDays: activeDays)
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
            .onAppear {
                if let config = manager.habitConfigs.first(where: { $0.habitType == habitType }) {
                    activeDays = config.activeDays
                }
            }
        }
    }
}

// MARK: - Day Schedule Sheet for Custom Habit

private struct DayScheduleSheetForCustomHabit: View {
    @ObservedObject var manager: MorningProofManager
    let habit: CustomHabit
    @Environment(\.dismiss) var dismiss

    @State private var activeDays: Set<Int> = Set(1...7)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: MPSpacing.xs) {
                    Text("Schedule")
                        .font(MPFont.headingSmall())
                        .foregroundColor(MPColors.textPrimary)

                    Text("Which days should \"\(habit.name)\" be active?")
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

                    Text(DaySchedule.displayString(for: activeDays))
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(MPColors.primary)
                        .padding(.top, MPSpacing.lg)
                }

                Spacer()

                Button {
                    manager.updateCustomHabitSchedule(habit.id, activeDays: activeDays)
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
            .onAppear {
                activeDays = habit.activeDays
            }
        }
    }
}

#Preview {
    RoutineTabView(manager: MorningProofManager.shared)
}
