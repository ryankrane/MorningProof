import SwiftUI

struct CustomHabitCreationSheet: View {
    @ObservedObject var manager: MorningProofManager
    @Environment(\.dismiss) var dismiss

    // Editing mode
    var editingHabit: CustomHabit?

    // Form state
    @State private var habitName: String = ""
    @State private var selectedIcon: String = "star.fill"
    @State private var verificationType: CustomVerificationType = .honorSystem
    @State private var aiPrompt: String = ""

    // UI state
    @State private var showIconPicker = false
    @FocusState private var isNameFocused: Bool
    @FocusState private var isPromptFocused: Bool

    var isEditing: Bool {
        editingHabit != nil
    }

    var isFormValid: Bool {
        let nameValid = !habitName.trimmingCharacters(in: .whitespaces).isEmpty
        let promptValid = verificationType == .honorSystem || !aiPrompt.trimmingCharacters(in: .whitespaces).isEmpty
        return nameValid && promptValid
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: MPSpacing.xl) {
                        // Icon and Name Section
                        iconAndNameSection

                        // Verification Type Section
                        verificationTypeSection

                        // AI Prompt Section (conditional)
                        if verificationType == .aiVerified {
                            aiPromptSection
                        }
                    }
                    .padding(.horizontal, MPSpacing.xl)
                    .padding(.top, MPSpacing.lg)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle(isEditing ? "Edit Habit" : "New Custom Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(MPColors.textSecondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Create") {
                        saveHabit()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? MPColors.primary : MPColors.textTertiary)
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                if let habit = editingHabit {
                    habitName = habit.name
                    selectedIcon = habit.icon
                    verificationType = habit.verificationType
                    aiPrompt = habit.aiPrompt ?? ""
                }
            }
        }
        .swipeBack { dismiss() }
    }

    // MARK: - Icon and Name Section

    var iconAndNameSection: some View {
        sectionContainer(title: "Habit Details", icon: "pencil") {
            VStack(spacing: 0) {
                // Icon selector
                HStack {
                    Text("Icon")
                        .font(MPFont.bodyMedium())
                        .foregroundColor(MPColors.textPrimary)

                    Spacer()

                    Button {
                        showIconPicker = true
                    } label: {
                        Image(systemName: selectedIcon)
                            .font(.system(size: 22))
                            .foregroundColor(MPColors.primary)
                            .frame(width: 44, height: 44)
                            .background(MPColors.primaryLight.opacity(0.3))
                            .cornerRadius(MPRadius.md)
                    }
                }
                .frame(height: 56)

                Divider()

                // Name field - inline style
                HStack {
                    Text("Name")
                        .font(MPFont.bodyMedium())
                        .foregroundColor(MPColors.textPrimary)

                    Spacer()

                    TextField("e.g., Take vitamins", text: $habitName)
                        .font(MPFont.bodyMedium())
                        .foregroundColor(MPColors.textPrimary)
                        .multilineTextAlignment(.trailing)
                        .focused($isNameFocused)
                }
                .frame(height: 56)
            }
        }
        .sheet(isPresented: $showIconPicker) {
            iconPickerSheet
        }
    }

    // MARK: - Icon Picker Sheet

    var iconPickerSheet: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: MPSpacing.lg) {
                        ForEach(CustomHabit.availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                                showIconPicker = false
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: MPRadius.md)
                                        .fill(selectedIcon == icon ? MPColors.primaryLight : MPColors.surface)
                                        .frame(width: 56, height: 56)

                                    Image(systemName: icon)
                                        .font(.system(size: 24))
                                        .foregroundColor(selectedIcon == icon ? MPColors.primary : MPColors.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(MPSpacing.xl)
                }
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showIconPicker = false
                    }
                    .foregroundColor(MPColors.primary)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Verification Type Section

    var verificationTypeSection: some View {
        sectionContainer(title: "Verification Method", icon: "checkmark.shield.fill") {
            VStack(spacing: 0) {
                ForEach(CustomVerificationType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            verificationType = type
                        }
                    } label: {
                        HStack(spacing: MPSpacing.md) {
                            Image(systemName: type.icon)
                                .font(.system(size: 18))
                                .foregroundColor(verificationType == type ? MPColors.primary : MPColors.textSecondary)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.displayName)
                                    .font(MPFont.labelMedium())
                                    .foregroundColor(MPColors.textPrimary)

                                Text(type.description)
                                    .font(MPFont.labelTiny())
                                    .foregroundColor(MPColors.textTertiary)
                            }

                            Spacer()

                            ZStack {
                                Circle()
                                    .stroke(verificationType == type ? MPColors.primary : MPColors.border, lineWidth: 2)
                                    .frame(width: 22, height: 22)

                                if verificationType == type {
                                    Circle()
                                        .fill(MPColors.primary)
                                        .frame(width: 12, height: 12)
                                }
                            }
                        }
                        .padding(.vertical, MPSpacing.md)
                    }

                    if type != CustomVerificationType.allCases.last {
                        Divider()
                            .padding(.leading, 46)
                    }
                }
            }
        }
    }

    // MARK: - AI Prompt Section

    var aiPromptSection: some View {
        sectionContainer(title: "Verification Instructions", icon: "brain.head.profile") {
            VStack(alignment: .leading, spacing: MPSpacing.sm) {
                Text("How should AI verify this habit?")
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.textSecondary)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $aiPrompt)
                        .font(MPFont.bodyMedium())
                        .foregroundColor(MPColors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100, maxHeight: 150)
                        .padding(MPSpacing.md)
                        .background(MPColors.surfaceSecondary)
                        .cornerRadius(MPRadius.md)
                        .focused($isPromptFocused)

                    if aiPrompt.isEmpty {
                        Text("e.g., Make me show my orange pill")
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textTertiary)
                            .padding(MPSpacing.md)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                }

                Text("Be specific about what the AI should look for in your photo.")
                    .font(MPFont.labelTiny())
                    .foregroundColor(MPColors.textTertiary)
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

    func saveHabit() {
        let trimmedName = habitName.trimmingCharacters(in: .whitespaces)
        let trimmedPrompt = aiPrompt.trimmingCharacters(in: .whitespaces)

        if let existingHabit = editingHabit {
            // Update existing habit
            var updatedHabit = existingHabit
            updatedHabit.name = trimmedName
            updatedHabit.icon = selectedIcon
            updatedHabit.verificationType = verificationType
            updatedHabit.aiPrompt = verificationType == .aiVerified ? trimmedPrompt : nil
            manager.updateCustomHabit(updatedHabit)
        } else {
            // Create new habit
            let newHabit = CustomHabit(
                name: trimmedName,
                icon: selectedIcon,
                verificationType: verificationType,
                aiPrompt: verificationType == .aiVerified ? trimmedPrompt : nil
            )
            manager.addCustomHabit(newHabit)
        }

        dismiss()
    }
}

#Preview {
    CustomHabitCreationSheet(manager: MorningProofManager.shared)
}
