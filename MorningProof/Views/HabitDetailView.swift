import SwiftUI

/// Unified detail view for configuring a habit (predefined or custom)
struct HabitDetailView: View {
    @ObservedObject var manager: MorningProofManager
    @Environment(\.dismiss) var dismiss

    // Either a predefined habit type or a custom habit
    let habitType: HabitType?
    let customHabit: CustomHabit?

    @State private var isEnabled: Bool = true
    @State private var activeDays: Set<Int> = Set(1...7)
    @State private var sleepGoal: Double = 7.0
    @State private var stepGoal: Int = 500
    @State private var showSleepGoalPicker = false
    @State private var showStepGoalPicker = false
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false

    // Convenience init for predefined habit
    init(manager: MorningProofManager, habitType: HabitType) {
        self.manager = manager
        self.habitType = habitType
        self.customHabit = nil
    }

    // Convenience init for custom habit
    init(manager: MorningProofManager, customHabit: CustomHabit) {
        self.manager = manager
        self.habitType = nil
        self.customHabit = customHabit
    }

    private var displayName: String {
        habitType?.displayName ?? customHabit?.name ?? ""
    }

    private var icon: String {
        habitType?.icon ?? customHabit?.icon ?? "star.fill"
    }

    private var howItWorks: String {
        if let type = habitType {
            return type.howItWorksDetailed
        } else if let custom = customHabit {
            return customHabitDescription(for: custom)
        }
        return ""
    }

    private var verificationDescription: String {
        if let type = habitType {
            return type.tier.sectionTitle
        } else if let custom = customHabit {
            return custom.verificationType.displayName
        }
        return ""
    }

    private var verificationIcon: String {
        if let type = habitType {
            return type.tier.icon
        } else if let custom = customHabit {
            return custom.verificationType.icon
        }
        return "checkmark.circle"
    }

    var body: some View {
        ZStack {
            MPColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: MPSpacing.xxl) {
                    // Hero header
                    heroHeader

                    // Enable toggle section
                    enableSection

                    // Schedule section
                    scheduleSection

                    // Goal section (only for sleep and steps)
                    if let type = habitType {
                        if type == .sleepDuration {
                            sleepGoalSection
                        } else if type == .morningSteps {
                            stepGoalSection
                        }
                    }

                    // How it works section
                    howItWorksSection

                    // Custom habit actions (edit/delete)
                    if customHabit != nil {
                        customHabitActions
                    }

                    Spacer(minLength: MPSpacing.xxxl)
                }
                .padding(.horizontal, MPSpacing.xxl)
                .padding(.top, MPSpacing.md)
            }
        }
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadState() }
        .onDisappear { saveState() }
        .alert("Delete Habit", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let custom = customHabit {
                    manager.deleteCustomHabit(id: custom.id)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete \"\(customHabit?.name ?? "")\"? This cannot be undone.")
        }
        .sheet(isPresented: $showEditSheet) {
            if let custom = customHabit {
                CustomHabitCreationSheet(manager: manager, editingHabit: custom)
            }
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: MPSpacing.lg) {
            // Large icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [MPColors.primary.opacity(0.15), MPColors.primary.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)

                Image(systemName: icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(MPColors.primary)
            }

            // Verification badge
            HStack(spacing: 6) {
                Image(systemName: verificationIcon)
                    .font(.system(size: 12, weight: .medium))
                Text(verificationDescription)
                    .font(MPFont.labelSmall())
            }
            .foregroundColor(MPColors.textSecondary)
            .padding(.horizontal, MPSpacing.lg)
            .padding(.vertical, MPSpacing.sm)
            .background(MPColors.surfaceSecondary)
            .cornerRadius(MPRadius.full)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MPSpacing.xl)
    }

    // MARK: - Enable Section

    private var enableSection: some View {
        sectionContainer {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enabled")
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.textPrimary)
                    Text("Include in your daily routine")
                        .font(MPFont.labelSmall())
                        .foregroundColor(MPColors.textTertiary)
                }

                Spacer()

                Toggle("", isOn: $isEnabled)
                    .tint(MPColors.primary)
            }
            .padding(.vertical, MPSpacing.sm)
        }
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            sectionHeader(title: "SCHEDULE")

            sectionContainer {
                VStack(spacing: MPSpacing.lg) {
                    DaySchedulePicker(activeDays: $activeDays)

                    Text(DaySchedule.displayString(for: activeDays))
                        .font(MPFont.labelSmall())
                        .foregroundColor(MPColors.textSecondary)
                }
                .padding(.vertical, MPSpacing.sm)
            }
        }
    }

    // MARK: - Sleep Goal Section

    private var sleepGoalSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            sectionHeader(title: "GOAL")

            sectionContainer {
                Button {
                    showSleepGoalPicker = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sleep Target")
                                .font(MPFont.labelMedium())
                                .foregroundColor(MPColors.textPrimary)
                            Text("Hours of sleep per night")
                                .font(MPFont.labelTiny())
                                .foregroundColor(MPColors.textTertiary)
                        }

                        Spacer()

                        Text(formatSleepGoal(sleepGoal))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, MPSpacing.md)
                            .padding(.vertical, MPSpacing.sm)
                            .background(MPColors.primary)
                            .cornerRadius(MPRadius.md)
                    }
                    .padding(.vertical, MPSpacing.xs)
                }
            }
            .sheet(isPresented: $showSleepGoalPicker) {
                SleepGoalPicker(sleepGoal: $sleepGoal)
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Step Goal Section

    private var stepGoalSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            sectionHeader(title: "GOAL")

            sectionContainer {
                Button {
                    showStepGoalPicker = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Step Target")
                                .font(MPFont.labelMedium())
                                .foregroundColor(MPColors.textPrimary)
                            Text("Steps to hit each morning")
                                .font(MPFont.labelTiny())
                                .foregroundColor(MPColors.textTertiary)
                        }

                        Spacer()

                        Text("\(stepGoal)")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, MPSpacing.md)
                            .padding(.vertical, MPSpacing.sm)
                            .background(MPColors.primary)
                            .cornerRadius(MPRadius.md)
                    }
                    .padding(.vertical, MPSpacing.xs)
                }
            }
            .sheet(isPresented: $showStepGoalPicker) {
                StepGoalPicker(stepGoal: $stepGoal)
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: - How It Works Section

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            sectionHeader(title: "HOW IT WORKS")

            sectionContainer {
                Text(howItWorks)
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Custom Habit Actions

    private var customHabitActions: some View {
        VStack(spacing: MPSpacing.md) {
            Button {
                showEditSheet = true
            } label: {
                HStack {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .medium))
                    Text("Edit Habit")
                        .font(MPFont.labelMedium())
                }
                .foregroundColor(MPColors.primary)
                .frame(maxWidth: .infinity)
                .frame(height: MPButtonHeight.md)
                .background(MPColors.primary.opacity(0.1))
                .cornerRadius(MPRadius.md)
            }

            Button {
                showDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                    Text("Delete Habit")
                        .font(MPFont.labelMedium())
                }
                .foregroundColor(MPColors.error)
                .frame(maxWidth: .infinity)
                .frame(height: MPButtonHeight.md)
                .background(MPColors.error.opacity(0.1))
                .cornerRadius(MPRadius.md)
            }
        }
        .padding(.top, MPSpacing.lg)
    }

    // MARK: - Helpers

    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(MPColors.textTertiary)
            .tracking(0.8)
            .padding(.leading, MPSpacing.sm)
    }

    private func sectionContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack {
            content()
        }
        .padding(.horizontal, MPSpacing.xl)
        .padding(.vertical, MPSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
    }

    private func formatSleepGoal(_ hours: Double) -> String {
        if hours == floor(hours) {
            return "\(Int(hours))h"
        } else {
            let h = Int(hours)
            let m = Int((hours - Double(h)) * 60)
            return "\(h)h \(m)m"
        }
    }

    private func customHabitDescription(for habit: CustomHabit) -> String {
        switch habit.verificationType {
        case .aiVerified:
            if habit.mediaType == .video {
                return "Record a video showing \(cleanPromptForDisplay(habit.aiPrompt ?? "the action").lowercased()). AI will verify you completed it."
            } else if let prompt = habit.aiPrompt, !prompt.isEmpty {
                let cleaned = cleanPromptForDisplay(prompt)
                return "Take a photo showing \(cleaned.lowercased()). AI will verify it for you."
            } else {
                return "Take a photo and AI will verify you completed this habit."
            }
        case .honorSystem:
            return "Hold to confirm you completed this habit. We trust you!"
        }
    }

    private func cleanPromptForDisplay(_ prompt: String) -> String {
        var cleaned = prompt.trimmingCharacters(in: .whitespaces)
        let prefixesToRemove = [
            "make me show ", "make me ", "show me ", "show that ",
            "show ", "verify that ", "verify ", "check that ", "check if ", "check "
        ]
        let lowercased = cleaned.lowercased()
        for prefix in prefixesToRemove {
            if lowercased.hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count))
                break
            }
        }
        return cleaned
    }

    private func loadState() {
        if let type = habitType {
            if let config = manager.habitConfigs.first(where: { $0.habitType == type }) {
                isEnabled = config.isEnabled
                activeDays = config.activeDays
            }
            // Load goals from settings
            if type == .sleepDuration {
                sleepGoal = manager.settings.customSleepGoal
            } else if type == .morningSteps {
                stepGoal = manager.settings.customStepGoal
            }
        } else if let custom = customHabit {
            activeDays = custom.activeDays
            if let config = manager.customHabitConfigs.first(where: { $0.customHabitId == custom.id }) {
                isEnabled = config.isEnabled
            }
        }
    }

    private func saveState() {
        if let type = habitType {
            manager.updateHabitConfig(type, isEnabled: isEnabled)
            manager.updateHabitSchedule(type, activeDays: activeDays)

            // Save goals to settings
            if type == .sleepDuration {
                manager.settings.customSleepGoal = sleepGoal
            } else if type == .morningSteps {
                manager.settings.customStepGoal = stepGoal
            }
            manager.saveCurrentState()
        } else if let custom = customHabit {
            manager.toggleCustomHabit(custom.id, isEnabled: isEnabled)
            manager.updateCustomHabitSchedule(custom.id, activeDays: activeDays)
        }
    }
}

#Preview("Predefined Habit") {
    NavigationStack {
        HabitDetailView(
            manager: MorningProofManager.shared,
            habitType: .madeBed
        )
    }
}

#Preview("Sleep Habit") {
    NavigationStack {
        HabitDetailView(
            manager: MorningProofManager.shared,
            habitType: .sleepDuration
        )
    }
}
