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
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [MPColors.background, MPColors.surfaceSecondary],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: MPSpacing.xxl) {
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
                .padding(.horizontal, MPSpacing.xl)
                .padding(.top, MPSpacing.sm)
                .padding(.bottom, MPSpacing.xxxl)
            }

            // Close button overlay (top-right)
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(MPColors.textTertiary)
                    }
                    .padding(MPSpacing.lg)
                }
                Spacer()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Header

    var headerSection: some View {
        VStack(spacing: MPSpacing.lg) {
            // Premium badge
            ZStack {
                Circle()
                    .fill(MPColors.accentGradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: MPColors.accent.opacity(0.4), radius: 15, x: 0, y: 5)

                Image(systemName: "crown.fill")
                    .font(.system(size: MPIconSize.xl))
                    .foregroundColor(.white)
            }

            VStack(spacing: MPSpacing.sm) {
                Text("Unlock Premium")
                    .font(MPFont.headingLarge())
                    .foregroundColor(MPColors.textPrimary)

                Text("Build better mornings with full access")
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, MPSpacing.xl)
    }

    // MARK: - Features

    var featuresSection: some View {
        VStack(spacing: 0) {
            FeatureRow(icon: "infinity", title: "Unlimited Habits", description: "Track as many morning habits as you want", isPremium: true)
            Divider().padding(.horizontal, MPSpacing.lg)
            FeatureRow(icon: "camera.viewfinder", title: "Unlimited AI Verifications", description: "Verify your bed every day with AI", isPremium: true)
            Divider().padding(.horizontal, MPSpacing.lg)
            FeatureRow(icon: "flame.fill", title: "Streak Recovery", description: "1 free recovery per month + buy more", isPremium: true)
            Divider().padding(.horizontal, MPSpacing.lg)
            FeatureRow(icon: "chart.bar.fill", title: "Insights & Analytics", description: "Coming soon", isPremium: true, comingSoon: true)
        }
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.medium)
    }

    // MARK: - Plan Selection

    var planSelectionSection: some View {
        VStack(spacing: MPSpacing.md) {
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
        VStack(spacing: MPSpacing.sm) {
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
                        Text("Subscribe")
                            .fontWeight(.semibold)
                    }
                }
                .font(MPFont.labelLarge())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: MPButtonHeight.lg)
                .background(MPColors.primaryGradient)
                .cornerRadius(MPRadius.lg)
                .shadow(color: MPColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .disabled(isPurchasing)

            Text("\(selectedPlan == .yearly ? subscriptionManager.yearlyPrice : subscriptionManager.monthlyPrice)\(selectedPlan == .yearly ? "/year" : "/month")")
                .font(MPFont.bodySmall())
                .foregroundColor(MPColors.textTertiary)
        }
    }

    // MARK: - Terms

    var termsSection: some View {
        VStack(spacing: MPSpacing.md) {
            Button {
                Task {
                    await subscriptionManager.restorePurchases()
                }
            } label: {
                Text("Restore Purchases")
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.primary)
            }

            Text("Cancel anytime. Subscription auto-renews unless cancelled at least 24 hours before the end of the current period.")
                .font(MPFont.labelTiny())
                .foregroundColor(MPColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MPSpacing.xl)

            HStack(spacing: MPSpacing.lg) {
                Link("Privacy Policy", destination: URL(string: "https://ryankrane.github.io/morningproof-legal/privacy.html")!)
                    .font(MPFont.labelTiny())
                    .foregroundColor(MPColors.textTertiary)

                Link("Terms of Service", destination: URL(string: "https://ryankrane.github.io/morningproof-legal/terms.html")!)
                    .font(MPFont.labelTiny())
                    .foregroundColor(MPColors.textTertiary)
            }
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
        HStack(spacing: MPSpacing.lg) {
            ZStack {
                Circle()
                    .fill(isPremium ? MPColors.accentLight : MPColors.progressBg)
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: MPIconSize.sm))
                    .foregroundColor(isPremium ? MPColors.accent : MPColors.textTertiary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: MPSpacing.sm) {
                    Text(title)
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.textPrimary)

                    if comingSoon {
                        Text("Soon")
                            .font(MPFont.labelTiny())
                            .foregroundColor(MPColors.accent)
                            .padding(.horizontal, MPSpacing.sm)
                            .padding(.vertical, 2)
                            .background(MPColors.accentLight)
                            .cornerRadius(MPRadius.xs)
                    }
                }

                Text(description)
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.textTertiary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(MPColors.success)
        }
        .padding(MPSpacing.lg)
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
                VStack(alignment: .leading, spacing: MPSpacing.xs) {
                    HStack(spacing: MPSpacing.sm) {
                        Text(title)
                            .font(MPFont.labelLarge())
                            .foregroundColor(MPColors.textPrimary)

                        if let badge = badge {
                            Text(badge)
                                .font(MPFont.bodySmall())
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, MPSpacing.sm)
                                .padding(.vertical, 3)
                                .background(MPColors.success)
                                .cornerRadius(MPRadius.sm)
                        }
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(price)
                            .font(MPFont.headingMedium())
                            .foregroundColor(MPColors.textPrimary)

                        Text(period)
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textTertiary)
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? MPColors.primary : MPColors.border, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(MPColors.primary)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(MPSpacing.lg)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: MPRadius.lg)
                    .stroke(isSelected ? MPColors.primary : Color.clear, lineWidth: 2)
            )
            .mpShadow(.small)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PaywallView(subscriptionManager: SubscriptionManager.shared)
}
