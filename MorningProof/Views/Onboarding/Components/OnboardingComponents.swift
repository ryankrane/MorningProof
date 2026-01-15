import SwiftUI

// MARK: - Onboarding Brand Header

/// Compact header with app branding for onboarding screens
struct OnboardingBrandHeader: View {
    var showBackButton: Bool = false
    var showRestoreButton: Bool = false
    var onBack: (() -> Void)? = nil
    var onRestore: (() -> Void)? = nil

    var body: some View {
        HStack {
            if showBackButton {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(MPColors.textSecondary)
                }
            }

            Spacer()

            // App branding
            HStack(spacing: MPSpacing.sm) {
                Image(systemName: "sunrise.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MPColors.accent, MPColors.accentGold],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text("Morning Proof")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(MPColors.accent)
            }

            Spacer()

            if showRestoreButton {
                Button(action: { onRestore?() }) {
                    Text("Restore")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(MPColors.textSecondary)
                }
            } else if showBackButton {
                // Spacer to balance the back button
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, MPSpacing.lg)
        .padding(.vertical, MPSpacing.md)
    }
}

// MARK: - Feature Bullet (Paywall Style)

/// Orange checkmark bullet with title and subtitle
struct OnboardingFeatureBullet: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: MPSpacing.lg) {
            // Orange checkmark circle
            ZStack {
                Circle()
                    .fill(MPColors.accent)
                    .frame(width: 28, height: 28)

                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(MPColors.textPrimary)

                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundColor(MPColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.vertical, MPSpacing.sm)
    }
}

// MARK: - Pricing Plan Card (Side-by-Side Style)

/// Compact pricing card for side-by-side layout
struct CompactPlanCard: View {
    let title: String
    let price: String
    let period: String
    let isSelected: Bool
    let isMostPopular: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Most Popular badge
                if isMostPopular {
                    Text("Most Popular")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(MPColors.accent)
                }

                VStack(spacing: MPSpacing.sm) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MPColors.textSecondary)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(price)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(MPColors.textPrimary)

                        Text(period)
                            .font(.system(size: 14))
                            .foregroundColor(MPColors.textSecondary)
                    }

                    // Selection indicator
                    ZStack {
                        Circle()
                            .stroke(isSelected ? MPColors.accent : MPColors.border, lineWidth: 2)
                            .frame(width: 22, height: 22)

                        if isSelected {
                            Circle()
                                .fill(MPColors.accent)
                                .frame(width: 14, height: 14)
                        }
                    }
                }
                .padding(.vertical, MPSpacing.lg)
                .padding(.horizontal, MPSpacing.md)
            }
            .frame(maxWidth: .infinity)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: MPRadius.lg)
                    .stroke(isSelected ? MPColors.accent : MPColors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Black CTA Button

/// Full-width black button for primary actions
struct OnboardingCTAButton: View {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.black)
            .cornerRadius(MPRadius.lg)
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1)
    }
}

// MARK: - Reassurance Text

/// "No Commitment - Cancel Anytime" style text with checkmark
struct ReassuranceText: View {
    let text: String
    var showCheckmark: Bool = true

    var body: some View {
        HStack(spacing: MPSpacing.sm) {
            if showCheckmark {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(MPColors.textSecondary)
            }

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(MPColors.textSecondary)
        }
    }
}

// MARK: - Selection Card (Orange Accent)

/// Selection card with orange border when selected
struct OnboardingSelectionCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MPSpacing.lg) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(isSelected ? MPColors.accentLight : MPColors.surfaceSecondary)
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? MPColors.accent : MPColors.textTertiary)
                }

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(MPColors.textPrimary)

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? MPColors.accent : MPColors.border, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(MPColors.accent)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(MPSpacing.lg)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: MPRadius.lg)
                    .stroke(isSelected ? MPColors.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Grid Selection Card (Orange Accent)

/// Compact grid selection card with orange accent
struct OnboardingGridCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    var badge: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: MPSpacing.sm) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? MPColors.accentLight : MPColors.surfaceSecondary)
                            .frame(width: 48, height: 48)

                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? MPColors.accent : MPColors.textTertiary)
                    }

                    if let badge = badge {
                        Text(badge)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(MPColors.accent)
                            .cornerRadius(4)
                            .offset(x: 8, y: -4)
                    }
                }

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 100)
            .padding(.vertical, MPSpacing.md)
            .padding(.horizontal, MPSpacing.sm)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: MPRadius.lg)
                    .stroke(isSelected ? MPColors.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Price Display Helper

/// Helper to format and display prices safely
struct PriceDisplay {
    static func format(price: String, fallback: String) -> String {
        // Check for invalid price strings
        if price.isEmpty || price.contains("NaN") || price == "$0.00" {
            return fallback
        }
        return price
    }

    static func monthlyEquivalent(yearlyPrice: Decimal?) -> String {
        guard let yearly = yearlyPrice else {
            return "$2.50/mo"
        }
        let monthly = yearly / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2

        if let formatted = formatter.string(from: NSDecimalNumber(decimal: monthly)) {
            return "\(formatted)/mo"
        }
        return "$2.50/mo"
    }
}

// MARK: - Previews

#Preview("Brand Header") {
    VStack(spacing: 20) {
        OnboardingBrandHeader()
        OnboardingBrandHeader(showBackButton: true, showRestoreButton: true)
    }
    .background(MPColors.background)
}

#Preview("Feature Bullets") {
    VStack(spacing: 0) {
        OnboardingFeatureBullet(
            title: "Proof you can't fake",
            subtitle: "AI checks your habits so you actually do them"
        )
        OnboardingFeatureBullet(
            title: "End doom scrolling",
            subtitle: "Apps stay locked until you earn your morning"
        )
        OnboardingFeatureBullet(
            title: "Morning routine, simplified",
            subtitle: "One app to build habits that stick"
        )
    }
    .padding()
    .background(MPColors.background)
}

#Preview("Plan Cards") {
    HStack(spacing: MPSpacing.md) {
        CompactPlanCard(
            title: "Monthly",
            price: "$4.99",
            period: "/mo",
            isSelected: false,
            isMostPopular: false
        ) {}

        CompactPlanCard(
            title: "Yearly",
            price: "$29.99",
            period: "/yr",
            isSelected: true,
            isMostPopular: true
        ) {}
    }
    .padding()
    .background(MPColors.background)
}

#Preview("Selection Cards") {
    VStack(spacing: MPSpacing.md) {
        OnboardingSelectionCard(
            title: "Male",
            icon: "figure.stand",
            isSelected: true
        ) {}

        OnboardingSelectionCard(
            title: "Female",
            icon: "figure.stand.dress",
            isSelected: false
        ) {}
    }
    .padding()
    .background(MPColors.background)
}
