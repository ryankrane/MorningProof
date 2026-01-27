import SwiftUI

/// Celebratory popup when an achievement is unlocked
/// Features tier-colored glow, sparkles, and satisfying animations
struct AchievementUnlockCelebrationView: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var badgeScale: CGFloat = 0.3
    @State private var badgeOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var glowScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 30
    @State private var sparkles: [SparkleParticle] = []
    @State private var showButton: Bool = false
    @State private var pendingWorkItems: [DispatchWorkItem] = []

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }

            // Sparkle particles
            ForEach(sparkles) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: sparkle.size))
                    .foregroundColor(sparkle.color)
                    .position(sparkle.position)
                    .opacity(sparkle.opacity)
                    .rotationEffect(.degrees(sparkle.rotation))
            }

            // Main content card
            VStack(spacing: MPSpacing.xl) {
                // Achievement badge with glow
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(achievement.tier.glowColor)
                        .frame(width: 140, height: 140)
                        .blur(radius: 30)
                        .opacity(glowOpacity)
                        .scaleEffect(glowScale)

                    // Pulsing ring
                    Circle()
                        .stroke(achievement.tier.color, lineWidth: 4)
                        .frame(width: 110, height: 110)
                        .scaleEffect(glowScale)
                        .opacity(glowOpacity * 0.8)

                    // Tier ring
                    Circle()
                        .stroke(achievement.tier.color, lineWidth: 4)
                        .frame(width: 100, height: 100)

                    // Background circle
                    Circle()
                        .fill(MPColors.surface)
                        .frame(width: 92, height: 92)

                    // Icon
                    Image(systemName: achievement.icon)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(achievement.tier.color)
                }
                .scaleEffect(badgeScale)
                .opacity(badgeOpacity)

                // "Achievement Unlocked!" label
                Text("Achievement Unlocked!")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(achievement.tier.color)
                    .textCase(.uppercase)
                    .tracking(1.5)
                    .opacity(contentOpacity)
                    .offset(y: contentOffset)

                // Achievement title
                Text(achievement.title)
                    .font(MPFont.displaySmall())
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(contentOpacity)
                    .offset(y: contentOffset)

                // Tier badge
                HStack(spacing: MPSpacing.xs) {
                    Image(systemName: tierIcon)
                        .font(.system(size: 14))
                    Text(achievement.tier.displayName.uppercased())
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(achievement.tier.color)
                .padding(.horizontal, MPSpacing.md)
                .padding(.vertical, MPSpacing.sm)
                .background(achievement.tier.color.opacity(0.15))
                .cornerRadius(MPRadius.md)
                .opacity(contentOpacity)
                .offset(y: contentOffset)

                // Description
                Text(achievement.description)
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MPSpacing.md)
                    .opacity(contentOpacity)
                    .offset(y: contentOffset)

                // Dismiss button
                if showButton {
                    Button(action: dismissWithAnimation) {
                        Text("Awesome!")
                            .font(MPFont.labelMedium())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MPSpacing.md)
                            .background(achievement.tier.color)
                            .cornerRadius(MPRadius.lg)
                    }
                    .padding(.horizontal, MPSpacing.lg)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .padding(.vertical, MPSpacing.xxl)
            .padding(.horizontal, MPSpacing.xl)
            .frame(maxWidth: 320)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.xl)
            .shadow(color: achievement.tier.color.opacity(0.3), radius: 30, x: 0, y: 15)
        }
        .onAppear {
            startCelebration()
        }
        .onDisappear {
            // Cancel all pending work items to prevent memory leaks
            pendingWorkItems.forEach { $0.cancel() }
            pendingWorkItems.removeAll()
        }
    }

    private var tierIcon: String {
        switch achievement.tier {
        case .bronze: return "medal"
        case .silver: return "medal.fill"
        case .gold: return "crown.fill"
        case .hidden: return "sparkles"
        }
    }

    private func startCelebration() {
        // Haptic feedback
        HapticManager.shared.success()

        // Create sparkles around the badge
        createSparkles()

        // Phase 1: Badge appears with bounce (0-0.4s)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            badgeScale = 1.0
            badgeOpacity = 1.0
        }

        // Phase 2: Glow pulses in (0.2-0.5s)
        scheduleWorkItem(delay: 0.2) { [self] in
            withAnimation(.easeOut(duration: 0.3)) {
                glowOpacity = 1.0
                glowScale = 1.0
            }

            // Start glow pulsing
            startGlowPulse()
        }

        // Phase 3: Content slides up (0.3-0.6s)
        scheduleWorkItem(delay: 0.3) { [self] in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                contentOpacity = 1.0
                contentOffset = 0
            }
        }

        // Phase 4: Button appears (0.6s)
        scheduleWorkItem(delay: 0.6) { [self] in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showButton = true
            }
        }

        // Animate sparkles
        animateSparkles()
    }

    /// Schedules a cancellable work item with a delay
    private func scheduleWorkItem(delay: Double, work: @escaping () -> Void) {
        let workItem = DispatchWorkItem(block: work)
        pendingWorkItems.append(workItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func startGlowPulse() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowScale = 1.1
            glowOpacity = 0.7
        }
    }

    private func createSparkles() {
        let colors = [
            achievement.tier.color,
            achievement.tier.color.opacity(0.7),
            MPColors.accentGold,
            .white
        ]

        // Create sparkles in a burst pattern
        for i in 0..<12 {
            let angle = Double(i) * (360.0 / 12.0) * .pi / 180.0
            let distance: CGFloat = CGFloat.random(in: 80...140)

            let sparkle = SparkleParticle(
                id: i,
                position: CGPoint(x: 160, y: 160), // Will be positioned from center of badge area
                color: colors.randomElement() ?? achievement.tier.color,
                size: CGFloat.random(in: 10...18),
                opacity: 0,
                rotation: Double.random(in: 0...360),
                targetX: 160 + cos(angle) * distance,
                targetY: 100 + sin(angle) * distance
            )
            sparkles.append(sparkle)
        }
    }

    private func animateSparkles() {
        for i in sparkles.indices {
            let delay = Double.random(in: 0...0.3)

            // Sparkle appears
            withAnimation(.easeOut(duration: 0.3).delay(delay)) {
                sparkles[i].opacity = 1.0
                sparkles[i].position = CGPoint(x: sparkles[i].targetX, y: sparkles[i].targetY)
            }

            // Sparkle rotates and fades
            withAnimation(.linear(duration: 1.5).delay(delay + 0.3)) {
                sparkles[i].rotation += 180
            }

            withAnimation(.easeIn(duration: 0.5).delay(delay + 0.8)) {
                sparkles[i].opacity = 0
            }
        }
    }

    private func dismissWithAnimation() {
        // Cancel any pending animations since we're dismissing
        pendingWorkItems.forEach { $0.cancel() }
        pendingWorkItems.removeAll()

        // Quick fade out
        withAnimation(.easeOut(duration: 0.2)) {
            badgeOpacity = 0
            contentOpacity = 0
            glowOpacity = 0
        }

        // Call dismiss after animation
        scheduleWorkItem(delay: 0.2) { [self] in
            onDismiss()
        }
    }
}

// MARK: - Sparkle Particle

struct SparkleParticle: Identifiable {
    let id: Int
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
    var rotation: Double
    var targetX: CGFloat
    var targetY: CGFloat
}

// MARK: - Tier-Colored Confetti View

struct TierConfettiView: View {
    let tier: AchievementTier
    @State private var particles: [TierConfettiParticle] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    confettiView(for: particle)
                        .frame(width: particle.size, height: particle.size * 0.6)
                        .rotationEffect(Angle.degrees(particle.rotation))
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func confettiView(for particle: TierConfettiParticle) -> some View {
        switch particle.shapeType {
        case 0: RoundedRectangle(cornerRadius: 1).fill(particle.color)
        case 1: Circle().fill(particle.color)
        default: DiamondShape().fill(particle.color)
        }
    }

    private var tierColors: [Color] {
        switch tier {
        case .bronze:
            return [
                Color(red: 0.80, green: 0.50, blue: 0.20),
                Color(red: 0.90, green: 0.60, blue: 0.30),
                Color(red: 0.70, green: 0.45, blue: 0.15),
                MPColors.accentGold.opacity(0.7)
            ]
        case .silver:
            return [
                Color(red: 0.75, green: 0.75, blue: 0.80),
                Color(red: 0.85, green: 0.85, blue: 0.90),
                Color(red: 0.65, green: 0.65, blue: 0.70),
                .white.opacity(0.8)
            ]
        case .gold:
            return [
                Color(red: 1.0, green: 0.84, blue: 0.0),
                Color(red: 1.0, green: 0.90, blue: 0.3),
                Color(red: 0.9, green: 0.75, blue: 0.0),
                .white.opacity(0.7)
            ]
        case .hidden:
            return [
                Color(red: 0.5, green: 0.4, blue: 0.7),
                Color(red: 0.6, green: 0.5, blue: 0.8),
                Color(red: 0.7, green: 0.4, blue: 0.9),
                .white.opacity(0.6)
            ]
        }
    }

    private func createParticles(in size: CGSize) {
        let colors = tierColors

        for i in 0..<40 {
            let particle = TierConfettiParticle(
                id: i,
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                color: colors.randomElement() ?? tier.color,
                size: CGFloat.random(in: 6...12),
                opacity: 1.0,
                rotation: Double.random(in: 0...360),
                shapeType: Int.random(in: 0...2)
            )
            particles.append(particle)
        }

        // Animate particles falling
        for i in 0..<particles.count {
            let delay = Double.random(in: 0...0.5)
            let duration = Double.random(in: 2...3)

            withAnimation(.easeOut(duration: duration).delay(delay)) {
                particles[i].position.y = size.height + 50
                particles[i].position.x += CGFloat.random(in: -100...100)
                particles[i].rotation += Double.random(in: 180...540)
            }

            withAnimation(.easeIn(duration: 0.5).delay(delay + duration - 0.5)) {
                particles[i].opacity = 0
            }
        }
    }
}

struct TierConfettiParticle: Identifiable {
    let id: Int
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
    var rotation: Double
    let shapeType: Int
}

// MARK: - Preview

#Preview {
    ZStack {
        MPColors.background.ignoresSafeArea()

        AchievementUnlockCelebrationView(
            achievement: Achievement.streakAchievements[3], // Gold tier
            onDismiss: { print("Dismissed") }
        )
    }
}

#Preview("Bronze Achievement") {
    ZStack {
        MPColors.background.ignoresSafeArea()

        AchievementUnlockCelebrationView(
            achievement: Achievement.streakAchievements[0], // Bronze tier
            onDismiss: { print("Dismissed") }
        )
    }
}

#Preview("Hidden Achievement") {
    ZStack {
        MPColors.background.ignoresSafeArea()

        AchievementUnlockCelebrationView(
            achievement: Achievement.hiddenAchievements[0], // Hidden tier
            onDismiss: { print("Dismissed") }
        )
    }
}
