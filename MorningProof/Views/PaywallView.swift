import SwiftUI
import StoreKit

struct PaywallView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedPlan: PlanType = .yearly
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    enum PlanType {
        case monthly
        case yearly
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.96, blue: 0.93),
                        Color(red: 0.95, green: 0.92, blue: 0.88)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Features
                        featuresSection

                        // Plan Selection
                        planSelectionSection

                        // Subscribe Button
                        subscribeButton

                        // Terms
                        termsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
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
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Header

    var headerSection: some View {
        VStack(spacing: 16) {
            // Premium badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.9, green: 0.6, blue: 0.35),
                                Color(red: 0.85, green: 0.65, blue: 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color(red: 0.9, green: 0.6, blue: 0.35).opacity(0.4), radius: 15, x: 0, y: 5)

                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                Text("Unlock Premium")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                Text("Build better mornings with full access")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Features

    var featuresSection: some View {
        VStack(spacing: 0) {
            FeatureRow(icon: "infinity", title: "Unlimited Habits", description: "Track as many morning habits as you want", isPremium: true)
            Divider().padding(.horizontal, 16)
            FeatureRow(icon: "camera.viewfinder", title: "Unlimited AI Verifications", description: "Verify your bed every day with AI", isPremium: true)
            Divider().padding(.horizontal, 16)
            FeatureRow(icon: "flame.fill", title: "Streak Recovery", description: "1 free recovery per month + buy more", isPremium: true)
            Divider().padding(.horizontal, 16)
            FeatureRow(icon: "chart.bar.fill", title: "Insights & Analytics", description: "Coming soon", isPremium: true, comingSoon: true)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 3)
    }

    // MARK: - Plan Selection

    var planSelectionSection: some View {
        VStack(spacing: 12) {
            // Yearly plan (recommended)
            PlanCard(
                isSelected: selectedPlan == .yearly,
                title: "Yearly",
                price: subscriptionManager.yearlyPrice,
                period: "/year",
                badge: subscriptionManager.yearlySavings
            ) {
                selectedPlan = .yearly
            }

            // Monthly plan
            PlanCard(
                isSelected: selectedPlan == .monthly,
                title: "Monthly",
                price: subscriptionManager.monthlyPrice,
                period: "/month",
                badge: nil
            ) {
                selectedPlan = .monthly
            }
        }
    }

    // MARK: - Subscribe Button

    var subscribeButton: some View {
        VStack(spacing: 8) {
            Button {
                Task {
                    await subscribe()
                }
            } label: {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Start 7-Day Free Trial")
                            .fontWeight(.semibold)
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.55, green: 0.45, blue: 0.35),
                            Color(red: 0.45, green: 0.35, blue: 0.28)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color(red: 0.55, green: 0.45, blue: 0.35).opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .disabled(isPurchasing)

            Text("Then \(selectedPlan == .yearly ? subscriptionManager.yearlyPrice : subscriptionManager.monthlyPrice)\(selectedPlan == .yearly ? "/year" : "/month")")
                .font(.caption)
                .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
        }
    }

    // MARK: - Terms

    var termsSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await subscriptionManager.restorePurchases()
                }
            } label: {
                Text("Restore Purchases")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.55, green: 0.45, blue: 0.35))
            }

            Text("Cancel anytime. Subscription auto-renews unless cancelled at least 24 hours before the end of the current period.")
                .font(.caption2)
                .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Actions

    private func subscribe() async {
        isPurchasing = true

        do {
            let transaction: StoreKit.Transaction?
            if selectedPlan == .yearly {
                transaction = try await subscriptionManager.purchaseYearly()
            } else {
                transaction = try await subscriptionManager.purchaseMonthly()
            }

            if transaction != nil {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isPurchasing = false
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let isPremium: Bool
    var comingSoon: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        isPremium
                            ? Color(red: 0.95, green: 0.9, blue: 0.85)
                            : Color(red: 0.92, green: 0.9, blue: 0.87)
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(
                        isPremium
                            ? Color(red: 0.9, green: 0.6, blue: 0.35)
                            : Color(red: 0.6, green: 0.5, blue: 0.4)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                    if comingSoon {
                        Text("Soon")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.35))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(red: 0.95, green: 0.9, blue: 0.85))
                            .cornerRadius(4)
                    }
                }

                Text(description)
                    .font(.caption)
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(red: 0.55, green: 0.75, blue: 0.55))
        }
        .padding(16)
    }
}

struct PlanCard: View {
    let isSelected: Bool
    let title: String
    let price: String
    let period: String
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                        if let badge = badge {
                            Text(badge)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(red: 0.55, green: 0.75, blue: 0.55))
                                .cornerRadius(6)
                        }
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(price)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                        Text(period)
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(
                            isSelected
                                ? Color(red: 0.55, green: 0.45, blue: 0.35)
                                : Color(red: 0.8, green: 0.75, blue: 0.7),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color(red: 0.55, green: 0.45, blue: 0.35))
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected
                            ? Color(red: 0.55, green: 0.45, blue: 0.35)
                            : Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PaywallView(subscriptionManager: SubscriptionManager.shared)
}
