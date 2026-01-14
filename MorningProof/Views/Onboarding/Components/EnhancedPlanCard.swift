import SwiftUI

/// Enhanced plan selection card for paywall
struct EnhancedPlanCard: View {
    let isSelected: Bool
    let title: String
    let price: String
    let period: String
    let monthlyEquivalent: String?
    let badge: String?
    let isHighlighted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Badge bar (if highlighted)
                if isHighlighted, let badge = badge {
                    Text(badge)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MPSpacing.sm)
                        .background(MPColors.accent)
                }

                // Main content
                HStack {
                    VStack(alignment: .leading, spacing: MPSpacing.xs) {
                        // Title row
                        HStack(spacing: MPSpacing.sm) {
                            Text(title)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(MPColors.textPrimary)

                            if !isHighlighted, let badge = badge {
                                Text(badge)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, MPSpacing.sm)
                                    .padding(.vertical, 3)
                                    .background(MPColors.success)
                                    .cornerRadius(MPRadius.sm)
                            }
                        }

                        // Price row
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(price)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(MPColors.textPrimary)

                            Text(period)
                                .font(.system(size: 14))
                                .foregroundColor(MPColors.textTertiary)
                        }

                        // Monthly equivalent
                        if let monthly = monthlyEquivalent {
                            Text(monthly)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(MPColors.textSecondary)
                        }
                    }

                    Spacer()

                    // Selection indicator
                    ZStack {
                        Circle()
                            .stroke(isSelected ? MPColors.primary : MPColors.border, lineWidth: 2)
                            .frame(width: 26, height: 26)

                        if isSelected {
                            Circle()
                                .fill(MPColors.primary)
                                .frame(width: 16, height: 16)
                        }
                    }
                }
                .padding(MPSpacing.lg)
            }
            .background(MPColors.surface)
            .cornerRadius(isHighlighted ? MPRadius.lg : MPRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: isHighlighted ? MPRadius.lg : MPRadius.lg)
                    .stroke(
                        isSelected ? MPColors.primary : (isHighlighted ? MPColors.accent : Color.clear),
                        lineWidth: isSelected ? 2 : (isHighlighted ? 2 : 0)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: MPRadius.lg))
            .mpShadow(isHighlighted ? .medium : .small)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Trust badge row for paywall
struct TrustBadgeRow: View {
    var body: some View {
        HStack(spacing: MPSpacing.xl) {
            TrustBadge(icon: "lock.fill", text: "Secure")
            TrustBadge(icon: "arrow.uturn.backward", text: "Cancel anytime")
            TrustBadge(icon: "checkmark.shield.fill", text: "Guaranteed")
        }
        .foregroundColor(MPColors.textTertiary)
    }
}

struct TrustBadge: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
    }
}

/// Feature row for paywall features list
struct PaywallFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let isIncluded: Bool

    init(icon: String, title: String, subtitle: String? = nil, isIncluded: Bool = true) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isIncluded = isIncluded
    }

    var body: some View {
        HStack(spacing: MPSpacing.md) {
            ZStack {
                Circle()
                    .fill(MPColors.accentLight)
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(MPColors.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(MPColors.textTertiary)
                }
            }

            Spacer()

            Image(systemName: isIncluded ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(isIncluded ? MPColors.success : MPColors.textMuted)
        }
        .padding(.vertical, MPSpacing.sm)
    }
}

#Preview {
    VStack(spacing: 16) {
        EnhancedPlanCard(
            isSelected: true,
            title: "Yearly",
            price: "$29.99",
            period: "/year",
            monthlyEquivalent: "Just $2.50/month",
            badge: "MOST POPULAR",
            isHighlighted: true
        ) {}

        EnhancedPlanCard(
            isSelected: false,
            title: "Monthly",
            price: "$4.99",
            period: "/month",
            monthlyEquivalent: nil,
            badge: nil,
            isHighlighted: false
        ) {}

        Divider()

        VStack(spacing: 0) {
            PaywallFeatureRow(icon: "infinity", title: "Unlimited habits", subtitle: "Track as many as you want")
            PaywallFeatureRow(icon: "camera.viewfinder", title: "Unlimited AI verifications")
            PaywallFeatureRow(icon: "flame.fill", title: "Streak recovery", subtitle: "1 free per month")
        }
        .padding()
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)

        TrustBadgeRow()
    }
    .padding()
}
