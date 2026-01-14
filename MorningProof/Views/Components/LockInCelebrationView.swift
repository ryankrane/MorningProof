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
    @State private var flameRotation: Double = 0
    @State private var flameGlowOpacity: Double = 0.5

    // Trail particles
    @State private var trailParticles: [TrailParticle] = []

    // Impact effects
    @State private var shockwaveScale: CGFloat = 0.5
    @State private var shockwaveOpacity: Double = 0
    @State private var impactBurstScale: CGFloat = 0.3
    @State private var impactBurstOpacity: Double = 0

    private let flameSize: CGFloat = 48  // Increased from 32
    private let buttonWidth: CGFloat = 220
    private let buttonHeight: CGFloat = 56

    enum CelebrationPhase {
        case initial
        case lockClick
        case flameEmerge
        case flying
        case impact
        case complete
    }

    struct TrailParticle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var scale: CGFloat
        var opacity: Double
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
            // Semi-transparent background
            Color.black.opacity(0.15)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Trail particles
            ForEach(trailParticles) { particle in
                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(flameGradient.opacity(0.7))
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .position(particle.position)
            }

            // Lock icon (at button position)
            if showLock {
                Image(systemName: "lock.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(MPColors.accentGold)
                    .scaleEffect(lockScale)
                    .rotationEffect(.degrees(lockRotation))
                    .shadow(color: MPColors.accentGold.opacity(lockGlowOpacity), radius: 20)
                    .position(buttonCenter)
            }

            // Flying flame
            if flameOpacity > 0 {
                ZStack {
                    // Intense glow behind flame
                    Circle()
                        .fill(MPColors.accent.opacity(flameGlowOpacity * 0.6))
                        .frame(width: 80, height: 80)
                        .blur(radius: 25)

                    // Main flame icon
                    Image(systemName: "flame.fill")
                        .font(.system(size: flameSize, weight: .bold))
                        .foregroundStyle(flameGradient)
                        .shadow(color: MPColors.accent, radius: 15)
                        .shadow(color: MPColors.error.opacity(0.8), radius: 8)
                }
                .scaleEffect(flameScale)
                .rotationEffect(.degrees(flameRotation))
                .opacity(flameOpacity)
                .position(flamePosition)
            }

            // Impact effects at destination
            if phase == .impact {
                // Shockwave ring
                Circle()
                    .stroke(MPColors.accentGold, lineWidth: 4)
                    .frame(width: 100, height: 100)
                    .scaleEffect(shockwaveScale)
                    .opacity(shockwaveOpacity)
                    .position(streakFlamePosition)

                // Inner impact burst
                Circle()
                    .fill(MPColors.accent.opacity(impactBurstOpacity))
                    .frame(width: 60, height: 60)
                    .scaleEffect(impactBurstScale)
                    .blur(radius: 10)
                    .position(streakFlamePosition)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    // Button center calculation for capsule shape
    private var buttonCenter: CGPoint {
        CGPoint(
            x: buttonPosition.x + buttonWidth / 2,
            y: buttonPosition.y + buttonHeight / 2
        )
    }

    private func startAnimation() {
        // Initialize flame position at button center
        flamePosition = buttonCenter

        // Phase 1: Lock clicks (0.0-0.15s)
        phase = .lockClick
        HapticManager.shared.rigid()

        withAnimation(.spring(response: 0.12, dampingFraction: 0.5)) {
            lockRotation = -20
            lockScale = 1.15
            lockGlowOpacity = 1.0
        }

        // Phase 2: Flame emerges powerfully (0.15-0.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            phase = .flameEmerge
            HapticManager.shared.medium()

            // Flame bursts out
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                flameScale = 1.3
                flameOpacity = 1.0
                flameGlowOpacity = 1.0
            }

            // Fade out lock
            withAnimation(.easeOut(duration: 0.2)) {
                lockGlowOpacity = 0
                lockScale = 0.8
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showLock = false
            }
        }

        // Phase 3: Dramatic flight (0.4s - start flight)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            phase = .flying
            startDramaticFlight()
        }
    }

    private func startDramaticFlight() {
        let startPos = flamePosition
        let endPos = streakFlamePosition
        let flightDuration: Double = 0.35

        // Calculate direction for rotation
        let angle = atan2(endPos.y - startPos.y, endPos.x - startPos.x) * 180 / .pi

        // Rotate flame to point toward destination
        withAnimation(.easeOut(duration: 0.08)) {
            flameRotation = angle - 90  // Adjust so flame tip points forward
        }

        // Start trail particle spawning
        startTrailEffect(from: startPos, to: endPos, duration: flightDuration)

        // Accelerating flight - fast and direct
        withAnimation(.timingCurve(0.4, 0, 1, 1, duration: flightDuration)) {
            flamePosition = endPos
            flameScale = 0.9  // Compress as it speeds up
        }

        // Intensify glow during flight
        withAnimation(.easeIn(duration: flightDuration * 0.7)) {
            flameGlowOpacity = 1.2
        }

        // Impact!
        DispatchQueue.main.asyncAfter(deadline: .now() + flightDuration) {
            triggerImpact()
        }
    }

    private func startTrailEffect(from start: CGPoint, to end: CGPoint, duration: Double) {
        let particleCount = 6
        let interval = duration / Double(particleCount)

        for i in 0..<particleCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * interval) {
                let progress = Double(i) / Double(particleCount)
                let particlePos = CGPoint(
                    x: start.x + (end.x - start.x) * progress,
                    y: start.y + (end.y - start.y) * progress
                )

                let particle = TrailParticle(
                    position: particlePos,
                    scale: 0.7 - CGFloat(progress) * 0.3,
                    opacity: 0.8
                )

                trailParticles.append(particle)

                // Fade out particle
                let particleId = particle.id
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        if let index = trailParticles.firstIndex(where: { $0.id == particleId }) {
                            trailParticles[index].opacity = 0
                            trailParticles[index].scale = 0.2
                        }
                    }
                }

                // Remove particle after fade
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    trailParticles.removeAll { $0.id == particleId }
                }
            }
        }
    }

    private func triggerImpact() {
        phase = .impact

        // SLAM! Compress then explode
        withAnimation(.spring(response: 0.06, dampingFraction: 0.3)) {
            flameScale = 0.5  // Compress on impact
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.35)) {
                flameScale = 1.8  // Explosive expansion
            }
        }

        // Then settle with strong spring
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                flameScale = 1.2
                flameRotation = 0
            }
        }

        // Shockwave burst
        shockwaveScale = 0.5
        shockwaveOpacity = 1.0
        withAnimation(.easeOut(duration: 0.35)) {
            shockwaveScale = 2.5
            shockwaveOpacity = 0
        }

        // Inner impact flash
        impactBurstScale = 0.3
        impactBurstOpacity = 0.9
        withAnimation(.easeOut(duration: 0.25)) {
            impactBurstScale = 2.0
            impactBurstOpacity = 0
        }

        // STRONG haptic sequence - the "slam"
        HapticManager.shared.heavyTap()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            HapticManager.shared.rigid()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            HapticManager.shared.success()
        }

        // Callback to trigger StreakHeroCard pulse
        onFlameArrived()

        // Final settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                flameScale = 1.0
            }
        }

        // Fade out (merges with existing flame)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeOut(duration: 0.2)) {
                flameOpacity = 0
            }
        }

        // Complete and dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            phase = .complete
            withAnimation(.easeOut(duration: 0.15)) {
                isShowing = false
            }
        }
    }
}

#Preview {
    ZStack {
        MPColors.background.ignoresSafeArea()

        LockInCelebrationView(
            isShowing: .constant(true),
            buttonPosition: CGPoint(x: 85, y: 600),
            streakFlamePosition: CGPoint(x: 60, y: 200),
            onFlameArrived: {}
        )
    }
}
