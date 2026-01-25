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
                // Hero icon (simple, no glow)
                Image(systemName: "megaphone.fill")
                    .font(.system(size: 60))
                    .foregroundColor(MPColors.primary)
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
                        .foregroundColor(source.iconColor)
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

// MARK: - Preview

#Preview {
    ZStack {
        MPColors.background.ignoresSafeArea()
        AttributionStep(data: OnboardingData(), onContinue: {})
    }
    .preferredColorScheme(.dark)
}
