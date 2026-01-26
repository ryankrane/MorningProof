import SwiftUI

struct StreakRecoveryView: View {
    @ObservedObject var manager: MorningProofManager
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss

    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.98, green: 0.96, blue: 0.93)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    // Broken streak illustration
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.98, green: 0.93, blue: 0.9))
                            .frame(width: 120, height: 120)

                        Image(systemName: "flame.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )

                        // Crack overlay
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(red: 0.85, green: 0.6, blue: 0.5))
                            .offset(x: 20, y: -15)
                    }

                    VStack(spacing: 12) {
                        Text("Streak Lost")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                        Text("You missed a day and your \(manager.settings.currentStreak > 0 ? "\(manager.settings.currentStreak)-day" : "") streak has reset to 0.")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // Recovery options
                    VStack(spacing: 16) {
                        if subscriptionManager.isPremium {
                            if subscriptionManager.canUseFreeStreakRecovery {
                                // Free recovery available
                                recoveryOption(
                                    title: "Use Free Recovery",
                                    subtitle: "1 free recovery per month",
                                    buttonText: "Recover Streak",
                                    isFree: true
                                ) {
                                    useFreeRecovery()
                                }
                            } else {
                                // No free recoveries left this month
                                VStack(spacing: 8) {
                                    Text("No recoveries left this month")
                                        .font(.subheadline)
                                        .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                                    Text("Free recovery resets next month")
                                        .font(.caption)
                                        .foregroundColor(Color(red: 0.7, green: 0.6, blue: 0.5))
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 3)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    // Start fresh button
                    Button {
                        dismiss()
                    } label: {
                        Text("Start Fresh")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.55, green: 0.45, blue: 0.35))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(14)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }

                // Success overlay
                if showSuccess {
                    successOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                    }
                }
            }
        }
    }

    // MARK: - Recovery Option Card

    func recoveryOption(title: String, subtitle: String, buttonText: String, isFree: Bool, action: @escaping () -> Void) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color(red: 0.55, green: 0.75, blue: 0.55))
                }

                Spacer()

                Button(action: action) {
                    Text(buttonText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(red: 0.55, green: 0.75, blue: 0.55))
                        .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Success Overlay

    var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.9, green: 0.97, blue: 0.9))
                        .frame(width: 100, height: 100)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 45))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                }

                Text("Streak Recovered!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                Text("Your streak is back!")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))

                Button {
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.55, green: 0.75, blue: 0.55))
                        .cornerRadius(14)
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Actions

    private func useFreeRecovery() {
        subscriptionManager.useFreeStreakRecovery()
        recoverStreak()
    }

    private func recoverStreak() {
        // Restore the streak
        manager.recoverStreak()

        // Show success
        HapticManager.shared.success()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showSuccess = true
        }
    }
}

#Preview {
    StreakRecoveryView(
        manager: MorningProofManager.shared,
        subscriptionManager: SubscriptionManager.shared
    )
}
