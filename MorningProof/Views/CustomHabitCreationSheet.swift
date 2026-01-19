import SwiftUI

struct CustomHabitCreationSheet: View {
    @ObservedObject var manager: MorningProofManager
    @Environment(\.dismiss) var dismiss

    // Editing mode
    var editingHabit: CustomHabit?

    // Form state
    @State private var habitName: String = ""
    @State private var selectedIcon: String = "bolt.fill"
    @State private var verificationType: CustomVerificationType = .honorSystem
    @State private var mediaType: VerificationMediaType = .photo
    @State private var aiPrompt: String = ""
    @State private var allowsScreenshots: Bool = false

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

                        // Media Type Section (conditional - only for AI verified)
                        if verificationType == .aiVerified {
                            mediaTypeSection

                            // Screenshot Option Section (only for photo media type)
                            if mediaType == .photo {
                                screenshotOptionSection
                            }

                            // AI Prompt Section
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
                    mediaType = habit.mediaType
                    aiPrompt = habit.aiPrompt ?? ""
                    allowsScreenshots = habit.allowsScreenshots
                }
            }
        }
        .swipeBack { dismiss() }
    }

    // MARK: - Icon and Name Section

    var iconAndNameSection: some View {
        sectionContainer(title: "Habit Details", icon: "pencil") {
            VStack(spacing: MPSpacing.lg) {
                // Icon selector - centered hero style
                Button {
                    showIconPicker = true
                } label: {
                    VStack(spacing: MPSpacing.sm) {
                        ZStack {
                            // Outer glow ring
                            Circle()
                                .fill(MPColors.primaryLight.opacity(0.15))
                                .frame(width: 88, height: 88)

                            // Main icon background
                            Circle()
                                .fill(MPColors.primaryLight.opacity(0.3))
                                .frame(width: 72, height: 72)

                            // Icon
                            Image(systemName: selectedIcon)
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(MPColors.primary)
                        }

                        Text("Tap to change")
                            .font(MPFont.labelTiny())
                            .foregroundColor(MPColors.textTertiary)
                    }
                }
                .padding(.top, MPSpacing.sm)

                // Name field
                VStack(alignment: .leading, spacing: MPSpacing.xs) {
                    Text("Name")
                        .font(MPFont.labelSmall())
                        .foregroundColor(MPColors.textSecondary)

                    TextField("e.g., Take vitamins", text: $habitName)
                        .font(MPFont.bodyMedium())
                        .foregroundColor(MPColors.textPrimary)
                        .padding(.horizontal, MPSpacing.md)
                        .padding(.vertical, MPSpacing.md)
                        .background(MPColors.surfaceSecondary)
                        .cornerRadius(MPRadius.md)
                        .focused($isNameFocused)
                }
            }
            .padding(.bottom, MPSpacing.xs)
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

    // MARK: - Media Type Section

    var mediaTypeSection: some View {
        sectionContainer(title: "Capture Method", icon: "camera.metering.multispot") {
            VStack(spacing: MPSpacing.md) {
                // Segmented picker
                HStack(spacing: 0) {
                    ForEach(VerificationMediaType.allCases, id: \.self) { type in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                mediaType = type
                            }
                        } label: {
                            HStack(spacing: MPSpacing.xs) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 14))
                                Text(type.displayName)
                                    .font(MPFont.labelMedium())
                            }
                            .foregroundColor(mediaType == type ? .white : MPColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MPSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: MPRadius.sm)
                                    .fill(mediaType == type ? MPColors.primary : Color.clear)
                            )
                        }
                    }
                }
                .padding(4)
                .background(MPColors.surfaceSecondary)
                .cornerRadius(MPRadius.md)

                // Help text
                Text(mediaType.description)
                    .font(MPFont.labelTiny())
                    .foregroundColor(MPColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Screenshot Option Section

    var screenshotOptionSection: some View {
        sectionContainer(title: "Screenshot Verification", icon: "photo.on.rectangle") {
            VStack(alignment: .leading, spacing: MPSpacing.sm) {
                Toggle(isOn: $allowsScreenshots) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Allow screenshots")
                            .font(MPFont.labelMedium())
                            .foregroundColor(MPColors.textPrimary)

                        Text("Choose photos from library instead of camera")
                            .font(MPFont.labelTiny())
                            .foregroundColor(MPColors.textTertiary)
                    }
                }
                .tint(MPColors.primary)

                if allowsScreenshots {
                    Text("Best for habits verified via screenshots (phone calls, app activity, etc.)")
                        .font(MPFont.labelTiny())
                        .foregroundColor(MPColors.textTertiary)
                        .padding(.top, MPSpacing.xs)
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

        // Only allow screenshots for AI-verified photo habits
        let screenshotsEnabled = verificationType == .aiVerified && mediaType == .photo && allowsScreenshots

        if let existingHabit = editingHabit {
            // Update existing habit
            var updatedHabit = existingHabit
            updatedHabit.name = trimmedName
            updatedHabit.icon = selectedIcon
            updatedHabit.verificationType = verificationType
            updatedHabit.mediaType = verificationType == .aiVerified ? mediaType : .photo
            updatedHabit.aiPrompt = verificationType == .aiVerified ? trimmedPrompt : nil
            updatedHabit.allowsScreenshots = screenshotsEnabled
            manager.updateCustomHabit(updatedHabit)
        } else {
            // Create new habit
            let newHabit = CustomHabit(
                name: trimmedName,
                icon: selectedIcon,
                verificationType: verificationType,
                mediaType: verificationType == .aiVerified ? mediaType : .photo,
                aiPrompt: verificationType == .aiVerified ? trimmedPrompt : nil,
                allowsScreenshots: screenshotsEnabled
            )
            manager.addCustomHabit(newHabit)
        }

        dismiss()
    }
}

#Preview {
    CustomHabitCreationSheet(manager: MorningProofManager.shared)
}
