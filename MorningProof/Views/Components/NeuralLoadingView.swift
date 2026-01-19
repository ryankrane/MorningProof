import SwiftUI

// MARK: - Linear Progress Loading View

/// Clean, minimal loading animation featuring a horizontal progress bar with percentage.
/// Used for the "Building Your Plan" onboarding step.
struct NeuralLoadingView: View {
    let progress: Double           // 0.0 to 1.0
    let isProcessing: Bool         // Controls animation on/off
    @Binding var burstTarget: CGPoint?  // Kept for API compatibility
    var onBurstComplete: (() -> Void)?  // Optional callback

    @State private var lastProgressScale: CGFloat = 1.0
    @State private var displayedProgress: Int = 0
    @State private var shimmerOffset: CGFloat = -1

    private let barHeight: CGFloat = 8
    private let barCornerRadius: CGFloat = 4

    var body: some View {
        GeometryReader { geometry in
            let barWidth = min(geometry.size.width * 0.85, 280)

            VStack(spacing: 20) {
                Spacer()

                // Percentage text
                Text("\(displayedProgress)%")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.primary)
                    .scaleEffect(lastProgressScale)
                    .contentTransition(.numericText())

                // Progress bar
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: barCornerRadius)
                        .fill(MPColors.primary.opacity(0.15))
                        .frame(width: barWidth, height: barHeight)

                    // Filled portion
                    RoundedRectangle(cornerRadius: barCornerRadius)
                        .fill(MPColors.primary)
                        .frame(width: max(barHeight, barWidth * CGFloat(progress)), height: barHeight)

                    // Shimmer effect
                    if isProcessing && progress > 0.05 && progress < 1.0 {
                        RoundedRectangle(cornerRadius: barCornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0),
                                        .white.opacity(0.4),
                                        .white.opacity(0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 40, height: barHeight)
                            .offset(x: shimmerOffset * barWidth * CGFloat(progress))
                            .mask(
                                RoundedRectangle(cornerRadius: barCornerRadius)
                                    .frame(width: max(barHeight, barWidth * CGFloat(progress)), height: barHeight)
                                    .frame(width: barWidth, alignment: .leading)
                            )
                    }
                }
                .frame(width: barWidth)

                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .allowsHitTesting(false)
        .onAppear {
            startShimmer()
        }
        .onChange(of: burstTarget) { _, newTarget in
            if newTarget != nil {
                HapticManager.shared.habitBurst()
                DispatchQueue.main.async {
                    burstTarget = nil
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onBurstComplete?()
                }
            }
        }
        .onChange(of: progress) { _, newProgress in
            let newDisplayed = Int(newProgress * 100)
            if newDisplayed != displayedProgress {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    lastProgressScale = 1.08
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) {
                    lastProgressScale = 1.0
                }
                displayedProgress = newDisplayed
            }
        }
    }

    private func startShimmer() {
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            shimmerOffset = 1
        }
    }
}

// MARK: - Preview

struct NeuralLoadingViewPreview: View {
    @State private var burstTarget: CGPoint? = nil
    @State private var progress: Double = 0.65

    var body: some View {
        ZStack {
            MPColors.background.ignoresSafeArea()

            VStack(spacing: 40) {
                NeuralLoadingView(
                    progress: progress,
                    isProcessing: true,
                    burstTarget: $burstTarget
                )
                .frame(width: 300, height: 200)

                HStack(spacing: 20) {
                    Button("0%") { progress = 0 }
                    Button("+10%") { progress = min(1.0, progress + 0.1) }
                    Button("100%") { progress = 1.0 }
                }
                .foregroundColor(MPColors.primary)
            }
        }
    }
}

#Preview {
    NeuralLoadingViewPreview()
}
