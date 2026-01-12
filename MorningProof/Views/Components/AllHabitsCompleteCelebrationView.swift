import SwiftUI

/// Flame celebration when all habits are completed - the flame forms and flies up to "ignite" the streak
struct AllHabitsCompleteCelebrationView: View {
    @Binding var isShowing: Bool
    let streakCount: Int
    let habitsCompleted: Int
    let totalHabits: Int

    // Animation phases
    @State private var phase: CelebrationPhase = .hidden
    @State private var showBackground = false
    @State private var flameScale: CGFloat = 0
    @State private var flameGlow: CGFloat = 0
    @State private var flameOffset: CGFloat = 0
    @State private var flameOpacity: Double = 0
    @State private var flameRotation: Double = 0
    @State private var showEmbers = false
    @State private var showTrail = false
    @State private var igniteFlash: Double = 0
    @State private var showStatsCard = false
    @State private var statsCardScale: CGFloat = 0.8
    @State private var displayedStreak: Int = 0
    @State private var showConfetti = false
    @State private var emberParticles: [EmberParticle] = []
    @State private var trailParticles: [TrailParticle] = []

    enum CelebrationPhase {
        case hidden
        case flameForming
        case flamePulsing
        case flameRising
        case igniting
        case celebrating
    }

    // Fire color palette
    private let fireOrange = Color(red: 1.0, green: 0.6, blue: 0.0)
    private let fireYellow = Color(red: 1.0, green: 0.85, blue: 0.0)
    private let fireRed = Color(red: 1.0, green: 0.3, blue: 0.1)
    private let fireGold = Color(red: 1.0, green: 0.75, blue: 0.0)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: Dark overlay
                Color.black.opacity(showBackground ? 0.9 : 0)
                    .ignoresSafeArea()

                // Layer 2: Ignite flash (full screen orange flash when flame "lands")
                Color.orange.opacity(igniteFlash)
                    .ignoresSafeArea()

                // Layer 3: Ember particles swirling around flame
                ForEach(emberParticles) { ember in
                    Circle()
                        .fill(ember.color)
                        .frame(width: ember.size, height: ember.size)
                        .blur(radius: 1)
                        .position(x: ember.x, y: ember.y)
                        .opacity(ember.opacity)
                }

                // Layer 4: Trail particles (when flame rises)
                ForEach(trailParticles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .blur(radius: 2)
                        .position(x: particle.x, y: particle.y)
                        .opacity(particle.opacity)
                }

                // Layer 5: Main flame
                ZStack {
                    // Outer glow
                    Text("🔥")
                        .font(.system(size: 180))
                        .blur(radius: 30)
                        .opacity(flameGlow * 0.6)

                    // Middle glow
                    Text("🔥")
                        .font(.system(size: 150))
                        .blur(radius: 15)
                        .opacity(flameGlow * 0.8)

                    // Core flame
                    Text("🔥")
                        .font(.system(size: 120))
                        .shadow(color: fireOrange, radius: 20)
                        .shadow(color: fireYellow, radius: 40)
                }
                .scaleEffect(flameScale)
                .opacity(flameOpacity)
                .rotationEffect(.degrees(flameRotation))
                .offset(y: flameOffset)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                // Layer 6: Stats card (after flame rises)
                if showStatsCard {
                    VStack(spacing: 0) {
                        // Fire emoji at top where flame "landed"
                        ZStack {
                            // Glow behind the streak fire
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [fireOrange.opacity(0.6), Color.clear],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 100
                                    )
                                )
                                .frame(width: 200, height: 200)

                            Text("🔥")
                                .font(.system(size: 80))
                                .shadow(color: fireOrange, radius: 15)
                        }
                        .padding(.top, 60)

                        Spacer()

                        // Stats card
                        FlameStatsCardView(
                            streakCount: displayedStreak,
                            habitsCompleted: habitsCompleted,
                            totalHabits: totalHabits,
                            fireColor: fireOrange
                        )
                        .scaleEffect(statsCardScale)

                        Spacer().frame(height: 80)
                    }
                }

                // Layer 7: Celebratory confetti/embers falling
                if showConfetti {
                    FireConfettiView(
                        fireOrange: fireOrange,
                        fireYellow: fireYellow,
                        fireRed: fireRed
                    )
                }
            }
        }
        .onAppear { startAnimationSequence() }
        .onTapGesture { dismissCelebration() }
    }

    private func startAnimationSequence() {
        // Trigger haptics
        HapticManager.shared.allHabitsCompleteCelebration()

        // Phase 1: Background fades in (0.0s)
        withAnimation(.easeOut(duration: 0.3)) {
            showBackground = true
        }

        // Phase 2: Flame forms in center (0.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            phase = .flameForming

            // Flame appears with bounce
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                flameScale = 1.0
                flameOpacity = 1.0
                flameGlow = 1.0
            }

            // Start ember particles
            showEmbers = true
            createEmberParticles()
            animateEmbers()
        }

        // Phase 3: Flame pulses/breathes (0.8s - 1.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            phase = .flamePulsing

            // Pulsing animation
            withAnimation(.easeInOut(duration: 0.4).repeatCount(3, autoreverses: true)) {
                flameScale = 1.15
            }

            // Slight wobble
            withAnimation(.easeInOut(duration: 0.2).repeatCount(6, autoreverses: true)) {
                flameRotation = 3
            }
        }

        // Phase 4: Flame shoots upward (1.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            phase = .flameRising

            // Create trail particles
            createTrailParticles()

            // Flame shrinks and shoots up
            withAnimation(.easeIn(duration: 0.4)) {
                flameScale = 0.3
                flameOffset = -400
                flameGlow = 2.0
            }

            // Animate trail
            animateTrail()
        }

        // Phase 5: Ignite flash (2.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            phase = .igniting

            // Hide the traveling flame
            flameOpacity = 0

            // Flash the screen
            withAnimation(.easeOut(duration: 0.1)) {
                igniteFlash = 0.8
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                igniteFlash = 0
            }

            // Haptic for the "snap"
            HapticManager.shared.heavyTap()
        }

        // Phase 6: Show stats card with fire at top (2.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            phase = .celebrating

            showStatsCard = true
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                statsCardScale = 1.0
            }

            // Animate streak count
            animateStreakCount()
        }

        // Phase 7: Confetti (2.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            showConfetti = true
        }
    }

    private func createEmberParticles() {
        emberParticles = (0..<20).map { _ in
            EmberParticle(
                x: UIScreen.main.bounds.width / 2 + CGFloat.random(in: -60...60),
                y: UIScreen.main.bounds.height / 2 + CGFloat.random(in: -40...60),
                size: CGFloat.random(in: 4...10),
                color: [fireOrange, fireYellow, fireRed].randomElement()!,
                opacity: Double.random(in: 0.6...1.0),
                angle: Double.random(in: 0...(2 * .pi)),
                distance: CGFloat.random(in: 30...80)
            )
        }
    }

    private func animateEmbers() {
        // Swirl embers around the flame
        for index in emberParticles.indices {
            let particle = emberParticles[index]
            let centerX = UIScreen.main.bounds.width / 2
            let centerY = UIScreen.main.bounds.height / 2

            withAnimation(
                .easeInOut(duration: Double.random(in: 0.8...1.5))
                .repeatCount(3, autoreverses: true)
            ) {
                emberParticles[index].x = centerX + cos(particle.angle + .pi) * particle.distance
                emberParticles[index].y = centerY + sin(particle.angle + .pi) * particle.distance - 50
            }
        }

        // Fade out embers when flame rises
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                for index in emberParticles.indices {
                    emberParticles[index].opacity = 0
                }
            }
        }
    }

    private func createTrailParticles() {
        let centerX = UIScreen.main.bounds.width / 2
        let startY = UIScreen.main.bounds.height / 2

        trailParticles = (0..<30).map { index in
            TrailParticle(
                x: centerX + CGFloat.random(in: -20...20),
                y: startY + CGFloat(index) * 15,
                size: CGFloat.random(in: 6...14),
                color: [fireOrange, fireYellow, fireRed, fireGold].randomElement()!,
                opacity: 1.0
            )
        }
    }

    private func animateTrail() {
        // Trail particles fade up
        for index in trailParticles.indices {
            withAnimation(
                .easeOut(duration: 0.6)
                .delay(Double(index) * 0.02)
            ) {
                trailParticles[index].y -= 100
                trailParticles[index].opacity = 0
            }
        }
    }

    private func animateStreakCount() {
        let duration = 0.6
        let steps = min(streakCount, 20)
        let interval = duration / Double(max(steps, 1))

        for i in 1...max(steps, 1) {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                displayedStreak = (streakCount * i) / max(steps, 1)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            displayedStreak = streakCount
        }
    }

    private func dismissCelebration() {
        withAnimation(.easeOut(duration: 0.3)) {
            showBackground = false
            showStatsCard = false
            showConfetti = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
        }
    }
}

// MARK: - Ember Particle

struct EmberParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
    var angle: Double
    var distance: CGFloat
}

// MARK: - Trail Particle

struct TrailParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
}

// MARK: - Flame Stats Card

struct FlameStatsCardView: View {
    let streakCount: Int
    let habitsCompleted: Int
    let totalHabits: Int
    let fireColor: Color

    var body: some View {
        VStack(spacing: 20) {
            // Streak message
            Text(streakMessage)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(fireColor)
                .multilineTextAlignment(.center)

            // Large streak number
            VStack(spacing: 4) {
                Text("\(streakCount)")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [fireColor, Color(red: 1.0, green: 0.4, blue: 0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .contentTransition(.numericText())

                Text(streakCount == 1 ? "DAY" : "DAY STREAK")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
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
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("HABITS")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1)
                }

                // Checkmarks row
                HStack(spacing: 6) {
                    ForEach(0..<totalHabits, id: \.self) { index in
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(index < habitsCompleted ? Color(red: 0.3, green: 0.75, blue: 0.35) : .white.opacity(0.3))
                    }
                }
            }

            // Tap to continue
            Text("tap to continue")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .padding(.top, 8)
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                colors: [fireColor.opacity(0.6), fireColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .padding(.horizontal, 32)
    }

    var streakMessage: String {
        if streakCount == 1 {
            return "🔥 STREAK IGNITED! 🔥"
        } else if streakCount < 7 {
            return "🔥 KEEP THE FIRE BURNING! 🔥"
        } else if streakCount < 30 {
            return "🔥 YOU'RE ON FIRE! 🔥"
        } else {
            return "🔥 UNSTOPPABLE! 🔥"
        }
    }
}

// MARK: - Fire Confetti

struct FireConfettiView: View {
    let fireOrange: Color
    let fireYellow: Color
    let fireRed: Color

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
        let colors: [Color] = [fireOrange, fireYellow, fireRed, .white, Color(red: 1.0, green: 0.9, blue: 0.6)]

        particles = (0..<60).map { _ in
            MiniConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -30,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.3),
                opacity: 1.0,
                color: colors.randomElement() ?? fireOrange,
                velocityX: CGFloat.random(in: -40...40),
                velocityY: CGFloat.random(in: 150...300),
                rotationSpeed: Double.random(in: -180...180),
                shapeType: [.star, .circle, .diamond].randomElement() ?? .star
            )
        }
    }

    private func animateParticles(in size: CGSize) {
        withAnimation(.easeIn(duration: 2.5)) {
            for i in particles.indices {
                particles[i].y = size.height + 50
                particles[i].x += particles[i].velocityX
                particles[i].rotation += particles[i].rotationSpeed * 2
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
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
        streakCount: 1,
        habitsCompleted: 3,
        totalHabits: 3
    )
}
