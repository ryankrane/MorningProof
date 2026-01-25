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

// MARK: - Megaphone Icon (Image with Animated Sound Waves)

private struct MegaphoneIcon: View {
    let size: CGFloat

    // Animation state for pulsing sound waves
    @State private var soundWavePhase: CGFloat = 0

    private let soundWaveBlue = Color(red: 0.4, green: 0.75, blue: 1.0)

    var body: some View {
        HStack(spacing: -size * 0.05) {
            // Megaphone image from assets
            Image("MegaphoneIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)

            // Animated sound waves
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    SoundWaveArc()
                        .stroke(
                            soundWaveBlue,
                            style: StrokeStyle(lineWidth: size * 0.04, lineCap: .round)
                        )
                        .frame(
                            width: size * (0.12 + CGFloat(index) * 0.1),
                            height: size * (0.26 + CGFloat(index) * 0.13)
                        )
                        .offset(x: CGFloat(index) * size * 0.08, y: 0)
                        .opacity(waveOpacity(for: index))
                        .scaleEffect(waveScale(for: index))
                }
            }
            .frame(width: size * 0.4)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: false)
            ) {
                soundWavePhase = 1.0
            }
        }
    }

    private func waveOpacity(for index: Int) -> Double {
        let offset = Double(index) * 0.33
        let adjustedPhase = (soundWavePhase + offset).truncatingRemainder(dividingBy: 1.0)
        return 1.0 - adjustedPhase * 0.7
    }

    private func waveScale(for index: Int) -> CGFloat {
        let offset = Double(index) * 0.33
        let adjustedPhase = (soundWavePhase + offset).truncatingRemainder(dividingBy: 1.0)
        return 1.0 + CGFloat(adjustedPhase) * 0.15
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
