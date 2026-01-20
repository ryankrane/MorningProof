import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: BedVerificationViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedHour: Int = 9
    @State private var selectedMinute: Int = 0
    @State private var userName: String = ""
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: MPSpacing.xl) {
                        // Name section
                        VStack(alignment: .leading, spacing: MPSpacing.md) {
                            Text("Your Name")
                                .font(MPFont.labelMedium())
                                .foregroundColor(MPColors.textSecondary)

                            TextField("Enter your name", text: $userName)
                                .padding(MPSpacing.lg)
                                .background(MPColors.surface)
                                .cornerRadius(MPRadius.md)
                                .mpShadow(.small)
                        }

                        // Deadline section
                        VStack(alignment: .leading, spacing: MPSpacing.md) {
                            Text("Daily Deadline")
                                .font(MPFont.labelMedium())
                                .foregroundColor(MPColors.textSecondary)

                            Text("Make your bed before this time each day")
                                .font(MPFont.bodySmall())
                                .foregroundColor(MPColors.textTertiary)

                            HStack(spacing: MPSpacing.md) {
                                // Hour picker
                                Picker("Hour", selection: $selectedHour) {
                                    ForEach(5..<13) { hour in
                                        Text("\(hour)").tag(hour)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 80, height: 120)
                                .clipped()
                                .background(MPColors.surface)
                                .cornerRadius(MPRadius.md)

                                Text(":")
                                    .font(.title)
                                    .foregroundColor(MPColors.textPrimary)

                                // Minute picker
                                Picker("Minute", selection: $selectedMinute) {
                                    ForEach([0, 15, 30, 45], id: \.self) { minute in
                                        Text(String(format: "%02d", minute)).tag(minute)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 80, height: 120)
                                .clipped()
                                .background(MPColors.surface)
                                .cornerRadius(MPRadius.md)

                                Text("AM")
                                    .font(MPFont.labelLarge())
                                    .foregroundColor(MPColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MPSpacing.lg)
                            .background(MPColors.surface)
                            .cornerRadius(MPRadius.lg)
                            .mpShadow(.medium)
                        }

                        // Current deadline display
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(MPColors.primary)
                            Text("Deadline set to \(selectedHour):\(String(format: "%02d", selectedMinute)) AM")
                                .font(MPFont.bodyMedium())
                                .foregroundColor(MPColors.textPrimary)
                            Spacer()
                        }
                        .padding(MPSpacing.lg)
                        .background(MPColors.surfaceHighlight)
                        .cornerRadius(MPRadius.md)

                        Spacer(minLength: 40)

                        // Delete account & data button
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Account & Data")
                            }
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.error)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MPSpacing.md)
                            .background(MPColors.surface)
                            .cornerRadius(MPRadius.md)
                            .mpShadow(.small)
                        }

                        Text("Version 1.0")
                            .font(MPFont.labelTiny())
                            .foregroundColor(MPColors.textMuted)
                            .padding(.top, MPSpacing.xl)
                    }
                    .padding(.horizontal, MPSpacing.xl)
                    .padding(.top, MPSpacing.xl)
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
                    .foregroundColor(MPColors.primary)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(MPColors.textTertiary)
                }
            }
            .onAppear {
                selectedHour = viewModel.settings.deadlineHour
                selectedMinute = viewModel.settings.deadlineMinute
                userName = viewModel.settings.userName
            }
            .alert("Delete Account & Data?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    MorningProofManager.shared.resetAllData()
                    dismiss()
                }
            } message: {
                Text("This will permanently delete your account and all data including habits, streaks, and settings. This cannot be undone.")
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
