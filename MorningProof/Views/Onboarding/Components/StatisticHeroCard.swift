import SwiftUI

/// Large statistic card for problem agitation screens
struct StatisticHeroCard: View {
    let value: String
    let label: String
    let citation: String?
    let accentColor: Color

    @State private var animatedValue: Int = 0
    @State private var showContent = false

    // Extract numeric value and suffix (e.g., "73%" -> 73 and "%")
    private var numericValue: Int {
        let digits = value.filter { $0.isNumber }
        return Int(digits) ?? 0
    }

    private var suffix: String {
        value.filter { !$0.isNumber }
    }

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
            // Value with counting animation
            Text("\(animatedValue)\(suffix)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(accentColor)
                .contentTransition(.numericText())
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
            // Start counting animation after a brief delay
            startCountingAnimation()
        }
    }

    private func startCountingAnimation() {
        let target = numericValue
        let duration: Double = 1.2
        let steps = min(target, 30) // Cap steps for smooth animation
        let stepDuration = duration / Double(steps)

        for i in 0...steps {
            let value = Int(Double(i) / Double(steps) * Double(target))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + stepDuration * Double(i)) {
                withAnimation(.easeOut(duration: 0.05)) {
                    animatedValue = value
                }
            }
        }
        // Ensure final value is exact
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + duration) {
            withAnimation(.easeOut(duration: 0.05)) {
                animatedValue = target
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
    @State private var displayedNumber: Int = 0
    @State private var showComparison = false
    @State private var glowOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.8
    @State private var showEndCap = false
    @State private var pulseGlow = false

    private let ringSize: CGFloat = 200
    private let ringWidth: CGFloat = 16

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
                // Ambient background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentColor.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 60,
                            endRadius: 140
                        )
                    )
                    .frame(width: ringSize + 60, height: ringSize + 60)
                    .opacity(glowOpacity)
                    .scaleEffect(pulseGlow ? 1.08 : 1.0)

                // Outer decorative ring
                Circle()
                    .stroke(accentColor.opacity(0.08), lineWidth: 1)
                    .frame(width: ringSize + 40, height: ringSize + 40)
                    .opacity(glowOpacity)

                // Second decorative ring
                Circle()
                    .stroke(accentColor.opacity(0.12), lineWidth: 1)
                    .frame(width: ringSize + 24, height: ringSize + 24)
                    .opacity(glowOpacity)

                // Background ring with gradient
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [MPColors.progressBg.opacity(0.6), MPColors.progressBg],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: ringWidth
                    )
                    .frame(width: ringSize, height: ringSize)

                // Progress ring glow layer
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        accentColor.opacity(0.4),
                        style: StrokeStyle(lineWidth: ringWidth + 8, lineCap: .round)
                    )
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 8)

                // Main progress ring
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        AngularGradient(
                            colors: [
                                accentColor.opacity(0.5),
                                accentColor.opacity(0.8),
                                accentColor,
                                accentColor
                            ],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360 * Double(animatedProgress))
                        ),
                        style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                    )
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: accentColor.opacity(0.6), radius: 12, x: 0, y: 0)

                // Glowing end cap dot
                if showEndCap && animatedProgress > 0.05 {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white, accentColor],
                                center: .center,
                                startRadius: 0,
                                endRadius: 8
                            )
                        )
                        .frame(width: 12, height: 12)
                        .shadow(color: accentColor, radius: 8)
                        .shadow(color: .white.opacity(0.5), radius: 4)
                        .offset(y: -ringSize / 2)
                        .rotationEffect(.degrees(-90 + 360 * Double(animatedProgress)))
                }

                // Center content
                VStack(spacing: 6) {
                    Text("\(displayedNumber)%")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [MPColors.textPrimary, MPColors.textPrimary.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text(label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MPColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .scaleEffect(ringScale)

            // Comparison text
            if let comparison = comparisonText {
                Text(comparison)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MPColors.textTertiary)
                    .opacity(showComparison ? 1 : 0)
            }
        }
        .padding(.vertical, MPSpacing.xxl)
        .padding(.horizontal, MPSpacing.xl)
        .onAppear {
            // Scale in the ring
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                ringScale = 1.0
            }

            // Start glow
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                glowOpacity = 1.0
            }

            // Show end cap
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showEndCap = true
            }

            // Animate the progress ring
            withAnimation(.easeOut(duration: 1.8).delay(0.3)) {
                animatedProgress = CGFloat(percentage) / 100.0
            }

            // Count up the number
            animateNumber()

            // Show comparison text
            withAnimation(.easeOut(duration: 0.5).delay(1.8)) {
                showComparison = true
            }

            // Start subtle pulse glow after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    pulseGlow = true
                }
            }
        }
    }

    private func animateNumber() {
        let duration: Double = 1.8
        let steps = 60
        let stepDuration = duration / Double(steps)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(step) * stepDuration) {
                // Ease-out curve for counting
                let progress = Double(step) / Double(steps)
                let easedProgress = 1 - pow(1 - progress, 3)
                displayedNumber = Int(easedProgress * Double(percentage))
            }
        }
    }
}

/// Small stat pill for supporting statistics
struct StatPillView: View {
    let value: String
    let label: String
    let icon: String
    var iconColor: Color = MPColors.accent

    var body: some View {
        VStack(spacing: MPSpacing.sm) {
            // Icon with background circle for better visibility
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(MPColors.textPrimary)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(MPColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MPSpacing.lg)
        .padding(.horizontal, MPSpacing.sm)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
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
