import SwiftUI

/// Instagram-worthy celebration view when all habits are completed
struct AllHabitsCompleteCelebrationView: View {
    @Binding var isShowing: Bool
    let streakCount: Int
    let habitsCompleted: Int
    let totalHabits: Int

    // Animation states
    @State private var showBackground = false
    @State private var showGradient = false
    @State private var raysRotation: Double = 0
    @State private var showRays = false
    @State private var ringScales: [CGFloat] = [0, 0, 0]
    @State private var ringOpacities: [Double] = [0.8, 0.8, 0.8]
    @State private var trophyScale: CGFloat = 0
    @State private var trophyRotation: Double = -15
    @State private var showSparkles = false
    @State private var statsCardOffset: CGFloat = 300
    @State private var displayedStreak: Int = 0
    @State private var showPerfectText = false
    @State private var showConfetti = false

    // Gold color palette
    private let goldPrimary = Color(red: 1.0, green: 0.84, blue: 0.0)    // #FFD700
    private let goldSecondary = Color(red: 1.0, green: 0.65, blue: 0.0)  // #FFA500
    private let goldLight = Color(red: 1.0, green: 0.9, blue: 0.36)      // #FFE55C

    var body: some View {
        ZStack {
            // Layer 1: Dark overlay
            Color.black.opacity(showBackground ? 0.85 : 0)
                .ignoresSafeArea()

            // Layer 2: Gold radial gradient
            RadialGradient(
                colors: [
                    goldPrimary.opacity(0.4),
                    goldPrimary.opacity(0.1),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 300
            )
            .opacity(showGradient ? 1 : 0)
            .ignoresSafeArea()

            // Layer 3: Light rays
            LightRaysView(goldColor: goldPrimary)
                .rotationEffect(.degrees(raysRotation))
                .opacity(showRays ? 0.6 : 0)

            // Layer 4: Pulsing rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [goldPrimary, goldSecondary],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(ringScales[index])
                    .opacity(ringOpacities[index])
            }

            // Layer 5: Sparkle particles
            if showSparkles {
                SparkleParticleView(goldColor: goldPrimary)
            }

            // Layer 6: Trophy
            TrophyIconView(
                scale: trophyScale,
                rotation: trophyRotation,
                goldPrimary: goldPrimary,
                goldSecondary: goldSecondary
            )

            // Layer 7: Stats card
            VStack(spacing: 0) {
                Spacer()

                StatsCardView(
                    streakCount: displayedStreak,
                    habitsCompleted: habitsCompleted,
                    totalHabits: totalHabits,
                    showPerfectText: showPerfectText,
                    goldColor: goldPrimary
                )
                .offset(y: statsCardOffset)

                Spacer().frame(height: 80)
            }

            // Layer 8: Confetti
            if showConfetti {
                PremiumGoldConfettiView(
                    goldPrimary: goldPrimary,
                    goldSecondary: goldSecondary,
                    goldLight: goldLight
                )
            }
        }
        .onAppear { startAnimationSequence() }
        .onTapGesture { dismissCelebration() }
    }

    private func startAnimationSequence() {
        // Trigger haptics
        HapticManager.shared.allHabitsCompleteCelebration()

        // 0.0s: Background fade in
        withAnimation(.easeOut(duration: 0.3)) {
            showBackground = true
        }

        // 0.1s: Gradient fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.3)) {
                showGradient = true
            }
        }

        // 0.2s: Light rays appear and start rotating
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.5)) {
                showRays = true
            }
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                raysRotation = 360
            }
        }

        // 0.3s: Ring 1 pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animateRing(index: 0)
        }

        // 0.4s: Trophy scales in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                trophyScale = 1.15
                trophyRotation = 5
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    trophyScale = 1.0
                    trophyRotation = 0
                }
            }
        }

        // 0.5s: Ring 2 pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animateRing(index: 1)
        }

        // 0.6s: Sparkles appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showSparkles = true
        }

        // 0.7s: Ring 3 pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            animateRing(index: 2)
        }

        // 0.8s: Stats card slides up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                statsCardOffset = 0
            }
        }

        // 1.0s: Streak count-up animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            animateStreakCount()
        }

        // 1.2s: "Perfect Morning" text appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                showPerfectText = true
            }
        }

        // 1.5s: Confetti starts falling
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showConfetti = true
        }
    }

    private func animateRing(index: Int) {
        ringScales[index] = 0.5
        ringOpacities[index] = 0.8
        withAnimation(.easeOut(duration: 0.6)) {
            ringScales[index] = 1.8
            ringOpacities[index] = 0
        }
    }

    private func animateStreakCount() {
        let duration = 0.8
        let steps = min(streakCount, 30) // Cap at 30 for smooth animation
        let interval = duration / Double(steps)

        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                displayedStreak = (streakCount * i) / steps
            }
        }
        // Ensure final value is exact
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            displayedStreak = streakCount
        }
    }

    private func dismissCelebration() {
        withAnimation(.easeOut(duration: 0.3)) {
            showBackground = false
            showGradient = false
            showRays = false
            showSparkles = false
            showConfetti = false
            statsCardOffset = 300
            trophyScale = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
        }
    }
}

// MARK: - Light Rays

struct LightRaysView: View {
    let goldColor: Color
    let rayCount = 12

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<rayCount, id: \.self) { index in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    goldColor.opacity(0.5),
                                    goldColor.opacity(0)
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 3, height: geometry.size.height * 0.5)
                        .offset(y: -geometry.size.height * 0.25)
                        .rotationEffect(.degrees(Double(index) * (360 / Double(rayCount))))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Trophy Icon

struct TrophyIconView: View {
    let scale: CGFloat
    let rotation: Double
    let goldPrimary: Color
    let goldSecondary: Color

    var body: some View {
        ZStack {
            // Glow behind trophy
            Circle()
                .fill(
                    RadialGradient(
                        colors: [goldPrimary.opacity(0.6), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)

            // Trophy icon
            Image(systemName: "trophy.fill")
                .font(.system(size: 80, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [goldPrimary, goldSecondary, goldPrimary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: goldPrimary.opacity(0.5), radius: 20)
        }
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotation))
        .offset(y: -100)
    }
}

// MARK: - Stats Card

struct StatsCardView: View {
    let streakCount: Int
    let habitsCompleted: Int
    let totalHabits: Int
    let showPerfectText: Bool
    let goldColor: Color

    var body: some View {
        VStack(spacing: 16) {
            // "Perfect Morning!" header
            if showPerfectText {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("PERFECT MORNING")
                    Image(systemName: "sparkles")
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(goldColor)
                .tracking(2)
                .transition(.scale.combined(with: .opacity))
            }

            // Large streak number
            VStack(spacing: 4) {
                Text("\(streakCount)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [goldColor, Color(red: 1.0, green: 0.65, blue: 0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .contentTransition(.numericText())

                Text("DAY STREAK")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(3)
            }

            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.horizontal, 40)

            // Habits completed
            HStack(spacing: 24) {
                VStack {
                    Text("\(habitsCompleted)/\(totalHabits)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("HABITS")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1)
                }

                // Checkmarks row
                HStack(spacing: 4) {
                    ForEach(0..<totalHabits, id: \.self) { index in
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(index < habitsCompleted ? Color(red: 0.3, green: 0.69, blue: 0.31) : .white.opacity(0.3))
                    }
                }
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [goldColor.opacity(0.5), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .padding(.horizontal, 32)
    }
}

// MARK: - Sparkle Particles

struct SparkleParticleView: View {
    let goldColor: Color

    @State private var sparkles: [Sparkle] = []

    struct Sparkle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
        var opacity: Double
        var targetY: CGFloat
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(sparkles) { sparkle in
                    Image(systemName: "sparkle")
                        .font(.system(size: 12))
                        .foregroundColor(goldColor)
                        .scaleEffect(sparkle.scale)
                        .opacity(sparkle.opacity)
                        .position(x: sparkle.x, y: sparkle.y)
                }
            }
            .onAppear {
                createSparkles(in: geometry.size)
                animateSparkles()
            }
        }
        .allowsHitTesting(false)
    }

    private func createSparkles(in size: CGSize) {
        sparkles = (0..<30).map { _ in
            Sparkle(
                x: CGFloat.random(in: 40...(size.width - 40)),
                y: size.height + 20,
                scale: CGFloat.random(in: 0.5...1.5),
                opacity: Double.random(in: 0.4...1.0),
                targetY: CGFloat.random(in: -50...size.height * 0.3)
            )
        }
    }

    private func animateSparkles() {
        for index in sparkles.indices {
            withAnimation(
                .easeOut(duration: Double.random(in: 2.5...4.0))
                .delay(Double.random(in: 0...1.0))
            ) {
                sparkles[index].y = sparkles[index].targetY
                sparkles[index].opacity = 0
            }
        }
    }
}

// MARK: - Premium Gold Confetti

struct PremiumGoldConfettiView: View {
    let goldPrimary: Color
    let goldSecondary: Color
    let goldLight: Color

    @State private var particles: [MiniConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPieceView(shapeType: particle.shapeType, color: particle.color)
                        .frame(width: 10, height: 10)
                        .scaleEffect(particle.scale)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(x: particle.x, y: particle.y)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private func createParticles(in size: CGSize) {
        let colors: [Color] = [goldPrimary, goldSecondary, .white, goldLight, Color(red: 0.83, green: 0.69, blue: 0.22)]

        particles = (0..<80).map { _ in
            MiniConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -30,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.6...1.4),
                opacity: 1.0,
                color: colors.randomElement() ?? .white,
                velocityX: CGFloat.random(in: -30...30),
                velocityY: CGFloat.random(in: 150...350),
                rotationSpeed: Double.random(in: -180...180),
                shapeType: ConfettiShapeType.allCases.randomElement() ?? .rectangle
            )
        }
    }

    private func animateParticles(in size: CGSize) {
        withAnimation(.easeIn(duration: 3.0)) {
            for i in particles.indices {
                particles[i].y = size.height + 50
                particles[i].x += particles[i].velocityX
                particles[i].rotation += particles[i].rotationSpeed * 3
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                for i in particles.indices {
                    particles[i].opacity = 0
                }
            }
        }
    }
}

#Preview {
    AllHabitsCompleteCelebrationView(
        isShowing: .constant(true),
        streakCount: 14,
        habitsCompleted: 3,
        totalHabits: 3
    )
}
