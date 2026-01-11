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
        habitType.displayName
    }

    private var icon: String {
        habitType.icon
    }

    private var accentColor: Color {
        MPColors.primary
    }

    private var bgColor: Color {
        MPColors.background
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
                            Image(systemName: icon)
                                .foregroundColor(accentColor)
                            Text(title)
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
                            .frame(minHeight: 150)
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

    private func completeEntry() {
        manager.completeTextEntry(habitType: habitType, text: entryText)
    }
}

#Preview {
    TextEntryView(manager: MorningProofManager.shared, habitType: .meditation)
}
