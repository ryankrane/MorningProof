import SwiftUI

struct JournalEntryView: View {
    @ObservedObject var manager: MorningProofManager
    @Environment(\.dismiss) var dismiss

    @State private var journalText = ""
    @FocusState private var isFocused: Bool

    private let minimumLength = 10

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.98, green: 0.96, blue: 0.93)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Prompt card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.3))
                            Text("Morning Prompt")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                        }

                        Text(todayPrompt)
                            .font(.body)
                            .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 20)

                    // Text editor
                    VStack(alignment: .leading, spacing: 8) {
                        TextEditor(text: $journalText)
                            .focused($isFocused)
                            .frame(minHeight: 200)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(14)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)

                        // Character count
                        HStack {
                            Text("\(journalText.count) characters")
                                .font(.caption)
                                .foregroundColor(journalText.count >= minimumLength ?
                                    Color(red: 0.55, green: 0.75, blue: 0.55) :
                                    Color(red: 0.6, green: 0.5, blue: 0.4))

                            Spacer()

                            if journalText.count < minimumLength {
                                Text("\(minimumLength - journalText.count) more needed")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 0.85, green: 0.6, blue: 0.5))
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    // Save button
                    Button {
                        manager.completeTextEntry(habitType: .meditation, text: journalText)
                        dismiss()
                    } label: {
                        Text("Save Entry")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(journalText.count >= minimumLength ?
                                Color(red: 0.55, green: 0.45, blue: 0.35) :
                                Color(red: 0.8, green: 0.75, blue: 0.7))
                            .cornerRadius(14)
                    }
                    .disabled(journalText.count < minimumLength)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Morning Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
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

    var todayPrompt: String {
        let prompts = [
            "What are you grateful for this morning?",
            "What's one thing you want to accomplish today?",
            "How are you feeling right now?",
            "What would make today great?",
            "What's on your mind this morning?",
            "What did you dream about last night?",
            "What's one positive thing about today?"
        ]

        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return prompts[dayOfYear % prompts.count]
    }
}

#Preview {
    JournalEntryView(manager: MorningProofManager.shared)
}
