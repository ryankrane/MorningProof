import SwiftUI

struct LockInCelebrationView: View {
    @Binding var isShowing: Bool
    let buttonPosition: CGPoint       // Where the lock button is (global coordinates)
    let streakFlamePosition: CGPoint  // Where the streak flame icon is (global coordinates)
    let onFlameArrived: () -> Void    // Callback when flame reaches destination

    // Animation phases
    @State private var phase: CelebrationPhase = .initial

    // Lock animation states
    @State private var lockScale: CGFloat = 1.0
    @State private var lockRotation: Double = 0
    @State private var lockGlowOpacity: Double = 0
    @State private var showLock: Bool = true

    // Flame animation states
    @State private var flameScale: CGFloat = 0
    @State private var flameOpacity: Double = 0
    @State private var flamePosition: CGPoint = .zero
    @State private var flamePulseScale: CGFloat = 1.0
    @State private var flameGlowOpacity: Double = 0.5

    // Bounce tracking
    @State private var bounceCount: Int = 0

    private let totalDuration: Double = 2.5

    enum CelebrationPhase {
        case initial
        case lockClick
        case flameEmerge
        case bouncing
        case flying
        case arrived
        case complete
    }

    // Flame gradient matching StreakHeroCard
    private var flameGradient: LinearGradient {
        LinearGradient(
            colors: [MPColors.accent, MPColors.error],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    var body: some View {
        ZStack {
            // Semi-transparent background (subtle)
            Color.black.opacity(0.1)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Lock icon (at button position, fades after flame emerges)
            if showLock {
                Image(systemName: "lock.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(MPColors.accentGold)
                    .scaleEffect(lockScale)
                    .rotationEffect(.degrees(lockRotation))
                    .shadow(color: MPColors.accentGold.opacity(lockGlowOpacity), radius: 20)
                    .position(
                        x: buttonPosition.x + 40,  // Center of button
                        y: buttonPosition.y + 40
                    )
            }

            // Flying flame
            if flameOpacity > 0 {
                ZStack {
                    // Glow behind flame
                    Circle()
                        .fill(MPColors.accent.opacity(flameGlowOpacity * 0.5))
                        .frame(width: 60, height: 60)
                        .blur(radius: 15)

                    // Flame icon
                    Image(systemName: "flame.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(flameGradient)
                        .shadow(color: MPColors.accent.opacity(flameGlowOpacity), radius: 12)
                }
                .scaleEffect(flameScale * flamePulseScale)
                .opacity(flameOpacity)
                .position(flamePosition)
            }

            // Glow burst at arrival
            if phase == .arrived {
                Circle()
                    .stroke(MPColors.accentGold, lineWidth: 3)
                    .frame(width: 80, height: 80)
                    .scaleEffect(lockScale)
                    .opacity(lockGlowOpacity)
                    .position(streakFlamePosition)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Initialize flame position at button
        flamePosition = CGPoint(
            x: buttonPosition.x + 40,
            y: buttonPosition.y + 40
        )

        // Phase 1: Lock clicks (0.0-0.2s)
        phase = .lockClick
        HapticManager.shared.rigid()

        withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
            lockRotation = -15
            lockScale = 1.1
            lockGlowOpacity = 0.8
        }

        // Phase 2: Flame emerges (0.2-0.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            phase = .flameEmerge
            HapticManager.shared.medium()

            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                flameScale = 1.0
                flameOpacity = 1.0
            }

            // Start flame pulsing
            startFlamePulse()

            // Fade out lock
            withAnimation(.easeOut(duration: 0.3)) {
                lockGlowOpacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showLock = false
            }
        }

        // Phase 3: Start bouncing (0.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            phase = .bouncing
            performBounces()
        }
    }

    private func startFlamePulse() {
        // Continuous pulse while flying
        withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
            flamePulseScale = 1.15
            flameGlowOpacity = 0.8
        }
    }

    private func performBounces() {
        // Calculate bounce waypoints
        let startX = buttonPosition.x + 40
        let startY = buttonPosition.y + 40
        let endX = streakFlamePosition.x
        let endY = streakFlamePosition.y

        let horizontalDistance = endX - startX
        let verticalDistance = endY - startY

        // 3 bounces, each getting smaller and moving closer to target
        let bounces: [(CGPoint, CGFloat, Double)] = [
            // (position, height of bounce apex, duration)
            (CGPoint(x: startX + horizontalDistance * 0.25, y: startY + verticalDistance * 0.1), -80, 0.35),
            (CGPoint(x: startX + horizontalDistance * 0.55, y: startY + verticalDistance * 0.4), -50, 0.30),
            (CGPoint(x: startX + horizontalDistance * 0.8, y: startY + verticalDistance * 0.7), -30, 0.25),
        ]

        var delay: Double = 0

        for (_, bounce) in bounces.enumerated() {
            let (targetPos, bounceHeight, duration) = bounce

            // Bounce up
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // Apex of bounce
                let apexPos = CGPoint(x: targetPos.x, y: targetPos.y + bounceHeight)

                withAnimation(.easeOut(duration: duration * 0.5)) {
                    flamePosition = apexPos
                    flameScale = 1.1  // Expand slightly going up
                }
            }

            // Bounce down with compression
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + duration * 0.5) {
                withAnimation(.easeIn(duration: duration * 0.4)) {
                    flamePosition = targetPos
                }

                // Compress on impact
                DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.35) {
                    HapticManager.shared.light()  // Impact haptic

                    withAnimation(.spring(response: 0.1, dampingFraction: 0.4)) {
                        flameScale = 0.85  // Squish
                    }

                    // Spring back
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                        withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                            flameScale = 1.0
                        }
                    }
                }
            }

            delay += duration
        }

        // Final flight to target (after all bounces)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            phase = .flying
            finalFlight()
        }
    }

    private func finalFlight() {
        // Accelerate toward streak flame
        withAnimation(.easeIn(duration: 0.25)) {
            flamePosition = streakFlamePosition
            flameScale = 0.9  // Slightly smaller as it zooms in
        }

        // Arrival
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            phase = .arrived

            // Stop pulsing and trigger arrival effects
            withAnimation(.spring(response: 0.1, dampingFraction: 0.5)) {
                flamePulseScale = 1.0
                flameScale = 1.4  // Big pulse
                flameGlowOpacity = 1.0
            }

            // Arrival burst
            lockScale = 0.5
            lockGlowOpacity = 0.8
            withAnimation(.easeOut(duration: 0.4)) {
                lockScale = 2.0
                lockGlowOpacity = 0
            }

            // Strong haptic
            HapticManager.shared.success()

            // Callback to trigger StreakHeroCard pulse
            onFlameArrived()

            // Fade out flame (it "merges" with the existing flame)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.3)) {
                    flameOpacity = 0
                    flameScale = 1.0
                }
            }

            // Complete and dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                phase = .complete
                withAnimation(.easeOut(duration: 0.2)) {
                    isShowing = false
                }
            }
        }
    }
}

#Preview {
    ZStack {
        MPColors.background.ignoresSafeArea()

        LockInCelebrationView(
            isShowing: .constant(true),
            buttonPosition: CGPoint(x: 150, y: 600),
            streakFlamePosition: CGPoint(x: 60, y: 200),
            onFlameArrived: {}
        )
    }
}
