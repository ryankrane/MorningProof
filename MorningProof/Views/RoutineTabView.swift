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
    @State private var showScheduleSheet = false
    @State private var editingHabitSchedule: HabitType? = nil
    @State private var editingCustomHabitSchedule: CustomHabit? = nil

    // Info popups
    @State private var showingHabitInfo: HabitType? = nil
    @State private var showingCustomHabitInfo: CustomHabit? = nil

    // Custom habits
    @State private var showCreateCustomHabit = false
    @State private var editingCustomHabit: CustomHabit? = nil
    @State private var addingToSection: CustomVerificationType? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: MPSpacing.xl) {
                        // MARK: - Habit Deadline
                        deadlineSection

                        // MARK: - Habits by Verification Type
                        unifiedHabitsSection

                        // MARK: - Habit Schedule
                        weeklyScheduleSection

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
            .onAppear {
                loadSettings()
            }
            .onDisappear {
                saveSettings()
            }
            .sheet(isPresented: $showCreateCustomHabit) {
                CustomHabitCreationSheet(manager: manager, preselectedVerificationType: addingToSection)
            }
            .onChange(of: showCreateCustomHabit) { _, isPresented in
                // Clear preselection when sheet is dismissed
                if !isPresented {
                    addingToSection = nil
                }
            }
            .sheet(item: $editingCustomHabit) { habit in
                CustomHabitCreationSheet(manager: manager, editingHabit: habit)
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
        sectionContainer(title: "Deadline", icon: "clock.fill") {
            Button {
                showCutoffTimePicker = true
            } label: {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Habit Deadline")
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textPrimary)
                        Text("Finish your habits by this time")
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

    // MARK: - Unified Habits Section (Organized by Verification Type)

    var unifiedHabitsSection: some View {
        VStack(spacing: MPSpacing.xl) {
            // AI Verified Section
            aiVerifiedSection

            // Apple Health Section
            appleHealthSection

            // Self-Reported Section
            selfReportedSection
        }
    }

    // MARK: - AI Verified Section

    var aiVerifiedSection: some View {
        let predefinedHabits = manager.habitConfigs.filter { $0.habitType.tier == .aiVerified }
            .sorted { config1, config2 in
                if config1.isEnabled != config2.isEnabled { return config1.isEnabled }
                return config1.displayOrder < config2.displayOrder
            }

        let customHabits = manager.customHabits.filter { $0.verificationType == .aiVerified }
            .sorted { habit1, habit2 in
                let config1 = manager.customHabitConfigs.first { $0.customHabitId == habit1.id }
                let config2 = manager.customHabitConfigs.first { $0.customHabitId == habit2.id }
                let enabled1 = config1?.isEnabled ?? true
                let enabled2 = config2?.isEnabled ?? true
                if enabled1 != enabled2 { return enabled1 }
                return habit1.createdAt < habit2.createdAt
            }

        return habitSectionContainer(
            title: HabitVerificationTier.aiVerified.sectionTitle,
            icon: HabitVerificationTier.aiVerified.icon,
            showAddButton: true,
            onAdd: {
                addingToSection = .aiVerified
                showCreateCustomHabit = true
            }
        ) {
            VStack(spacing: 0) {
                // Predefined habits
                ForEach(predefinedHabits) { config in
                    habitRow(config: config)
                    Divider().padding(.leading, 46)
                }

                // Custom habits
                ForEach(customHabits) { habit in
                    customHabitRow(habit: habit)
                    if habit.id != customHabits.last?.id || true {
                        Divider().padding(.leading, 46)
                    }
                }

                // Inline add button
                addHabitButton(verificationType: .aiVerified)
            }
        }
    }

    // MARK: - Apple Health Section

    var appleHealthSection: some View {
        let predefinedHabits = manager.habitConfigs.filter { $0.habitType.tier == .autoTracked }
            .sorted { config1, config2 in
                if config1.isEnabled != config2.isEnabled { return config1.isEnabled }
                return config1.displayOrder < config2.displayOrder
            }

        return habitSectionContainer(
            title: HabitVerificationTier.autoTracked.sectionTitle,
            icon: HabitVerificationTier.autoTracked.icon,
            showAddButton: false,
            onAdd: {}
        ) {
            VStack(spacing: 0) {
                ForEach(Array(predefinedHabits.enumerated()), id: \.element.id) { index, config in
                    habitRow(config: config)
                    if index < predefinedHabits.count - 1 {
                        Divider().padding(.leading, 46)
                    }
                }
            }
        }
    }

    // MARK: - Self-Reported Section

    var selfReportedSection: some View {
        let predefinedHabits = manager.habitConfigs.filter { $0.habitType.tier == .honorSystem }
            .sorted { config1, config2 in
                if config1.isEnabled != config2.isEnabled { return config1.isEnabled }
                return config1.displayOrder < config2.displayOrder
            }

        let customHabits = manager.customHabits.filter { $0.verificationType == .honorSystem }
            .sorted { habit1, habit2 in
                let config1 = manager.customHabitConfigs.first { $0.customHabitId == habit1.id }
                let config2 = manager.customHabitConfigs.first { $0.customHabitId == habit2.id }
                let enabled1 = config1?.isEnabled ?? true
                let enabled2 = config2?.isEnabled ?? true
                if enabled1 != enabled2 { return enabled1 }
                return habit1.createdAt < habit2.createdAt
            }

        return habitSectionContainer(
            title: HabitVerificationTier.honorSystem.sectionTitle,
            icon: HabitVerificationTier.honorSystem.icon,
            showAddButton: true,
            onAdd: {
                addingToSection = .honorSystem
                showCreateCustomHabit = true
            }
        ) {
            VStack(spacing: 0) {
                // Predefined habits
                ForEach(predefinedHabits) { config in
                    habitRow(config: config)
                    Divider().padding(.leading, 46)
                }

                // Custom habits
                ForEach(customHabits) { habit in
                    customHabitRow(habit: habit)
                    if habit.id != customHabits.last?.id || true {
                        Divider().padding(.leading, 46)
                    }
                }

                // Inline add button
                addHabitButton(verificationType: .honorSystem)
            }
        }
    }

    // MARK: - Section Container with Optional Add Button

    func habitSectionContainer<Content: View>(
        title: String,
        icon: String,
        showAddButton: Bool,
        onAdd: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            HStack(spacing: MPSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MPColors.textTertiary)
                Text(title.uppercased())
                    .font(MPFont.labelSmall())
                    .foregroundColor(MPColors.textTertiary)
                    .tracking(0.5)

                Spacer()

                if showAddButton {
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(MPColors.primary.opacity(0.8))
                    }
                }
            }
            .padding(.leading, MPSpacing.xs)
            .padding(.trailing, MPSpacing.xs)

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

    // MARK: - Inline Add Button

    func addHabitButton(verificationType: CustomVerificationType) -> some View {
        Button {
            addingToSection = verificationType
            showCreateCustomHabit = true
        } label: {
            HStack(spacing: MPSpacing.lg) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MPColors.primary)
                    .frame(width: 30)

                Text("Add Custom Habit")
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.primary)

                Spacer()
            }
            .padding(.vertical, MPSpacing.sm)
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

                    // Verification method indicator
                    HStack(spacing: 4) {
                        Image(systemName: config.habitType.tier.icon)
                            .font(.system(size: 10))
                        Text(config.habitType.tier.sectionTitle)
                            .font(MPFont.labelTiny())
                    }
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

                    // Verification method indicator
                    HStack(spacing: 4) {
                        Image(systemName: habit.verificationType.icon)
                            .font(.system(size: 10))
                        Text(habit.verificationType.displayName)
                            .font(MPFont.labelTiny())
                    }
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
        }
    }

    // MARK: - Weekly Schedule Section

    var weeklyScheduleSection: some View {
        // Collect enabled predefined habits
        let enabledPredefined = manager.habitConfigs.filter { $0.isEnabled }

        // Collect enabled custom habits
        let enabledCustom = manager.customHabits.filter { habit in
            let config = manager.customHabitConfigs.first { $0.customHabitId == habit.id }
            return config?.isEnabled ?? true
        }

        let totalEnabled = enabledPredefined.count + enabledCustom.count

        return sectionContainer(title: "Habit Schedule", icon: "calendar") {
            Button {
                showScheduleSheet = true
            } label: {
                HStack(spacing: MPSpacing.lg) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Manage Schedule")
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textPrimary)
                        Text(scheduleSubtitle(enabledCount: totalEnabled))
                            .font(MPFont.labelTiny())
                            .foregroundColor(MPColors.textTertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MPColors.textTertiary)
                }
                .padding(.vertical, MPSpacing.sm)
            }
        }
        .sheet(isPresented: $showScheduleSheet) {
            ScheduleOverviewSheet(
                manager: manager,
                editingHabitSchedule: $editingHabitSchedule,
                editingCustomHabitSchedule: $editingCustomHabitSchedule
            )
        }
    }

    private func scheduleSubtitle(enabledCount: Int) -> String {
        if enabledCount == 0 {
            return "No habits enabled"
        } else if enabledCount == 1 {
            return "1 habit scheduled"
        } else {
            return "\(enabledCount) habits scheduled"
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

                Text(customHabitDescription(for: customHabit))
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                // Action buttons
                HStack(spacing: MPSpacing.md) {
                    Button {
                        showingCustomHabitInfo = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            editingCustomHabit = customHabit
                        }
                    } label: {
                        HStack(spacing: MPSpacing.xs) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .medium))
                            Text("Edit")
                                .font(MPFont.labelMedium())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, MPSpacing.lg)
                        .padding(.vertical, MPSpacing.sm)
                        .background(MPColors.primary)
                        .cornerRadius(MPRadius.md)
                    }

                    Button {
                        showingCustomHabitInfo = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            manager.deleteCustomHabit(id: customHabit.id)
                        }
                    } label: {
                        HStack(spacing: MPSpacing.xs) {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .medium))
                            Text("Delete")
                                .font(MPFont.labelMedium())
                        }
                        .foregroundColor(MPColors.error)
                        .padding(.horizontal, MPSpacing.lg)
                        .padding(.vertical, MPSpacing.sm)
                        .background(MPColors.error.opacity(0.1))
                        .cornerRadius(MPRadius.md)
                    }
                }
                .padding(.top, MPSpacing.sm)
            }
            .padding(MPSpacing.xl)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .mpShadow(.medium)
            .padding(.horizontal, MPSpacing.xxl)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    /// Generate a description for a custom habit similar to howItWorksDetailed
    private func customHabitDescription(for habit: CustomHabit) -> String {
        switch habit.verificationType {
        case .aiVerified:
            if let prompt = habit.aiPrompt, !prompt.isEmpty {
                let cleaned = cleanPromptForDisplay(prompt)
                return "Take a photo showing \(cleaned.lowercased()). AI will verify it for you."
            } else {
                return "Take a photo and AI will verify you completed this habit."
            }
        case .honorSystem:
            return "Hold to confirm you completed this habit. We trust you!"
        }
    }

    /// Cleans up an AI verification prompt for display
    private func cleanPromptForDisplay(_ prompt: String) -> String {
        var cleaned = prompt.trimmingCharacters(in: .whitespaces)

        let prefixesToRemove = [
            "make me show ",
            "make me ",
            "show me ",
            "show that ",
            "show ",
            "verify that ",
            "verify ",
            "check that ",
            "check if ",
            "check "
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

// MARK: - Schedule Overview Sheet

private struct ScheduleOverviewSheet: View {
    @ObservedObject var manager: MorningProofManager
    @Binding var editingHabitSchedule: HabitType?
    @Binding var editingCustomHabitSchedule: CustomHabit?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: MPSpacing.xl) {
                        scheduleContent
                    }
                    .padding(.horizontal, MPSpacing.xl)
                    .padding(.top, MPSpacing.lg)
                    .padding(.bottom, MPSpacing.xxxl)
                }
            }
            .navigationTitle("Habit Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(MPFont.labelMedium())
                    .foregroundColor(MPColors.primary)
                }
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
        }
    }

    @ViewBuilder
    var scheduleContent: some View {
        let enabledPredefined = manager.habitConfigs.filter { $0.isEnabled }
        let enabledCustom = manager.customHabits.filter { habit in
            let config = manager.customHabitConfigs.first { $0.customHabitId == habit.id }
            return config?.isEnabled ?? true
        }

        let hasAnyEnabled = !enabledPredefined.isEmpty || !enabledCustom.isEmpty

        if !hasAnyEnabled {
            VStack(spacing: MPSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(MPColors.surfaceSecondary)
                        .frame(width: 72, height: 72)
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 28))
                        .foregroundColor(MPColors.textTertiary)
                }

                VStack(spacing: MPSpacing.sm) {
                    Text("No habits enabled")
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.textSecondary)
                    Text("Enable habits above to set their schedule")
                        .font(MPFont.labelSmall())
                        .foregroundColor(MPColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MPSpacing.xxxl)
        } else {
            VStack(spacing: MPSpacing.md) {
                ForEach(enabledPredefined) { config in
                    scheduleRow(
                        icon: config.habitType.icon,
                        name: config.habitType.displayName,
                        schedule: DaySchedule.displayString(for: config.activeDays),
                        action: { editingHabitSchedule = config.habitType }
                    )
                }

                ForEach(enabledCustom) { habit in
                    scheduleRow(
                        icon: habit.icon,
                        name: habit.name,
                        schedule: DaySchedule.displayString(for: habit.activeDays),
                        action: { editingCustomHabitSchedule = habit }
                    )
                }
            }
        }
    }

    func scheduleRow(icon: String, name: String, schedule: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: MPSpacing.lg) {
                // Icon in circular background
                ZStack {
                    Circle()
                        .fill(MPColors.surfaceSecondary)
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: MPIconSize.md))
                        .foregroundColor(MPColors.primary)
                }

                // Two-line text layout
                VStack(alignment: .leading, spacing: MPSpacing.xs) {
                    Text(name)
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.textPrimary)
                    Text(schedule)
                        .font(MPFont.labelTiny())
                        .foregroundColor(MPColors.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MPColors.textTertiary)
            }
            .padding(MPSpacing.lg)
            .frame(minHeight: 60)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .mpShadow(.small)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RoutineTabView(manager: MorningProofManager.shared)
}
