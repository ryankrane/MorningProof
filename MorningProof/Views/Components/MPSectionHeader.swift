import SwiftUI

struct MPSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailing: String? = nil
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: MPSpacing.xs) {
                Text(title.uppercased())
                    .font(MPFont.labelSmall())
                    .foregroundColor(MPColors.textTertiary)
                    .tracking(0.5)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textMuted)
                }
            }

            Spacer()

            if let trailing = trailing {
                if let action = trailingAction {
                    Button(action: action) {
                        Text(trailing)
                            .font(MPFont.labelSmall())
                            .foregroundColor(MPColors.primary)
                    }
                } else {
                    Text(trailing)
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }
            }
        }
        .padding(.horizontal, MPSpacing.xs)
    }
}

// MARK: - List Row Components

struct MPListRow<Leading: View, Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    let leading: Leading
    let trailing: Trailing

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: MPSpacing.md) {
            leading

            VStack(alignment: .leading, spacing: MPSpacing.xs) {
                Text(title)
                    .font(MPFont.labelMedium())
                    .foregroundColor(MPColors.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }
            }

            Spacer()

            trailing
        }
        .padding(.vertical, MPSpacing.md)
    }
}

// MARK: - Icon Badge

struct MPIconBadge: View {
    let icon: String
    var size: BadgeSize = .medium
    var style: BadgeStyle = .neutral

    enum BadgeSize {
        case small   // 36pt
        case medium  // 44pt
        case large   // 56pt

        var dimension: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 44
            case .large: return 56
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return MPIconSize.sm
            case .medium: return MPIconSize.md
            case .large: return MPIconSize.lg
            }
        }
    }

    enum BadgeStyle {
        case neutral
        case active
        case success
        case warning
        case premium

        var backgroundColor: Color {
            switch self {
            case .neutral: return MPColors.surfaceSecondary
            case .active: return MPColors.primary.opacity(0.15)
            case .success: return MPColors.successLight
            case .warning: return MPColors.errorLight
            case .premium: return MPColors.accentLight
            }
        }

        var iconColor: Color {
            switch self {
            case .neutral: return MPColors.textTertiary
            case .active: return MPColors.primary
            case .success: return MPColors.success
            case .warning: return MPColors.error
            case .premium: return MPColors.accent
            }
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(style.backgroundColor)
                .frame(width: size.dimension, height: size.dimension)

            Image(systemName: icon)
                .font(.system(size: size.iconSize))
                .foregroundColor(style.iconColor)
        }
    }
}

#Preview {
    VStack(spacing: MPSpacing.xxl) {
        MPSectionHeader(title: "Today's Habits", trailing: "See All") {
            print("tapped")
        }

        MPSectionHeader(title: "Settings", subtitle: "Customize your experience")

        MPCard {
            VStack(spacing: 0) {
                MPListRow(title: "Made Bed", subtitle: "AI Verified") {
                    MPIconBadge(icon: "bed.double.fill", style: .success)
                } trailing: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(MPColors.success)
                }

                Divider()
                    .padding(.leading, 60)

                MPListRow(title: "Morning Steps", subtitle: "365/500 steps") {
                    MPIconBadge(icon: "figure.walk", style: .active)
                } trailing: {
                    Text("73%")
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.textSecondary)
                }
            }
        }

        HStack(spacing: MPSpacing.lg) {
            MPIconBadge(icon: "flame.fill", size: .small, style: .premium)
            MPIconBadge(icon: "bed.double.fill", size: .medium, style: .success)
            MPIconBadge(icon: "figure.walk", size: .large, style: .active)
        }
    }
    .padding(MPSpacing.xl)
    .background(MPColors.background)
}
