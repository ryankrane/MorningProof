import SwiftUI

/// Large statistic card for problem agitation screens
struct StatisticHeroCard: View {
    let value: String
    let label: String
    let citation: String?
    let accentColor: Color

    @State private var animatedProgress: CGFloat = 0
    @State private var showContent = false

    init(
        value: String,
        label: String,
        citation: String? = nil,
        accentColor: Color = MPColors.primary
    ) {
        self.value = value
        self.label = label
        self.citation = citation
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(spacing: MPSpacing.lg) {
            // Value with animated appearance
            Text(value)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(accentColor)
                .scaleEffect(showContent ? 1 : 0.5)
                .opacity(showContent ? 1 : 0)

            // Label
            Text(label)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(MPColors.textSecondary)
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)

            // Citation badge
            if let citation = citation {
                HStack(spacing: MPSpacing.xs) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                        .foregroundColor(MPColors.success)

                    Text(citation)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MPColors.textTertiary)
                }
                .padding(.horizontal, MPSpacing.md)
                .padding(.vertical, MPSpacing.sm)
                .background(MPColors.surface)
                .cornerRadius(MPRadius.full)
                .opacity(showContent ? 1 : 0)
            }
        }
        .padding(MPSpacing.xxl)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                showContent = true
            }
        }
    }
}

/// Ring-style statistic for comparison screens
struct StatisticRingCard: View {
    let percentage: Int
    let label: String
    let comparisonText: String?
    let accentColor: Color

    @State private var animatedProgress: CGFloat = 0
    @State private var showComparison = false

    init(
        percentage: Int,
        label: String,
        comparisonText: String? = nil,
        accentColor: Color = MPColors.primary
    ) {
        self.percentage = percentage
        self.label = label
        self.comparisonText = comparisonText
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(spacing: MPSpacing.lg) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(MPColors.progressBg, lineWidth: 14)
                    .frame(width: 160, height: 160)

                // Progress ring
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))

                // Percentage text
                VStack(spacing: 2) {
                    Text("\(Int(animatedProgress * 100))%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)
                        .contentTransition(.numericText())

                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(MPColors.textSecondary)
                }
            }

            // Comparison text
            if let comparison = comparisonText {
                Text(comparison)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MPColors.textTertiary)
                    .opacity(showComparison ? 1 : 0)
            }
        }
        .padding(MPSpacing.xxl)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.xl)
        .overlay(
            RoundedRectangle(cornerRadius: MPRadius.xl)
                .stroke(
                    LinearGradient(
                        colors: [accentColor.opacity(0.3), accentColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .mpShadow(.large)
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).delay(0.3)) {
                animatedProgress = CGFloat(percentage) / 100.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(1.2)) {
                showComparison = true
            }
        }
    }
}

/// Small stat pill for supporting statistics
struct StatPillView: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: MPSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(MPColors.accent)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(MPColors.textPrimary)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(MPColors.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MPSpacing.md)
        .padding(.horizontal, MPSpacing.sm)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.md)
        .mpShadow(.small)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            StatisticHeroCard(
                value: "73%",
                label: "of people fail their morning goals",
                citation: "Based on survey of 17,000+ users"
            )

            StatisticRingCard(
                percentage: 76,
                label: "success rate",
                comparisonText: "vs 35% who don't track"
            )

            HStack(spacing: 12) {
                StatPillView(value: "42%", label: "more likely", icon: "arrow.up.right")
                StatPillView(value: "2.2x", label: "better results", icon: "chart.line.uptrend.xyaxis")
                StatPillView(value: "95%", label: "w/ accountability", icon: "person.2.fill")
            }
            .padding(.horizontal)
        }
        .padding()
    }
}
