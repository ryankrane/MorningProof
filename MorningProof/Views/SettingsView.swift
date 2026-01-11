import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: BedVerificationViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedHour: Int = 9
    @State private var selectedMinute: Int = 0
    @State private var userName: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.98, green: 0.96, blue: 0.93)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Name section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))

                            TextField("Enter your name", text: $userName)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        }

                        // Deadline section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Daily Deadline")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))

                            Text("Make your bed before this time each day")
                                .font(.caption)
                                .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))

                            HStack(spacing: 12) {
                                // Hour picker
                                Picker("Hour", selection: $selectedHour) {
                                    ForEach(5..<13) { hour in
                                        Text("\(hour)").tag(hour)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 80, height: 120)
                                .clipped()
                                .background(Color.white)
                                .cornerRadius(12)

                                Text(":")
                                    .font(.title)
                                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                                // Minute picker
                                Picker("Minute", selection: $selectedMinute) {
                                    ForEach([0, 15, 30, 45], id: \.self) { minute in
                                        Text(String(format: "%02d", minute)).tag(minute)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 80, height: 120)
                                .clipped()
                                .background(Color.white)
                                .cornerRadius(12)

                                Text("AM")
                                    .font(.headline)
                                    .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 3)
                        }

                        // Current deadline display
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(Color(red: 0.55, green: 0.45, blue: 0.35))
                            Text("Deadline set to \(selectedHour):\(String(format: "%02d", selectedMinute)) AM")
                                .font(.subheadline)
                                .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))
                            Spacer()
                        }
                        .padding(16)
                        .background(Color(red: 1.0, green: 0.98, blue: 0.95))
                        .cornerRadius(12)

                        Spacer(minLength: 40)

                        // Reset data button
                        Button {
                            viewModel.resetStreak()
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Reset All Data")
                            }
                            .font(.subheadline)
                            .foregroundColor(.red.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        }

                        Text("Version 1.0")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.7, green: 0.65, blue: 0.6))
                            .padding(.top, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.55, green: 0.45, blue: 0.35))
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                }
            }
            .onAppear {
                selectedHour = viewModel.settings.deadlineHour
                selectedMinute = viewModel.settings.deadlineMinute
                userName = viewModel.settings.userName
            }
        }
    }

    func saveSettings() {
        viewModel.settings.deadlineHour = selectedHour
        viewModel.settings.deadlineMinute = selectedMinute
        viewModel.settings.userName = userName
        viewModel.saveSettings()
    }
}

#Preview {
    SettingsView()
        .environmentObject(BedVerificationViewModel())
}
