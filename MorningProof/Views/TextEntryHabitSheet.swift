import SwiftUI

/// A sheet for text-entry habits like Gratitude and Daily Planning
/// Requires minimum text length before allowing completion
struct TextEntryHabitSheet: View {
    @ObservedObject var manager: MorningProofManager
    let habitType: HabitType
    @Environment(\.dismiss) var dismiss

    @State private var text: String = ""
    @State private var isCompleted = false
    @State private var showConfetti = false
    @FocusState private var isTextFieldFocused: Bool

    private var minimumLength: Int {
        habitType.minimumTextLength
    }

    private var isValidEntry: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).count >= minimumLength
    }

    private var placeholderText: String {
        switch habitType {
        case .gratitude: return "I'm grateful for..."
        case .dailyPlanning: return "My top priorities today..."
        default: return "Start writing..."
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                if isCompleted {
                    completionView
                } else {
                    entryView
                }
            }
            .navigationTitle(habitType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(MPColors.textTertiary)
                }
            }
        }
    }

    var entryView: some View {
        VStack(spacing: MPSpacing.lg) {
            // Header with icon
            VStack(spacing: MPSpacing.md) {
                ZStack {
                    Circle()
                        .fill(MPColors.primaryLight)
                        .frame(width: 72, height: 72)

                    Image(systemName: habitType.icon)
                        .font(.system(size: 32))
                        .foregroundColor(MPColors.primary)
                }

       cacing.md)
                    .focused($isTextFieldFocused)
            }
            .frame(minHeight: 140, maxHeight: 200)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: MPRadius.lg)
                    .stroke(isTextFieldFocused ? MPColors.primary : MPColors.border, lineWidth: isTextFieldFocused ? 2 : 1)
            )
            .padding(.horizontal, MPSpacing.xl)

            // Character hint
            if !text.isEmpty && !isValidEntry {
                let remaining = minimumLength - text.trimmingCharacters(in: .whitespacesAndNewlines).count
                Text("\(remaining) more character\(remaining == 1 ? "" : "s")")
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.textTertiary)
            }

            Spacer()
        }
        .safeAreaInset(edge: .bottom) {
            // Submit button pinned above keyboard
            MPButton(
                title: "Complete",
                style: isValidEntry ? .primary : .secondary,
                icon: "checkmark"
            ) {
                submitEntry()
            }
            .disabled(!isValidEntry)
            .padding(.horizontal, MPSpacing.xl)
            .padding(.bottom, MPSpacing.md)
            .padding(.top, MPSpacing.sm)
            .background(MPColors.background)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }

    var completionView: some View {
        ZStack {
            VStack(spacing: MPSpacing.xxl) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(MPColors.successLight)
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(MPColors.success)
                }

                Text(completionTitle)
                    .font(MPFont.headingMedium())
                    .foregroundColor(MPColors.textPrimary)

                Text(completionMessage)
                    .font(MPFont.bodyLarge())
                    .foregroundColor(MPColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MPSpacing.xxxl)

                Spacer()

                MPButton(title: "Done", style: .primary) {
                    dismiss()
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.bottom, MPSpacing.xxxl)
            }

            // Celebration confetti
            if showConfetti {
                MiniConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            HapticManager.shared.success()
            // Trigger confetti after a brief moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showConfetti = true
            }
        }
    }

    private var completionTitle: String {
        switch habitType {
        case .gratitude: return "Gratitude Logged!"
        case .dailyPlanning: return "Day Planned!"
        default: return "Completed!"
        }
    }

    private var completionMessage: String {
        switch habitType {
        case .gratitude: return "Starting your day with gratitude sets a positive tone."
        case .dailyPlanning: return "Clear priorities lead to productive mornings."
        default: return "Great job completing this habit!"
        }
    }

    private func submitEntry() {
        guard isValidEntry else { return }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        manager.completeTextEntry(habitType: habitType, text: trimmedText)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isCompleted = true
        }
    }
}

#Preview {
    TextEntryHabitSheet(manager: MorningProofManager.shared, habitType: .gratitude)
}
