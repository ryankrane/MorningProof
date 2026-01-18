import SwiftUI

struct LockInCelebrationView: View {
    @Binding var isShowing: Bool
    let buttonPosition: CGPoint       // Center of the lock button (global coordinates)
    let streakFlamePosition: CGPoint  // Center of the streak flame icon (global coordinates)
    let previousStreak: Int           // Streak BEFORE lock-in (0 = ignition, 1+ = flare-up)
    let onFlameArrived: () -> Void    // Callback when flame reaches destination
    var onIgnition: (() -> Void)?     // Callback for 0→1 effect (gray→vibrant transition)
    var onShake: ((CGFloat) -> Void)? // Callback for slam shake

    // Animation phases
    @State private var phase: CelebrationPhase = .initial

    // Lock animation states
    @State private var lockScale: CGFloat = 0  // Start at 0 for phoenix spawn
    @State private var lockRotation: Double = 0
    @State private var lockGlowOpacity: Double = 0
    @State private var showLock: Bool = true

    // Phoenix spawn particles
    @State private var spawnParticles: [SpawnParticle] = []
    @State private var showSpawnBurst: Bool = false

    // Flame animation states
    @State private var flameScale: CGFloat = 0
    @State private var flameOpacity: Double = 0
    @State private var flameGlowOpacity: Double = 0.5

    // Anticipation animation states (wind-up)
    @State private var anticipationScale: CGFloat = 1.0
    @State private var anticipationOffset: CGFloat = 0

    // Bezier flight states
    @State private var bezierProgress: CGFloat = 0
    @State private var bezier: QuadraticBezier?
    @State private var flameSpinRotation: Double = 0

    // Impact effects
    @State private var shockwaveScale: CGFloat = 0.5
    @State private var shockwaveOpacity: Double = 0
    @State private var impactBurstScale: CGFloat = 0.3
    @State private var impactBurstOpacity: Double = 0

    /// Flame size scales with streak - matches StreakHeroCard's destination size
    private var flameSize: CGFloat {
        // previousStreak is the streak before this lock-in, so destination is previousStreak + 1
        let destinationStreak = previousStreak + 1
        switch destinationStreak {
        case 1: return 52          // 0→1 ignition
        case 2: return 56          // Day 2
        case 3: return 60          // Day 3
        case 4: return 64          // Day 4
        case 5: return 68          // Day 5
        case 6...13: return 70     // Week territory
        case 14...29: return 74    // Two week+
        default: return 80         // Month+ streaks
        }
    }

    enum CelebrationPhase {
        case initial
        case lockClick
        case windUp
        case flying
        case impact
        case complete
    }

    struct SpawnParticle: Identifiable {
        let id = UUID()
        var offset: CGPoint
        var scale: CGFloat
        var opacity: Double
        var rotation: Double
    }

    // Flame gradient matching StreakHeroCard
    private var flameGradient: LinearGradient {
        MPColors.flameGradient
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent background - slightly darker for drama
                // Uses ignoresSafeArea to ensure full screen coverage
                Color.black.opacity(0.25)
                    .allowsHitTesting(false)

                // Phoenix spawn particles (golden sparks radiating outward)
                if showSpawnBurst {
                    ForEach(spawnParticles) { particle in
                        Image(systemName: "sparkle")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(MPColors.accentGold)
                            .scaleEffect(particle.scale)
                            .opacity(particle.opacity)
                            .rotationEffect(.degrees(particle.rotation))
                            .position(
                                x: buttonPosition.x + particle.offset.x,
                                y: buttonPosition.y + particle.offset.y
                            )
                    }
                }

                // Lock icon (at button position)
                if showLock {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 32, weight: .semibold))  // Larger lock
                        .foregroundStyle(MPColors.accentGold)
                        .scaleEffect(lockScale)
                        .rotationEffect(.degrees(lockRotation))
                        .shadow(color: MPColors.accentGold.opacity(lockGlowOpacity), radius: 25)
                        .shadow(color: MPColors.accentGold.opacity(lockGlowOpacity * 0.5), radius: 40)
                        .position(buttonPosition)
                }

                // Flying flame with Bezier path animation
                if flameOpacity > 0 {
                    ZStack {
                        // Intense glow behind flame - larger and more dramatic
                        Circle()
                            .fill(MPColors.flameOrange.opacity(flameGlowOpacity * 0.5))
                            .frame(width: 120, height: 120)
                            .blur(radius: 35)

                        // Secondary glow layer
                        Circle()
                            .fill(MPColors.flameRed.opacity(flameGlowOpacity * 0.3))
                            .frame(width: 90, height: 90)
                            .blur(radius: 20)

                        // Main flame icon
                        Image(systemName: "flame.fill")
                            .font(.system(size: flameSize, weight: .bold))
                            .foregroundStyle(flameGradient)
                            .shadow(color: MPColors.flameOrange, radius: 20)
                            .shadow(color: MPColors.flameRed.opacity(0.8), radius: 12)
                    }
                    .scaleEffect(flameScale * anticipationScale)
                    .offset(y: anticipationOffset)
                    .rotationEffect(.degrees(flameSpinRotation))
                    .opacity(flameOpacity)
                    .modifier(FlamePositionModifier(
                        bezier: bezier,
                        progress: bezierProgress,
                        fallbackPosition: buttonPosition
                    ))
                }

                // Impact effects at destination
                if phase == .impact {
                    // Shockwave ring - bigger and bolder
                    Circle()
                        .stroke(MPColors.accentGold, lineWidth: 5)
                        .frame(width: 120, height: 120)
                        .scaleEffect(shockwaveScale)
                        .opacity(shockwaveOpacity)
                        .position(streakFlamePosition)

                    // Inner impact burst
                    Circle()
                        .fill(MPColors.accent.opacity(impactBurstOpacity))
                        .frame(width: 80, height: 80)
                        .scaleEffect(impactBurstScale)
                        .blur(radius: 15)
                        .position(streakFlamePosition)
                }
            }
            .onAppear {
                startAnimation(screenWidth: geometry.size.width)
            }
        }
        .ignoresSafeArea()  // Ensures GeometryReader spans full screen for accurate global positioning
    }

    // MARK: - Animation Sequence
    // Total duration: ~2.5 seconds (was ~1 second)

    private func startAnimation(screenWidth: CGFloat) {
        // ═══════════════════════════════════════════════════════════════
        // PHASE 1: Phoenix Spawn (0 - 0.35s)
        // Lock materializes from golden sparks radiating outward
        // ═══════════════════════════════════════════════════════════════
        phase = .lockClick
        HapticManager.shared.rigid()

        // Create spawn particles in radial burst
        createSpawnParticles()
        showSpawnBurst = true

        // Animate particles outward and fade
        animateSpawnParticles()

        // Lock spawns: 0% → 120% (spring overshoot) → 100% (settle)
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
            lockScale = 1.2
            lockGlowOpacity = 1.0
        }

        // Settle to normal scale
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.65)) {
                lockScale = 1.0
            }
        }

        // Rotate with slight delay for layered effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                lockRotation = -25
            }
        }

        // Hold the lock pose for a beat
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            HapticManager.shared.light()
        }

        // Clean up spawn particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showSpawnBurst = false
            spawnParticles.removeAll()
        }

        // ═══════════════════════════════════════════════════════════════
        // PHASE 2: Flame Emerges + Wind-Up (0.3s - 0.9s)
        // Flame appears, does a dramatic squash-and-stretch wind-up
        // ═══════════════════════════════════════════════════════════════
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            phase = .windUp
            HapticManager.shared.medium()

            // Flame bursts into existence
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                flameScale = 1.1
                flameOpacity = 1.0
                flameGlowOpacity = 1.0
            }

            // Fade out lock gracefully
            withAnimation(.easeOut(duration: 0.25)) {
                lockGlowOpacity = 0
                lockScale = 0.7
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                showLock = false
            }
        }

        // Wind-up: SQUASH (crouch before the jump)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            HapticManager.shared.light()
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 12)) {
                anticipationScale = 0.6
                anticipationOffset = 12  // Crouch down
            }
        }

        // Wind-up: HOLD the crouch for tension
        // (The anticipation makes the release more satisfying)

        // Wind-up: STRETCH (the release!)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            HapticManager.shared.medium()
            withAnimation(.interpolatingSpring(stiffness: 250, damping: 10)) {
                anticipationScale = 1.4
                anticipationOffset = -20  // Pop up!
            }
        }

        // ═══════════════════════════════════════════════════════════════
        // PHASE 3: The Flight (0.95s - 1.85s)
        // Dramatic Bezier arc with tumbling rotation and particle trail
        // ═══════════════════════════════════════════════════════════════
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            phase = .flying
            startBezierFlight(screenWidth: screenWidth)
        }
    }

    // MARK: - Phoenix Spawn Helpers

    private func createSpawnParticles() {
        // Create 8 particles in radial pattern
        spawnParticles = (0..<8).map { i in
            SpawnParticle(
                offset: .zero,  // Start at center
                scale: 0.8,
                opacity: 1.0,
                rotation: Double.random(in: 0...360)
            )
        }
    }

    private func animateSpawnParticles() {
        // Animate each particle outward in its radial direction
        for (index, _) in spawnParticles.enumerated() {
            let angle = (Double(index) / 8.0) * 2 * .pi
            let distance: CGFloat = 45  // How far particles travel

            // Calculate target position
            let targetX = cos(angle) * distance
            let targetY = sin(angle) * distance

            // Stagger the animations slightly for organic feel
            let delay = Double(index) * 0.015

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.3)) {
                    if index < spawnParticles.count {
                        spawnParticles[index].offset = CGPoint(x: targetX, y: targetY)
                        spawnParticles[index].scale = 0.3
                        spawnParticles[index].opacity = 0
                        spawnParticles[index].rotation += Double.random(in: 90...180)
                    }
                }
            }
        }
    }

    private func startBezierFlight(screenWidth: CGFloat) {
        let flightDuration: Double = 0.9  // Slower, more dramatic flight

        // Reset anticipation for clean flight
        withAnimation(.easeOut(duration: 0.08)) {
            anticipationScale = 1.0
            anticipationOffset = 0
        }

        // Create Bezier path with more dramatic arc
        let flightBezier = QuadraticBezier.swoopingArc(
            from: buttonPosition,
            to: streakFlamePosition,
            screenWidth: screenWidth
        )
        bezier = flightBezier

        // Tumble rotation during flight (1.5-2.5 full rotations for drama)
        let rotationAmount = Double.random(in: 540...900) * (Bool.random() ? 1 : -1)
        withAnimation(.easeInOut(duration: flightDuration)) {
            flameSpinRotation = rotationAmount
        }

        // Animate along Bezier path - slower ease for more visible arc
        withAnimation(.timingCurve(0.25, 0.1, 0.25, 1.0, duration: flightDuration)) {
            bezierProgress = 1.0
        }

        // Scale gets smaller in middle of flight, bigger approaching target
        withAnimation(.easeInOut(duration: flightDuration * 0.5)) {
            flameScale = 0.75
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + flightDuration * 0.5) {
            withAnimation(.easeIn(duration: flightDuration * 0.5)) {
                flameScale = 1.1
            }
        }

        // Intensify glow as it approaches target
        DispatchQueue.main.asyncAfter(deadline: .now() + flightDuration * 0.4) {
            withAnimation(.easeIn(duration: flightDuration * 0.6)) {
                flameGlowOpacity = 1.5
            }
        }

        // IMPACT!
        DispatchQueue.main.asyncAfter(deadline: .now() + flightDuration) {
            triggerImpact()
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // PHASE 4: Impact (1.85s - 2.5s)
    // The satisfying SLAM with compression, explosion, and settle
    // ═══════════════════════════════════════════════════════════════
    private func triggerImpact() {
        phase = .impact

        // SLAM! Compress on impact
        withAnimation(.spring(response: 0.08, dampingFraction: 0.3)) {
            flameScale = 0.4
            flameSpinRotation = 0  // Lock rotation on impact
        }

        // Explosive expansion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.35)) {
                flameScale = 2.2  // Bigger explosion
            }
        }

        // First settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                flameScale = 1.4
            }
        }

        // Final settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                flameScale = 1.0
            }
        }

        // Shockwave burst - bigger and slower
        shockwaveScale = 0.4
        shockwaveOpacity = 1.0
        withAnimation(.easeOut(duration: 0.5)) {
            shockwaveScale = 3.0
            shockwaveOpacity = 0
        }

        // Inner impact flash
        impactBurstScale = 0.2
        impactBurstOpacity = 1.0
        withAnimation(.easeOut(duration: 0.35)) {
            impactBurstScale = 2.5
            impactBurstOpacity = 0
        }

        // STRONG haptic slam
        HapticManager.shared.flameSlamImpact()

        // Shake effect via callback
        triggerShakeSequence()

        // Trigger ignition callback if going from 0→1
        if previousStreak == 0 {
            onIgnition?()
        }

        // Callback to trigger StreakHeroCard pulse
        onFlameArrived()

        // Fade out (merges with existing flame)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.easeOut(duration: 0.3)) {
                flameOpacity = 0
            }
        }

        // Complete and dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            phase = .complete
            withAnimation(.easeOut(duration: 0.2)) {
                isShowing = false
            }
        }
    }

    private func triggerShakeSequence() {
        // Oscillating shake - slightly more dramatic
        let shakeValues: [(CGFloat, Double)] = [
            (7, 0.02),
            (-6, 0.06),
            (5, 0.10),
            (-3, 0.14),
            (2, 0.18),
            (0, 0.22)
        ]

        for (value, delay) in shakeValues {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                onShake?(value)
            }
        }
    }
}

// MARK: - Flame Position Modifier

/// Positions the flame along the Bezier path based on progress
private struct FlamePositionModifier: ViewModifier, Animatable {
    var bezier: QuadraticBezier?
    var progress: CGFloat
    let fallbackPosition: CGPoint

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let position: CGPoint
        if let bezier = bezier {
            position = bezier.point(at: progress)
        } else {
            position = fallbackPosition
        }

        return content.position(position)
    }
}

#Preview {
    ZStack {
        MPColors.background.ignoresSafeArea()

        LockInCelebrationView(
            isShowing: .constant(true),
            buttonPosition: CGPoint(x: 200, y: 600),
            streakFlamePosition: CGPoint(x: 60, y: 200),
            previousStreak: 0,
            onFlameArrived: {},
            onIgnition: {},
            onShake: { _ in }
        )
    }
}
