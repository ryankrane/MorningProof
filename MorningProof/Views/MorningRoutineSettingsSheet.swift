import SwiftUI

struct MorningRoutineSettingsSheet: View {
    @ObservedObject var manager: MorningProofManager
    @Environment(\.dismiss) var dismiss

    @State private var cutoffMinutes: Int = 540
    @State private var customSleepGoal: Double = 7.0
    @State private var customStepGoal: Int = 500

    // Picker sheets
    @State private var showCutoffTimePicker = false
    @State private var showSleepGoalPicker = false
    @State private var showStepGoalPicker = false

    // Info alert
    @State private var showingHabitInfo: HabitType? = nil

    // Custom habits
    @State private var showCreateCustomHabit = false
    @State private var editingCustomHabit: CustomHabit? = nil
    @State private var showingCustomHabitInfo: CustomHabit? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: MPSpacing.xl) {
                        // MARK: - Habits
                        habitsSection

                        // MARK: - Custom Habits
                        if !manager.customHabits.isEmpty {
                            customHabitsSection
                        }

                        // MARK: - Goals
                        goalsSection

                        // MARK: - Schedule (compact row)
                        scheduleRow
                    }
                    .padding(.horizontal, MPSpacing.xl)
                    .padding(.top, MPSpacing.lg)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Morning Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        saveSettings()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(MPColors.textSecondary)
                    }
                }

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
            .sheet(isPresented: $showCreateCustomHabit) {
                CustomHabitCreationSheet(manager: manager)
            }
            .sheet(item: $editingCustomHabit) { habit in
                CustomHabitCreationSheet(manager: manager, editingHabit: habit)
            }
            .onAppear {
                loadSettings()
            }
            .overlay {
                // Custom popup overlay
                if let habitInfo = showingHabitInfo {
                    ZStack {
                        // Dimmed background - tap to dismiss
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showingHabitInfo = nil
                            }

                        // Popup card
                        VStack(spacing: MPSpacing.md) {
                            // Header with icon and title
                            HStack(spacing: MPSpacing.sm) {
                                Image(systemName: habitInfo.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(MPColors.primary)

                                Text(habitInfo.displayName)
                                    .font(MPFont.labelLarge())
                                    .foregroundColor(MPColors.textPrimary)
                            }

                            // Description
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
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showingHabitInfo)
            .overlay {
                // Custom habit info popup overlay
                if let customHabit = showingCustomHabitInfo {
                    ZStack {
                        // Dimmed background - tap to dismiss
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showingCustomHabitInfo = nil
                            }

                        // Popup card
                        VStack(spacing: MPSpacing.md) {
                            // Header with icon and title
                            HStack(spacing: MPSpacing.sm) {
                                Image(systemName: customHabit.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(MPColors.primary)

                                Text(customHabit.name)
                                    .font(MPFont.labelLarge())
                                    .foregroundColor(MPColors.textPrimary)
                            }

                            // Verification type
                            Text(customHabit.verificationType.displayName)
                                .font(MPFont.labelSmall())
                                .foregroundColor(MPColors.textTertiary)

                            // AI Prompt if present
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
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showingCustomHabitInfo != nil)
        }
        .swipeBack {
            saveSettings()
            dismiss()
        }
    }

    // MARK: - Schedule Row (Compact)

    var scheduleRow: some View {
        Button {
            showCutoffTimePicker = true
        } label: {
            HStack(spacing: MPSpacing.md) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MPColors.primary)

                Text("Morning Deadline")
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textPrimary)

                Spacer()

                Text(TimeOptions.formatTime(cutoffMinutes))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(MPColors.primary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MPColors.textTertiary)
            }
            .padding(.horizontal, MPSpacing.lg)
            .padding(.vertical, MPSpacing.md)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .mpShadow(.small)
        }
        .sheet(isPresented: $showCutoffTimePicker) {
            TimeWheelPicker(
                selectedMinutes: $cutoffMinutes,
                title: "Morning Deadline",
                subtitle: "Finish your routine by this time each day",
                timeOptions: TimeOptions.cutoffTime
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Habits Section

    var habitsSection: some View {
        // Sort habits by verification tier so similar habits are grouped together
        let sortedConfigs = manager.habitConfigs.sorted { $0.habitType.tier.rawValue < $1.habitType.tier.rawValue }

        return sectionContainer(title: "Habits", icon: "checkmark.circle.fill") {
            VStack(spacing: 0) {
                ForEach(sortedConfigs) { config in
                    habitToggleRow(config: config)

                    if config.id != sortedConfigs.last?.id {
                        Divider()
                            .padding(.leading, 46)
                    }
                }
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

    // MARK: - Custom Habits Section

    var customHabitsSection: some View {
        sectionContainer(title: "Custom Habits", icon: "star.fill") {
            VStack(spacing: 0) {
                ForEach(manager.customHabits) { habit in
                    customHabitRow(habit: habit)

                    if habit.id != manager.customHabits.last?.id {
                        Divider()
                            .padding(.leading, 46)
                    }
                }
            }
        }
    }

    func customHabitRow(habit: CustomHabit) -> some View {
        let config = manager.customHabitConfigs.first { $0.customHabitId == habit.id }
        let isEnabled = config?.isEnabled ?? true

        return HStack(spacing: MPSpacing.lg) {
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

                Text(habit.verificationType.displayName)
                    .font(MPFont.labelTiny())
                    .foregroundColor(MPColors.textTertiary)
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
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                manager.deleteCustomHabit(id: habit.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
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

    func habitToggleRow(config: HabitConfig) -> some View {
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

                Text(config.habitType.tier.description)
                    .font(MPFont.labelTiny())
                    .foregroundColor(MPColors.textTertiary)
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

#Preview {
    MorningRoutineSettingsSheet(manager: MorningProofManager.shared)
}
