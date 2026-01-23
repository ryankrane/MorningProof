import SwiftUI

struct RoutineTabView: View {
    @ObservedObject var manager: MorningProofManager

    @State private var cutoffMinutes: Int = 540
    @State private var isEditMode = false
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
                        // Deadline card
                        DeadlineCardView(cutoffMinutes: $cutoffMinutes)

                        // Habits section
                        habitsSection

                        // Add habit button
                        addHabitButton

                        Spacer(minLength: MPSpacing.xxxl)
                    }
                    .padding(.horizontal, MPSpacing.xl)
                    .padding(.top, MPSpacing.lg)
                }
            }
            .navigationTitle("Your Routine")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { loadSettings() }
            .onDisappear { saveSettings() }
            .sheet(isPresented: $showCreateCustomHabit) {
                CustomHabitCreationSheet(manager: manager)
            }
        }
    }

    // MARK: - Habits Section

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            // Section header
            HStack {
                Text("YOUR HABITS")
                    .font(MPFont.labelSmall())
                    .foregroundColor(MPColors.textTertiary)
                    .tracking(0.5)

                Spacer()

                if enabledHabits.count > 1 {
                    Text("\(enabledHabits.count) habits")
                        .font(MPFont.labelTiny())
                        .foregroundColor(MPColors.textMuted)
                }
            }
            .padding(.leading, MPSpacing.xs)
            .padding(.trailing, MPSpacing.xs)

            // Habits list
            if enabledHabits.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(enabledHabits) { habit in
                        NavigationLink {
                            if let type = habit.predefinedType {
                                HabitDetailView(manager: manager, habitType: type)
                            } else if let custom = habit.customHabit {
                                HabitDetailView(manager: manager, customHabit: custom)
                            }
                        } label: {
                            habitRowContent(for: habit)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                removeHabit(habit)
                            } label: {
                                Label("Remove", systemImage: "minus.circle")
                            }
                            .tint(MPColors.error)
                        }

                        if habit.id != enabledHabits.last?.id {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
                .background(MPColors.surface)
                .cornerRadius(MPRadius.lg)
                .mpShadow(.small)
            }
        }
    }

    // MARK: - Habit Row Content

    private func habitRowContent(for habit: EnabledHabit) -> some View {
        HStack(spacing: MPSpacing.md) {
            // Icon with subtle tint (no circle background)
            Image(systemName: habit.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(MPColors.primary)
                .frame(width: 28)

            Text(habit.name)
                .font(MPFont.labelMedium())
                .foregroundColor(MPColors.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(MPColors.textTertiary)
        }
        .padding(.vertical, MPSpacing.lg)
        .padding(.horizontal, MPSpacing.lg)
        .contentShape(Rectangle())
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: MPSpacing.lg) {
            ZStack {
                Circle()
                    .fill(MPColors.surfaceSecondary)
                    .frame(width: 72, height: 72)
                Image(systemName: "plus.circle")
                    .font(.system(size: 28))
                    .foregroundColor(MPColors.textTertiary)
            }

            VStack(spacing: MPSpacing.sm) {
                Text("No habits yet")
                    .font(MPFont.labelMedium())
                    .foregroundColor(MPColors.textSecondary)
                Text("Add habits to build your morning routine")
                    .font(MPFont.labelSmall())
                    .foregroundColor(MPColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MPSpacing.xxxl)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
    }

    // MARK: - Manage Habits Button

    private var addHabitButton: some View {
        NavigationLink {
            AddHabitView(manager: manager)
        } label: {
            HStack(spacing: MPSpacing.sm) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .medium))
                Text("Manage Habits")
                    .font(MPFont.labelMedium())
            }
            .foregroundColor(MPColors.primary)
            .frame(maxWidth: .infinity)
            .frame(height: MPButtonHeight.md)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: MPRadius.lg)
                    .stroke(MPColors.border, lineWidth: 1.5)
            )
        }
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
    }

    private func saveSettings() {
        manager.settings.morningCutoffMinutes = cutoffMinutes
        manager.saveCurrentState()
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
