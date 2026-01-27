import SwiftUI

/// Premium celebration animation shown when the last AI-verified habit unlocks apps.
/// Designed to be Instagram-worthy - the shareable moment of the app.
struct AppsUnlockedCelebrationView: View {
    @Binding var isShowing: Bool
    let onComplete: () -> Void

    @State private var lockScale: CGFloat = 1.0
    @State private var lockRotation: Double = 0
    @State private var lockOpacity: Double = 1.0
    @State private var showUnlock = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showConfetti = false
    @State private var showAppIcons = false
    @State private var appIconOffsets: [CGSize] = []
    @State private var appIconScales: [CGFloat] = []
    @State private var shimmerPhase: CGFloat = 0

    // Simulated app icons for the animation
    private let appIconNames = ["safari", "message.fill", "mail.fill", "phone.fill", "music.note", "video.fill"]

    var body: some View {
        ZStack {
            // Background with gradient
            LinearGradient(
                colors: [
                    MPColors.background,
                    MPColors.primary.opacity(0.1),
                    MPColors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Main animation area
                ZStack {
                    // App icons flying in from corners
                    if showAppIcons {
                        ForEach(Array(appIconNames.enumerated()), id: \.offset) { index, iconName in
                            Image(systemName: iconName)
                                .font(.system(size: 40))
                                .foregroundColor(MPColors.primary)
                                .frame(width: 60, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(MPColors.surface)
                                        .shadow(color: MPColors.primary.opacity(0.3), radius: 10)
                                )
                                .offset(appIconOffsets[safe: index] ?? .zero)
                                .scaleEffect(appIconScales[safe: index] ?? 0)
                                .opacity(appIconScales[safe: index] ?? 0)
                        }
                    }

                    // Lock → Unlock animation
                    ZStack {
                        // Glow background
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        MPColors.success.opacity(showUnlock ? 0.4 : 0.2),
                                        MPColors.success.opacity(0)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                            .scaleEffect(showUnlock ? 1.5 : 1.0)

                        // Lock icon
                        if !showUnlock {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 80, weight: .medium))
                                .foregroundColor(MPColors.textTertiary)
                                .scaleEffect(lockScale)
                                .rotationEffect(.degrees(lockRotation))
                                .opacity(lockOpacity)
                        }

                        // Unlocked icon
                        if showUnlock {
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 80, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [MPColors.success, MPColors.success.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    // Shimmer effect
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0),
                                                    Color.white.opacity(0.6),
                                                    Color.white.opacity(0)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: 50)
                                        .offset(x: shimmerPhase)
                                        .mask(
                                            Image(systemName: "lock.open.fill")
                                                .font(.system(size: 80, weight: .medium))
                                        )
                                )
                                .scaleEffect(1.0)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .frame(height: 250)

                Spacer().frame(height: MPSpacing.xxl)

                // Title
                Text("Apps Unlocked!")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MPColors.success, MPColors.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(showTitle ? 1.0 : 0.8)
                    .opacity(showTitle ? 1.0 : 0)

                Spacer().frame(height: MPSpacing.md)

                // Subtitle
                Text("Morning routine complete")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(MPColors.textSecondary)
                    .opacity(showSubtitle ? 1.0 : 0)
                    .offset(y: showSubtitle ? 0 : 10)

                Spacer()
            }

            // Full-screen confetti
            if showConfetti {
                MiniConfettiView(
                    particleCount: 60,
                    colors: [MPColors.success, MPColors.primary, MPColors.accent, MPColors.accentGold]
                )
                .allowsHitTesting(false)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Initialize app icon positions (start from corners/edges)
        appIconOffsets = [
            CGSize(width: -150, height: -200),  // Top left
            CGSize(width: 150, height: -200),   // Top right
            CGSize(width: -180, height: 0),     // Left
            CGSize(width: 180, height: 0),      // Right
            CGSize(width: -150, height: 200),   // Bottom left
            CGSize(width: 150, height: 200)     // Bottom right
        ]
        appIconScales = Array(repeating: 0, count: appIconNames.count)

        // Step 1: Lock shakes (0.0s)
        withAnimation(.spring(response: 0.15, dampingFraction: 0.3).repeatCount(3)) {
            lockRotation = 15
        }

        // Lock returns to center
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                lockRotation = 0
            }
        }

        // Step 2: Lock shrinks and fades (0.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            HapticManager.shared.lightTap()
            withAnimation(.easeIn(duration: 0.2)) {
                lockScale = 0.3
                lockOpacity = 0
            }
        }

        // Step 3: Unlock appears with bounce (0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            HapticManager.shared.success()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showUnlock = true
            }
        }

        // Step 4: Shimmer across unlock (1.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.linear(duration: 0.6)) {
                shimmerPhase = 200
            }
        }

        // Step 5: App icons fly in (1.1s, staggered)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            showAppIcons = true
            for i in 0..<appIconNames.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                    HapticManager.shared.light()
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                        appIconOffsets[i] = getCircularPosition(index: i, total: appIconNames.count, radius: 140)
                        appIconScales[i] = 1.0
                    }
                }
            }
        }

        // Step 6: Title appears (1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showTitle = true
            }
        }

        // Step 7: Subtitle appears (1.7s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSubtitle = true
            }
        }

        // Step 8: Confetti burst (1.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            showConfetti = true
            HapticManager.shared.habitCompleted()
        }

        // Step 9: Fade out and dismiss (3.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                isShowing = false
            }
        }

        // Step 10: Call completion (4.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            onComplete()
        }
    }

    /// Positions app icons in a circle around the unlock icon
    private func getCircularPosition(index: Int, total: Int, radius: CGFloat) -> CGSize {
        let angle = (2 * .pi / Double(total)) * Double(index) - .pi / 2 // Start from top
        let x = cos(angle) * Double(radius)
        let y = sin(angle) * Double(radius)
        return CGSize(width: x, height: y)
    }
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    AppsUnlockedCelebrationView(isShowing: .constant(true), onComplete: {})
}
