import SwiftUI

// MARK: - Onboarding Feature Row (Paywall Style)

/// Feature row matching the paywall design - gold checkmark circle with title and subtitle
struct OnboardingFeatureRow: View {
    let title: String
    let subtitle: String
    var icon: String = "checkmark"

    var body: some View {
        HStack(alignment: .top, spacing: MPSpacing.lg) {
            // Gold circle with checkmark
            ZStack {
                Circle()
                    .fill(MPColors.accent)
                    .frame(width: 28, height: 28)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(MPColors.textPrimary)

                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundColor(MPColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}

// MARK: - Onboarding Hero Title

/// Large centered headline for onboarding steps
struct OnboardingHeroTitle: View {
    let text: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: MPSpacing.md) {
            Text(text)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(MPColors.textPrimary)
                .multilineTextAlignment(.center)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Onboarding Selection Card

/// Card for single selection options (like gender, morning struggle)
struct OnboardingSelectionCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MPSpacing.lg) {
                // Icon in circle
                ZStack {
                    Circle()
                        .fill(isSelected ? MPColors.accent.opacity(0.15) : MPColors.surfaceSecondary)
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18))
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
    }
}

// MARK: - Onboarding Multi-Select Card

/// Card for multi-selection options (like obstacles, desired outcomes)
struct OnboardingMultiSelectCard: View {
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
                            .fill(isSelected ? MPColors.accent.opacity(0.15) : MPColors.surfaceSecondary)
                            .frame(width: 48, height: 48)

                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? MPColors.accent : MPColors.textTertiary)
                    }

                    if let badge = badge {
                        Text(badge)
                            .font(.system(size: 9, weight: .bold))
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
    }
}

// MARK: - Onboarding Stat Card

/// Compact stat display for statistics steps
struct OnboardingStatCard: View {
    let value: String
    let label: String
    let icon: String
    var iconColor: Color = MPColors.accent

    var body: some View {
        VStack(spacing: MPSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(MPColors.textPrimary)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(MPColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MPSpacing.lg)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.md)
    }
}

// MARK: - Onboarding Progress Indicator

/// Simple, clean progress bar for onboarding
struct OnboardingProgressIndicator: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(MPColors.progressBg)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(MPColors.accent)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Onboarding Info Card

/// Info card with icon and description
struct OnboardingInfoCard: View {
    let icon: String
    let title: String
    let description: String
    var iconColor: Color = MPColors.accent

    var body: some View {
        HStack(spacing: MPSpacing.lg) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MPColors.textPrimary)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer()
        }
        .padding(MPSpacing.lg)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: MPSpacing.xl) {
            OnboardingHeroTitle(
                text: "Become a morning\nperson. Finally.",
                subtitle: "Build habits that stick"
            )

            VStack(spacing: MPSpacing.md) {
                OnboardingFeatureRow(
                    title: "Proof you can't fake",
                    subtitle: "AI checks your habits so you actually do them"
                )

                OnboardingFeatureRow(
                    title: "End doom scrolling",
                    subtitle: "Apps stay locked until you earn your morning"
                )
            }
            .padding(.horizontal, MPSpacing.xl)

            OnboardingProgressIndicator(progress: 0.4)
                .padding(.horizontal, MPSpacing.xl)

            VStack(spacing: MPSpacing.md) {
                OnboardingSelectionCard(
                    title: "Male",
                    icon: "figure.stand",
                    isSelected: true
                ) { }

                OnboardingSelectionCard(
                    title: "Female",
                    icon: "figure.stand.dress",
                    isSelected: false
                ) { }
            }
            .padding(.horizontal, MPSpacing.xl)

            HStack(spacing: MPSpacing.md) {
                OnboardingStatCard(value: "73%", label: "abandon routines", icon: "chart.line.downtrend.xyaxis")
                OnboardingStatCard(value: "3.5x", label: "more productive", icon: "bolt.fill")
            }
            .padding(.horizontal, MPSpacing.xl)
        }
        .padding(.vertical, MPSpacing.xl)
    }
    .background(MPColors.background)
}
