//
//  AppleStyleHabitsSection.swift
//  MorningProof
//
//  Apple-inspired habits list - calm, restrained, system-native
//

import SwiftUI

struct AppleStyleHabitsSection: View {
    let manager: MorningProofManager
    let layout: DynamicHabitLayout
    let allComplete: Bool

    // Actions
    let onAIHabitTap: (HabitType) -> Void
    let onTextHabitTap: (HabitType) -> Void
    let onCustomAIHabitTap: (CustomHabit) -> Void
    let onHoldComplete: (HabitType) -> Void
    let onCustomHoldComplete: (UUID) -> Void

    // Hold progress bindings
    @Binding var holdProgress: [HabitType: CGFloat]
    @Binding var customHoldProgress: [UUID: CGFloat]

    var body: some View {
        VStack(spacing: 0) {
            // Section header
            HStack {
                Text("Habits")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(MPColors.textPrimary)

                Spacer()

                // Completion indicator (subtle)
                if allComplete {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(MPColors.success)
                        Text("Complete")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(MPColors.success)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Text("\(manager.completedCount)/\(manager.totalEnabled)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(MPColors.textSecondary)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 12)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: allComplete)

            // Habits list (grouped by verification type)
            VStack(spacing: 1) {
                // AI Verified habits
                aiVerifiedSection

                // Auto-Tracked habits
                autoTrackedSection

                // Journaling habits
                journalingSection

                // Honor System habits
                honorSystemSection
            }
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .mpShadow(.medium)
        }
    }

    // MARK: - Sections by Verification Type

    @ViewBuilder
    private var aiVerifiedSection: some View {
        let predefinedAI = manager.enabledHabits.filter { $0.habitType.tier == .aiVerified }
        let customAI = manager.enabledCustomHabits.filter { $0.verificationType == .aiVerified }

        if !predefinedAI.isEmpty || !customAI.isEmpty {
            ForEach(predefinedAI) { config in
                habitRow(for: config)
                if !isLastHabit(config) {
                    Divider()
                        .padding(.leading, 52)
                }
            }

            ForEach(customAI) { habit in
                customHabitRow(for: habit)
                if !isLastCustomHabit(habit, in: customAI) {
                    Divider()
                        .padding(.leading, 52)
                }
            }
        }
    }

    @ViewBuilder
    private var autoTrackedSection: some View {
        let autoTracked = manager.enabledHabits.filter { $0.habitType.tier == .autoTracked }

        ForEach(autoTracked) { config in
            habitRow(for: config)
            if !isLastHabit(config) {
                Divider()
                    .padding(.leading, 52)
            }
        }
    }

    @ViewBuilder
    private var journalingSection: some View {
        let journaling = manager.enabledHabits.filter { $0.habitType.tier == .journaling }

        ForEach(journaling) { config in
            habitRow(for: config)
            if !isLastHabit(config) {
                Divider()
                    .padding(.leading, 52)
            }
        }
    }

    @ViewBuilder
    private var honorSystemSection: some View {
        let predefinedHonor = manager.enabledHabits.filter { $0.habitType.tier == .honorSystem }
        let customHonor = manager.enabledCustomHabits.filter { $0.verificationType == .honorSystem }

        if !predefinedHonor.isEmpty || !customHonor.isEmpty {
            ForEach(predefinedHonor) { config in
                habitRow(for: config)
                if !isLastHabit(config) || !customHonor.isEmpty {
                    Divider()
                        .padding(.leading, 52)
                }
            }

            ForEach(customHonor) { habit in
                customHabitRow(for: habit)
                if !isLastCustomHabit(habit, in: customHonor) {
                    Divider()
                        .padding(.leading, 52)
                }
            }
        }
    }

    // MARK: - Habit Rows

    @ViewBuilder
    private func habitRow(for config: HabitConfig) -> some View {
        let completion = manager.getCompletion(for: config.habitType)
        let isCompleted = completion?.isCompleted ?? false
        let subtitle = getSubtitle(for: config, completion: completion)
        let progress = holdProgress[config.habitType] ?? 0

        Button {
            handleHabitTap(config)
        } label: {
            HStack(spacing: 12) {
                // Status indicator (left)
                statusIndicator(isCompleted: isCompleted, icon: config.habitType.icon)

                // Info (middle)
                VStack(alignment: .leading, spacing: 2) {
                    Text(config.habitType.displayName)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(isCompleted ? MPColors.textSecondary : MPColors.textPrimary)

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 15))
                            .foregroundColor(MPColors.textTertiary)
                    }
                }

                Spacer()

                // Action indicator (right)
                trailingContent(for: config, isCompleted: isCompleted, progress: progress)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .holdToComplete(
            isEnabled: isHoldToCompleteHabit(config.habitType) && !isCompleted,
            progress: Binding(
                get: { holdProgress[config.habitType] ?? 0 },
                set: { holdProgress[config.habitType] = $0 }
            ),
            holdDuration: 1.0,
            onCompleted: {
                onHoldComplete(config.habitType)
            }
        )
    }

    @ViewBuilder
    private func customHabitRow(for habit: CustomHabit) -> some View {
        let completion = manager.getCustomCompletion(for: habit.id)
        let isCompleted = completion?.isCompleted ?? false
        let subtitle = getCustomSubtitle(for: habit, completion: completion)
        let progress = customHoldProgress[habit.id] ?? 0

        Button {
            handleCustomHabitTap(habit)
        } label: {
            HStack(spacing: 12) {
                statusIndicator(isCompleted: isCompleted, icon: habit.icon)

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(isCompleted ? MPColors.textSecondary : MPColors.textPrimary)

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 15))
                            .foregroundColor(MPColors.textTertiary)
                    }
                }

                Spacer()

                customTrailingContent(for: habit, isCompleted: isCompleted, progress: progress)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .holdToComplete(
            isEnabled: habit.verificationType == .honorSystem && !isCompleted,
            progress: Binding(
                get: { customHoldProgress[habit.id] ?? 0 },
                set: { customHoldProgress[habit.id] = $0 }
            ),
            holdDuration: 1.0,
            onCompleted: {
                onCustomHoldComplete(habit.id)
            }
        )
    }

    // MARK: - Status Indicator (Checkmark or Icon)

    @ViewBuilder
    private func statusIndicator(isCompleted: Bool, icon: String) -> some View {
        if isCompleted {
            // Green checkmark for completed
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(MPColors.success)
                .symbolRenderingMode(.hierarchical)
        } else {
            // Neutral gray circle with icon for incomplete
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(MPColors.textSecondary)
            }
        }
    }

    // MARK: - Trailing Content (Action Indicators)

    @ViewBuilder
    private func trailingContent(for config: HabitConfig, isCompleted: Bool, progress: CGFloat) -> some View {
        if isCompleted {
            EmptyView()
        } else if config.habitType == .morningSteps {
            let completion = manager.getCompletion(for: config.habitType)
            let score = completion?.score ?? 0
            progressRing(progress: CGFloat(score) / 100.0)
        } else if config.habitType.tier == .aiVerified {
            Image(systemName: "camera.fill")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(.systemGray3))
        } else if config.habitType.tier == .journaling {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(.systemGray3))
        } else if config.habitType.tier == .autoTracked {
            Image(systemName: "heart.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.pink.opacity(0.7))
        } else if progress > 0 {
            progressRing(progress: progress)
        } else {
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.systemGray4))
        }
    }

    @ViewBuilder
    private func customTrailingContent(for habit: CustomHabit, isCompleted: Bool, progress: CGFloat) -> some View {
        if isCompleted {
            EmptyView()
        } else if habit.verificationType == .aiVerified {
            Image(systemName: "camera.fill")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(.systemGray3))
        } else if progress > 0 {
            progressRing(progress: progress)
        } else {
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.systemGray4))
        }
    }

    @ViewBuilder
    private func progressRing(progress: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 2)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(MPColors.accent, lineWidth: 2)
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 24, height: 24)
    }

    // MARK: - Subtitle Text

    private func getSubtitle(for config: HabitConfig, completion: HabitCompletion?) -> String {
        if let completion = completion, completion.isCompleted {
            // Subtle completion indicator
            if let data = completion.verificationData {
                if data.isFromHealthKit ?? false {
                    if let steps = data.stepCount {
                        return "\(steps.formatted()) steps"
                    } else if let sleepHours = data.sleepHours {
                        return String(format: "%.1f hours", sleepHours)
                    } else if data.workoutDetected == true {
                        return "Workout detected"
                    }
                    return "Synced from Health"
                } else if data.aiScore != nil {
                    return "AI verified"
                } else if data.textEntry != nil {
                    return "Entry saved"
                }
            }
            return "" // Minimal text for completed
        } else {
            // Show prompt or progress for incomplete
            switch config.habitType.tier {
            case .aiVerified:
                return "Take photo to verify"
            case .autoTracked:
                if let data = completion?.verificationData {
                    if let steps = data.stepCount {
                        return "\(steps.formatted()) steps"
                    } else if let sleepHours = data.sleepHours {
                        return String(format: "%.1f hours", sleepHours)
                    }
                }
                return "Syncs from Health"
            case .journaling:
                return "Tap to add entry"
            case .honorSystem:
                return "Hold to complete"
            }
        }
    }

    private func getCustomSubtitle(for habit: CustomHabit, completion: CustomHabitCompletion?) -> String {
        if let completion = completion, completion.isCompleted {
            if completion.verificationData?.aiScore != nil {
                return "AI verified"
            }
            return ""
        } else {
            switch habit.verificationType {
            case .aiVerified:
                return "Take photo to verify"
            case .honorSystem:
                return "Hold to complete"
            default:
                return ""
            }
        }
    }

    // MARK: - Tap Handlers

    private func handleHabitTap(_ config: HabitConfig) {
        let completion = manager.getCompletion(for: config.habitType)
        guard !(completion?.isCompleted ?? false) else { return }

        if config.habitType.tier == .aiVerified {
            onAIHabitTap(config.habitType)
        } else if config.habitType.tier == .journaling {
            onTextHabitTap(config.habitType)
        }
    }

    private func handleCustomHabitTap(_ habit: CustomHabit) {
        let completion = manager.getCustomCompletion(for: habit.id)
        guard !(completion?.isCompleted ?? false) else { return }

        if habit.verificationType == .aiVerified {
            onCustomAIHabitTap(habit)
        }
    }

    // MARK: - Helpers

    private func isLastHabit(_ config: HabitConfig) -> Bool {
        guard let lastConfig = manager.enabledHabits.last else { return false }
        return config.id == lastConfig.id && manager.enabledCustomHabits.isEmpty
    }

    private func isLastCustomHabit(_ habit: CustomHabit, in section: [CustomHabit]) -> Bool {
        return habit.id == section.last?.id
    }

    private func isHoldToCompleteHabit(_ habitType: HabitType) -> Bool {
        let specialInputHabits: Set<HabitType> = [
            .madeBed, .sleepDuration, .morningSteps, .sunlightExposure, .hydration,
            .healthyBreakfast, .morningJournal, .vitamins, .skincare, .mealPrep,
            .gratitude, .dailyPlanning
        ]
        return !specialInputHabits.contains(habitType)
    }
}
