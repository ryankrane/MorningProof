import SwiftUI

struct MorningProofSettingsView: View {
    @ObservedObject var manager: MorningProofManager
    @Environment(\.dismiss) var dismiss

    @State private var userName: String = ""
    @State private var wakeTimeHour: Int = 7
    @State private var wakeTimeMinute: Int = 0
    @State private var cutoffHour: Int = 9
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.98, green: 0.96, blue: 0.93)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Section
                        settingsSection(title: "Profile") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Name")
                                    .font(.subheadline)
                                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))

                                TextField("Enter your name", text: $userName)
                                    .textFieldStyle(.plain)
                                    .padding(14)
                                    .background(Color(red: 0.98, green: 0.96, blue: 0.93))
                                    .cornerRadius(10)
                            }
                        }

                        // Time Settings
                        settingsSection(title: "Schedule") {
                            VStack(spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Wake Time")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))
                                        Text("When you plan to wake up")
                                            .font(.caption)
                                            .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                                    }

                                    Spacer()

                                    timePicker(hour: $wakeTimeHour, minute: $wakeTimeMinute)
                                }

                                Divider()

                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Morning Cutoff")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))
                                        Text("Deadline to complete habits")
                                            .font(.caption)
                                            .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                                    }

                                    Spacer()

                                    Picker("Cutoff", selection: $cutoffHour) {
                                        ForEach(6..<13) { hour in
                                            Text("\(hour):00 AM").tag(hour)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Color(red: 0.55, green: 0.45, blue: 0.35))
                                }
                            }
                        }

                        // Habits Section
                        settingsSection(title: "Habits") {
                            VStack(spacing: 0) {
                    ForEach(manager.habitConfigs) { config in
                        habitToggleRow(config: config)

                        if config.id != manager.habitConfigs.last?.id {
                            Divider()
                                .padding(.leading, 50)
                        }
                    }
                }
                        }

                        // Danger Zone
                        settingsSection(title: "Data") {
                            Button {
                                showResetConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Reset All Data")
                                }
                                .font(.subheadline)
                                .foregroundColor(Color(red: 0.85, green: 0.5, blue: 0.45))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                        }

                        // App Info
                        VStack(spacing: 4) {
                            Text("Morning Proof")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                            Text("Version 1.0")
                                .font(.caption2)
                                .foregroundColor(Color(red: 0.7, green: 0.65, blue: 0.6))
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.55, green: 0.45, blue: 0.35))
                }
            }
            .onAppear {
                loadSettings()
            }
            .alert("Reset All Data?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    manager.resetAllData()
                    dismiss()
                }
            } message: {
                Text("This will delete all your habits, streaks, and settings. This cannot be undone.")
            }
        }
    }

    func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                .padding(.leading, 4)

            VStack {
                content()
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }

    func timePicker(hour: Binding<Int>, minute: Binding<Int>) -> some View {
        HStack(spacing: 4) {
            Picker("Hour", selection: hour) {
                ForEach(4..<12) { h in
                    Text("\(h)").tag(h)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 50)

            Text(":")
                .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))

            Picker("Minute", selection: minute) {
                ForEach([0, 15, 30, 45], id: \.self) { m in
                    Text(String(format: "%02d", m)).tag(m)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 50)

            Text("AM")
                .font(.caption)
                .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
        }
        .tint(Color(red: 0.55, green: 0.45, blue: 0.35))
    }

    func habitToggleRow(config: HabitConfig) -> some View {
        HStack(spacing: 14) {
            Image(systemName: config.habitType.icon)
                .font(.system(size: 18))
                .foregroundColor(Color(red: 0.6, green: 0.55, blue: 0.5))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(config.habitType.displayName)
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                Text(config.habitType.tier.description)
                    .font(.caption2)
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { config.isEnabled },
                set: { newValue in
                    manager.updateHabitConfig(config.habitType, isEnabled: newValue)
                }
            ))
            .tint(Color(red: 0.55, green: 0.45, blue: 0.35))
        }
        .padding(.vertical, 8)
    }

    func loadSettings() {
        userName = manager.settings.userName
        wakeTimeHour = manager.settings.wakeTimeHour
        wakeTimeMinute = manager.settings.wakeTimeMinute
        cutoffHour = manager.settings.morningCutoffHour
    }

    func saveSettings() {
        manager.settings.userName = userName
        manager.settings.wakeTimeHour = wakeTimeHour
        manager.settings.wakeTimeMinute = wakeTimeMinute
        manager.settings.morningCutoffHour = cutoffHour
        manager.saveCurrentState()
    }
}

#Preview {
    MorningProofSettingsView(manager: MorningProofManager.shared)
}
