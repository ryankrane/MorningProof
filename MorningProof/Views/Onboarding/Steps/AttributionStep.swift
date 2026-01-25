import SwiftUI

// MARK: - Step 4: Attribution (Where did you hear about us?)

struct AttributionStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var selectedAnimating: OnboardingData.AttributionSource? = nil

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: MPSpacing.md) {
                // Hero icon - colorful megaphone
                MegaphoneIcon(size: 60)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.5)

                Text("Where did you hear\nabout us?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("This helps us reach more people like you")
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer().frame(height: MPSpacing.xxl)

            // 2-column grid of attribution options
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MPSpacing.md) {
                ForEach(Array(OnboardingData.AttributionSource.allCases.enumerated()), id: \.element.rawValue) { index, source in
                    AttributionOptionButton(
                        source: source,
                        isSelected: data.attributionSource == source
                    ) {
                        // Single selection with bounce animation
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            data.attributionSource = source
                            selectedAnimating = source
                        }

                        // Remove from animating after animation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedAnimating = nil
                        }
                    }
                    .scaleEffect(selectedAnimating == source ? 1.05 : 1.0)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.08),
                        value: appeared
                    )
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer()

            // Continue button and Skip option
            VStack(spacing: MPSpacing.md) {
                MPButton(
                    title: "Continue",
                    style: .primary,
                    isDisabled: data.attributionSource == nil
                ) {
                    onContinue()
                }

                Button {
                    // Skip without selecting
                    onContinue()
                } label: {
                    Text("Skip")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(MPColors.textTertiary)
                }
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

// MARK: - Attribution Option Button

private struct AttributionOptionButton: View {
    let source: OnboardingData.AttributionSource
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            action()
        }) {
            VStack(spacing: MPSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(MPColors.surfaceSecondary)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? MPColors.primary : Color.clear, lineWidth: 2)
                        )

                    Image(systemName: source.icon)
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? MPColors.primary : MPColors.textTertiary)
                }

                Text(source.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 95)
            .padding(.vertical, MPSpacing.md)
            .padding(.horizontal, MPSpacing.sm)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: MPRadius.lg)
                    .stroke(isSelected ? MPColors.primary : Color.clear, lineWidth: 2)
            )
            .mpShadow(.small)
        }
    }
}

// MARK: - Megaphone Icon (Simple Clipart Style)

private struct MegaphoneIcon: View {
    let size: CGFloat

    // Clean, bright colors matching original
    private let coneYellow = Color(red: 1.0, green: 0.82, blue: 0.25)
    private let coneOrange = Color(red: 1.0, green: 0.6, blue: 0.15)
    private let soundWaveBlue = Color(red: 0.4, green: 0.75, blue: 1.0)

    var body: some View {
        ZStack {
            // Simple megaphone cone shape
            MegaphoneConeShape()
                .fill(
                    LinearGradient(
                        colors: [coneYellow, coneOrange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.65, height: size * 0.6)

            // Subtle highlight on cone
            MegaphoneConeShape()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.4), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .frame(width: size * 0.65, height: size * 0.6)

            // Sound waves
            ForEach(0..<3) { index in
                SoundWaveArc()
                    .stroke(
                        soundWaveBlue.opacity(1.0 - Double(index) * 0.25),
                        style: StrokeStyle(lineWidth: size * 0.045, lineCap: .round)
                    )
                    .frame(width: size * (0.18 + CGFloat(index) * 0.13),
                           height: size * (0.28 + CGFloat(index) * 0.18))
                    .offset(x: size * 0.38 + CGFloat(index) * size * 0.08, y: 0)
            }
        }
        .frame(width: size * 1.2, height: size)
    }
}

// MARK: - Megaphone Cone Shape

private struct MegaphoneConeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Simple flared cone - narrow on left, wide on right
        let mouthRadius = rect.height * 0.5
        let backRadius = rect.height * 0.18

        // Back of megaphone (left side, small circle)
        let backX = rect.width * 0.08
        let centerY = rect.midY

        // Front/mouth of megaphone (right side, large circle)
        let frontX = rect.width * 0.85

        // Draw the cone shape
        // Start at top of back
        path.move(to: CGPoint(x: backX, y: centerY - backRadius))

        // Top edge curving to mouth
        path.addLine(to: CGPoint(x: frontX, y: centerY - mouthRadius))

        // Mouth arc (right side)
        path.addArc(
            center: CGPoint(x: frontX, y: centerY),
            radius: mouthRadius,
            startAngle: .degrees(-90),
            endAngle: .degrees(90),
            clockwise: false
        )

        // Bottom edge back to back
        path.addLine(to: CGPoint(x: backX, y: centerY + backRadius))

        // Back arc (left side)
        path.addArc(
            center: CGPoint(x: backX, y: centerY),
            radius: backRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(-90),
            clockwise: false
        )

        return path
    }
}

// MARK: - Sound Wave Arc

private struct SoundWaveArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.addArc(
            center: CGPoint(x: 0, y: rect.midY),
            radius: rect.height / 2,
            startAngle: .degrees(-45),
            endAngle: .degrees(45),
            clockwise: false
        )

        return path
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        MPColors.background.ignoresSafeArea()
        AttributionStep(data: OnboardingData(), onContinue: {})
    }
    .preferredColorScheme(.dark)
}
