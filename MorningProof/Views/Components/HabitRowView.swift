import SwiftUI

/// A reusable habit row showing icon, name, and verification badge
/// Used in the main routine list
struct HabitRowView: View {
    let icon: String
    let name: String
    let verificationTier: HabitVerificationTier?
    let customVerificationType: CustomVerificationType?

    init(icon: String, name: String, verificationTier: HabitVerificationTier) {
        self.icon = icon
        self.name = name
        self.verificationTier = verificationTier
        self.customVerificationType = nil
    }

    init(icon: String, name: String, customVerificationType: CustomVerificationType) {
        self.icon = icon
        self.name = name
        self.verificationTier = nil
        self.customVerificationType = customVerificationType
    }

    private var verificationBadgeText: String {
        if let tier = verificationTier {
            return tier.sectionTitle
        } else if let custom = customVerificationType {
            return custom.displayName
        }
        return ""
    }

    private var verificationBadgeIcon: String {
        if let tier = verificationTier {
            return tier.icon
        } else if let custom = customVerificationType {
            return custom.icon
        }
        return "checkmark.circle"
    }

    var body: some View {
        HStack(spacing: MPSpacing.lg) {
            // Icon in circular background
            ZStack {
                Circle()
                    .fill(MPColors.primary.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(MPColors.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(MPFont.labelMedium())
                    .foregroundColor(MPColors.textPrimary)

                // Verification badge
                HStack(spacing: 4) {
                    Image(systemName: verificationBadgeIcon)
                        .font(.system(size: 10))
                    Text(verificationBadgeText)
                        .font(MPFont.labelTiny())
                }
                .foregroundColor(MPColors.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(MPColors.textTertiary)
        }
        .padding(.vertical, MPSpacing.md)
        .padding(.horizontal, MPSpacing.lg)
        .background(MPColors.surface)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: 0) {
        HabitRowView(
            icon: "bed.double.fill",
            name: "Made Bed",
            verificationTier: .aiVerified
        )
        Divider().padding(.leading, 76)
        HabitRowView(
            icon: "moon.zzz.fill",
            name: "Sleep Goal",
            verificationTier: .autoTracked
        )
        Divider().padding(.leading, 76)
        HabitRowView(
            icon: "snowflake",
            name: "Cold Shower",
            verificationTier: .honorSystem
        )
    }
    .background(MPColors.surface)
    .cornerRadius(MPRadius.lg)
    .padding()
    .background(MPColors.background)
}
