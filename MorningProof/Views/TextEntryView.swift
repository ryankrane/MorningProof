import SwiftUI

struct TextEntryView: View {
    @ObservedObject var manager: MorningProofManager
    let habitType: HabitType
    @Environment(\.dismiss) var dismiss

    @State private var entryText = ""
    @FocusState private var isFocused: Bool

    private var minimumLength: Int {
        habitType.minimumTextLength
    }

    private var title: String {
        switch habitType {
        case .journaling: return "Morning Journal"
        case .gratitude: return "Gratitude"
        case .dailyGoals: return "Daily Goals"
        default: return habitType.displayName
        }
    }

    private var icon: String {
        habitType.icon
    }

    private var accentColor: Color {
        switch habitType {
        case .journaling: return Color(red: 0.55, green: 0.45, blue: 0.35)
        case .gratitude: return Color(red: 0.85, green: 0.5, blue: 0.5)
        case .dailyGoals: return Color(red: 0.4, green: 0.6, blue: 0.8)
        default: return MPColors.primary
        }
    }

    private var bgColor: Color {
        switch habitType {
        case .journaling: return Color(red: 0.98, green: 0.96, blue: 0.93)
        case .gratitude: return Color(red: 0.99, green: 0.95, blue: 0.95)
        case .dailyGoals: return Color(red: 0.95, green: 0.97, blue: 0.99)
        default: return MPColors.background
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                bgColor
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Prompt card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: promptIcon)
                                .foregroundColor(accentColor)
                            Text(promptTitle)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }

                        Text(habitType.textEntryPrompt)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 20)

                    // Text editor
                    VStack(alignment: .leading, spacing: 8) {
                        TextEditor(text: $entryText)
                            .focused($isFocused)
                            .frame(minHeight: habitType == .dailyGoals ? 150 : 200)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(14)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)

                        // Character count
                        HStack {
                            Text("\(entryText.count) characters")
                                .font(.caption)
                                .foregroundColor(entryText.count >= minimumLength ?
                                    Color.green : .secondary)

                            Spacer()

                            if entryText.count < minimumLength {
                                Text("\(minimumLength - entryText.count) more needed")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 20)

                    // Tips for specific habits
                    if habitType == .gratitude {
                        tipCard(
                            icon: "lightbulb.fill",
                            text: "Try listing 3 specific things you're grateful for today"
                        )
                    } else if habitType == .dailyGoals {
                        tipCard(
                            icon: "star.fill",
                            text: "Focus on your top 3 priorities - what would make today a success?"
                        )
                    }

                    Spacer()

                    // Save button
                    Button {
                        completeEntry()
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(entryText.count >= minimumLength ?
                                accentColor : Color.gray.opacity(0.5))
                            .cornerRadius(14)
                    }
                    .disabled(entryText.count < minimumLength)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .padding(.top, 20)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }

                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        isFocused = false
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }

    private var promptIcon: String {
        switch habitType {
        case .journaling: return "lightbulb.fill"
        case .gratitude: return "heart.fill"
        case .dailyGoals: return "target"
        default: return "pencil"
        }
    }

    private var promptTitle: String {
        switch habitType {
        case .journaling: return "Morning Prompt"
        case .gratitude: return "Gratitude Practice"
        case .dailyGoals: return "Set Your Intentions"
        default: return "Entry"
        }
    }

    @ViewBuilder
    private func tipCard(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(accentColor.opacity(0.8))
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.7))
        .cornerRadius(10)
        .padding(.horizontal, 20)
    }

    private func completeEntry() {
        switch habitType {
        case .journaling:
            manager.completeJournaling(text: entryText)
        case .gratitude:
            manager.completeTextEntry(habitType: .gratitude, text: entryText)
        case .dailyGoals:
            manager.completeTextEntry(habitType: .dailyGoals, text: entryText)
        default:
            break
        }
    }
}

#Preview {
    TextEntryView(manager: MorningProofManager.shared, habitType: .gratitude)
}
