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

// MARK: - Megaphone Icon

private struct MegaphoneIcon: View {
    let size: CGFloat

    // Bright, friendly colors
    private let megaphoneYellow = Color(red: 1.0, green: 0.8, blue: 0.2)
    private let megaphoneOrange = Color(red: 1.0, green: 0.55, blue: 0.1)
    private let handleColor = Color(red: 0.35, green: 0.35, blue: 0.4)
    private let soundWaveColor = Color(red: 0.4, green: 0.75, blue: 1.0)

    var body: some View {
        ZStack {
            // Megaphone body (cone shape using a trapezoid path)
            Path { path in
                let scale = size / 60.0

                // Cone shape - wide on right (bell), narrow on left (handle)
                path.move(to: CGPoint(x: 12 * scale, y: 22 * scale))
                path.addLine(to: CGPoint(x: 42 * scale, y: 10 * scale))
                path.addLine(to: CGPoint(x: 42 * scale, y: 50 * scale))
                path.addLine(to: CGPoint(x: 12 * scale, y: 38 * scale))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [megaphoneYellow, megaphoneOrange],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Handle grip
            RoundedRectangle(cornerRadius: size * 0.05)
                .fill(handleColor)
                .frame(width: size * 0.12, height: size * 0.35)
                .offset(x: -size * 0.32, y: 0)

            // Sound waves (three arcs)
            ForEach(0..<3) { index in
                SoundWaveArc(size: size, index: index)
                    .stroke(
                        soundWaveColor.opacity(1.0 - Double(index) * 0.25),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .offset(x: size * 0.12, y: 0)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Sound Wave Arc

private struct SoundWaveArc: Shape {
    let size: CGFloat
    let index: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let scale = size / 60.0
        let baseRadius: CGFloat = 12 * scale
        let radiusIncrement: CGFloat = 8 * scale
        let radius = baseRadius + CGFloat(index) * radiusIncrement

        let center = CGPoint(x: rect.midX, y: rect.midY)

        path.addArc(
            center: center,
            radius: radius,
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
