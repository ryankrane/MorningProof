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

                        // MARK: - Goals
                        goalsSection
                    }
                    .padding(.horizontal, MPSpacing.xl)
                    .padding(.top, MPSpacing.lg)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Morning Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(MPColors.primary)
                }
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
