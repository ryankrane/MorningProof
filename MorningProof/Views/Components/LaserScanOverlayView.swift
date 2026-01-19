import SwiftUI

/// A premium "Cyber-Audit" scanning animation overlay
/// Features: holographic card, laser scan line, minimal progress bar, haptic feedback
struct LaserScanOverlayView: View {
    let image: UIImage
    let accentColor: Color
    let statusText: String

    @State private var scanProgress: CGFloat = 0
    @State private var progressValue: CGFloat = 0

    // Timer references
    @State private var progressTimer: Timer?
    @State private var hapticTimer: Timer?
    @State private var progressStartTime: Date?

    private let scanDuration: Double = 2.5

    var body: some View {
        VStack(spacing: MPSpacing.xl) {
            Spacer()

            // Photo with scanning overlay
            ZStack {
                // The captured photo with holographic effect
                HolographicCardView(image: image, isAnimating: true)
                    .frame(maxHeight: 450)

                // Scanning overlay (laser line + highlight only)
                GeometryReader { geometry in
                    ZStack {
                        // Laser scan line
                        laserLine(in: geometry.size)

                        // Scan region highlight
                        scanHighlight(in: geometry.size)
                    }
                }
                .frame(maxHeight: 450)
                .aspectRatio(image.size, contentMode: .fit)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, MPSpacing.lg)

            // Status section - minimal
            VStack(spacing: MPSpacing.md) {
                // Horizontal progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Track
                        Capsule()
                            .fill(MPColors.progressBg)
                            .frame(height: 4)

                        // Progress with glow
                        Capsule()
                            .fill(accentColor)
                            .frame(width: geo.size.width * progressValue, height: 4)
                            .shadow(color: accentColor.opacity(0.8), radius: 6)
                            .shadow(color: accentColor.opacity(0.4), radius: 12)
                    }
                }
                .frame(height: 4)
                .frame(maxWidth: 260)

                // Percentage + subtitle
                VStack(spacing: MPSpacing.xs) {
                    Text("\(Int(progressValue * 100))%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)

                    Text(statusText)
                        .font(MPFont.bodyMedium())
                        .foregroundColor(MPColors.textTertiary)
                }
            }

            Spacer()
        }
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            stopAnimations()
        }
    }

    // MARK: - Laser Line

    @ViewBuilder
    private func laserLine(in size: CGSize) -> some View {
        let lineY = size.height * scanProgress

        ZStack {
            // Main laser line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0),
                            accentColor,
                            accentColor,
                            accentColor.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size.width, height: 2)

            // Glow effect
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0),
                            accentColor.opacity(0.6),
                            accentColor.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size.width, height: 30)
                .blur(radius: 10)
        }
        .position(x: size.width / 2, y: lineY)
    }

    // MARK: - Scan Highlight

    @ViewBuilder
    private func scanHighlight(in size: CGSize) -> some View {
        let highlightHeight: CGFloat = 60
        let lineY = size.height * scanProgress

        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        accentColor.opacity(0),
                        accentColor.opacity(0.15),
                        accentColor.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size.width, height: highlightHeight)
            .position(x: size.width / 2, y: lineY)
    }

    // MARK: - Animations

    private func startAnimations() {
        // Scan animation
        animateScan()

        // Haptic feedback loop - rhythmic thumping
        startHapticLoop()

        // Progress animation
        progressStartTime = Date()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let startTime = progressStartTime else { return }

            let elapsed = Date().timeIntervalSince(startTime)

            let newProgress: CGFloat
            if elapsed < 2 {
                newProgress = CGFloat(elapsed / 2) * 0.40
            } else if elapsed < 5 {
                newProgress = 0.40 + CGFloat((elapsed - 2) / 3) * 0.25
            } else if elapsed < 15 {
                newProgress = 0.65 + CGFloat((elapsed - 5) / 10) * 0.20
            } else {
                let extraTime = elapsed - 15
                newProgress = 0.85 + CGFloat(min(extraTime / 30, 1.0)) * 0.07
            }

            withAnimation(.linear(duration: 0.1)) {
                progressValue = min(newProgress, 0.92)
            }
        }
    }

    private func animateScan() {
        scanProgress = 0

        withAnimation(.easeInOut(duration: 1.5)) {
            scanProgress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 1.0)) {
                scanProgress = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + scanDuration) {
            animateScan()
        }
    }

    private func startHapticLoop() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()

        hapticTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
            generator.impactOccurred(intensity: 0.4)
            generator.prepare()
        }
    }

    private func stopAnimations() {
        progressTimer?.invalidate()
        progressTimer = nil
        hapticTimer?.invalidate()
        hapticTimer = nil
        progressStartTime = nil
    }
}

#Preview {
    ZStack {
        MPColors.background
            .ignoresSafeArea()

        LaserScanOverlayView(
            image: UIImage(systemName: "bed.double.fill")!,
            accentColor: MPColors.accent,
            statusText: "AI is checking if it's made"
        )
    }
}
