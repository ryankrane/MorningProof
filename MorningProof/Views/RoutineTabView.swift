import SwiftUI

struct RoutineTabView: View {
    @ObservedObject var manager: MorningProofManager

    @State private var cutoffMinutes: Int = 540
    @State private var deadlineCustomizationMode: Int = 0
    @State private var weekdayDeadlineMinutes: Int = 540
    @State private var weekendDeadlineMinutes: Int = 660
    @State private var perDayDeadlineMinutes: [Int] = [540, 540, 540, 540, 540, 540, 540]
    @State private var showCreateCustomHabit = false

    /// All enabled habits in display order (predefined + custom combined)
    private var enabledHabits: [EnabledHabit] {
        var habits: [EnabledHabit] = []

        // Add enabled predefined habits
        let enabledPredefined = manager.habitConfigs
            .filter { $0.isEnabled }
            .sorted { $0.displayOrder < $1.displayOrder }

        for config in enabledPredefined {
            habits.append(EnabledHabit(predefined: config.habitType))
        }

        // Add enabled custom habits
        let enabledCustom = manager.customHabits.filter { habit in
            let config = manager.customHabitConfigs.first { $0.customHabitId == habit.id }
            return config?.isEnabled ?? true
        }.sorted { $0.createdAt < $1.createdAt }

        for habit in enabledCustom {
            habits.append(EnabledHabit(custom: habit))
        }

        return habits
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: MPSpacing.xl) {
                        // Deadline section
                        DeadlineCardView(
                            cutoffMinutes: $cutoffMinutes,
                            customizationMode: $deadlineCustomizationMode,
                            weekdayDeadlineMinutes: $weekdayDeadlineMinutes,
                            weekendDeadlineMinutes: $weekendDeadlineMinutes,
                            perDayDeadlineMinutes: $perDayDeadlineMinutes
                        )

                        // App Locking section
                        AppLockingCardView()

                        // Habits section
                        habitsSection

                        // Customize Habits button
                        customizeHabitsButton

                        Spacer(minLength: MPSpacing.xxxl)
                    }
                    .padding(.horizontal, MPSpacing.xl)
                    .padding(.top, MPSpacing.lg)
                }
            }
            .navigationTitle("Routine")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AddHabitView(manager: manager)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(MPColors.primary)
                    }
                }
            }
            .onAppear { loadSettings() }
            .onDisappear { saveSettings() }
            .sheet(isPresented: $showCreateCustomHabit) {
                CustomHabitCreationSheet(manager: manager)
            }
        }
    }

    // MARK: - Habits Section

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.sm) {
            // Section header
            Text("HABITS")
                .font(MPFont.labelSmall())
                .foregroundColor(MPColors.textTertiary)
                .tracking(0.5)
                .padding(.leading, MPSpacing.xs)

            // Habits list
            if enabledHabits.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(enabledHabits.enumerated()), id: \.element.id) { index, habit in
                        NavigationLink {
                            if let type = habit.predefinedType {
                                HabitDetailView(manager: manager, habitType: type)
                            } else if let custom = habit.customHabit {
                                HabitDetailView(manager: manager, customHabit: custom)
                            }
                        } label: {
                            habitRowContent(for: habit)
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Add divider between items (not after last)
                        if index < enabledHabits.count - 1 {
                            Divider()
                                .background(MPColors.divider)
                                .padding(.leading, 52)
                        }
                    }
                }
                .background(MPColors.surface)
                .cornerRadius(MPRadius.lg)
            }
        }
    }

    // MARK: - Habit Row Content

    private func habitRowContent(for habit: EnabledHabit) -> some View {
        HStack(spacing: MPSpacing.md) {
            // Subtle icon
            Image(systemName: habit.icon)
                .font(.system(size: 18))
                .foregroundColor(MPColors.primary.opacity(0.85))
                .frame(width: 24)

            Text(habit.name)
                .font(.system(size: 17))
                .foregroundColor(MPColors.textPrimary)

            Spacer()

            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(MPColors.textTertiary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, MPSpacing.lg)
        .contentShape(Rectangle())
    }

    // MARK: - Customize Habits Button

    private var customizeHabitsButton: some View {
        NavigationLink {
            AddHabitView(manager: manager)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .medium))
                Text("Customize Habits")
                    .font(.system(size: 15, weight: .regular))
            }
            .foregroundColor(MPColors.textSecondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(MPColors.surface)
            )
            .overlay(
                Capsule()
                    .strokeBorder(MPColors.divider, lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: MPSpacing.md) {
            Image(systemName: "checklist")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(MPColors.textTertiary)

            Text("No habits yet")
                .font(.system(size: 17))
                .foregroundColor(MPColors.textSecondary)

            Text("Tap + to add your first habit")
                .font(.system(size: 15))
                .foregroundColor(MPColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Remove Habit

    private func removeHabit(_ habit: EnabledHabit) {
        if let type = habit.predefinedType {
            manager.updateHabitConfig(type, isEnabled: false)
        } else if let custom = habit.customHabit {
            manager.toggleCustomHabit(custom.id, isEnabled: false)
        }
    }

    // MARK: - Settings Persistence

    private func loadSettings() {
        cutoffMinutes = manager.settings.morningCutoffMinutes
        deadlineCustomizationMode = manager.settings.deadlineCustomizationMode
        weekdayDeadlineMinutes = manager.settings.weekdayDeadlineMinutes
        weekendDeadlineMinutes = manager.settings.weekendDeadlineMinutes
        perDayDeadlineMinutes = manager.settings.perDayDeadlineMinutes
    }

    private func saveSettings() {
        manager.settings.morningCutoffMinutes = cutoffMinutes
        manager.settings.deadlineCustomizationMode = deadlineCustomizationMode
        manager.settings.weekdayDeadlineMinutes = weekdayDeadlineMinutes
        manager.settings.weekendDeadlineMinutes = weekendDeadlineMinutes
        manager.settings.perDayDeadlineMinutes = perDayDeadlineMinutes
        manager.saveCurrentState()

        // Update notifications when deadline settings change
        Task {
            await NotificationManager.shared.updateNotificationSchedule(settings: manager.settings)
        }
    }
}

// MARK: - Enabled Habit Wrapper

/// A wrapper that unifies predefined and custom habits for display
private struct EnabledHabit: Identifiable {
    let id: String
    let predefinedType: HabitType?
    let customHabit: CustomHabit?

    init(predefined type: HabitType) {
        self.id = "predefined_\(type.rawValue)"
        self.predefinedType = type
        self.customHabit = nil
    }

    init(custom habit: CustomHabit) {
        self.id = "custom_\(habit.id.uuidString)"
        self.predefinedType = nil
        self.customHabit = habit
    }

    var name: String {
        predefinedType?.displayName ?? customHabit?.name ?? ""
    }

    var icon: String {
        predefinedType?.icon ?? customHabit?.icon ?? "star.fill"
    }

    var verificationText: String {
        if let type = predefinedType {
            return type.tier.sectionTitle
        } else if let custom = customHabit {
            return custom.verificationType.displayName
        }
        return ""
    }

    var verificationIcon: String {
        if let type = predefinedType {
            return type.tier.icon
        } else if let custom = customHabit {
            return custom.verificationType.icon
        }
        return "checkmark.circle"
    }
}

#Preview {
    RoutineTabView(manager: MorningProofManager.shared)
}
