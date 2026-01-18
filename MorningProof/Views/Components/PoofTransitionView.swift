import SwiftUI

/// A view that transitions between two content views with a particle "poof" dissolve effect.
/// The first view dissolves into scattered particles, then the second view materializes from particles.
struct PoofTransitionView<FirstContent: View, SecondContent: View>: View {
    let showSecond: Bool
    let trigger: Bool  // When this changes to true, animate the transition
    @ViewBuilder let firstContent: () -> FirstContent
    @ViewBuilder let secondContent: () -> SecondContent

    // Animation states
    @State private var particles: [PoofParticle] = []
    @State private var isAnimating = false
    @State private var showFirst = true
    @State private var showSecondContent = false
    @State private var firstContentOpacity: Double = 1.0
    @State private var secondContentOpacity: Double = 0.0
    @State private var hasTriggeredOnce = false

    // Particle grid configuration
    private let gridColumns = 6
    private let gridRows = 2
    private let particleSize: CGFloat = 6

    var body: some View {
        ZStack(alignment: .leading) {
            // First content (counter)
            if showFirst && !showSecond {
                firstContent()
                    .opacity(firstContentOpacity)
            }

            // Particles overlay - positioned from left edge
            GeometryReader { geo in
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particleSize, height: particleSize)
                        .scaleEffect(particle.scale)
                        .opacity(particle.opacity)
                        .position(
                            x: particle.offset.x,
                            y: geo.size.height / 2 + particle.offset.y
                        )
                }
            }

            // Second content (Perfect Morning)
            if showSecondContent || (showSecond && !isAnimating && hasTriggeredOnce) {
                secondContent()
                    .opacity(secondContentOpacity)
            }
        }
        .onChange(of: trigger) { _, newValue in
            if newValue && showSecond && !hasTriggeredOnce {
                startPoofTransition()
            }
        }
        .onChange(of: showSecond) { oldValue, newValue in
            // If going from true to false (resetting), reset states
            if oldValue && !newValue {
                resetStates()
            }
            // If already showing second without animation trigger, just show it
            if newValue && !isAnimating && !hasTriggeredOnce {
                // Check if we should wait for trigger or show immediately
                // If trigger is already true, animate. Otherwise wait.
                if trigger {
                    startPoofTransition()
                }
            }
        }
        .onAppear {
            // If starting with showSecond = true, show it without animation
            if showSecond {
                showFirst = false
                showSecondContent = true
                secondContentOpacity = 1.0
                hasTriggeredOnce = true
            }
        }
    }

    private func resetStates() {
        particles.removeAll()
        isAnimating = false
        showFirst = true
        showSecondContent = false
        firstContentOpacity = 1.0
        secondContentOpacity = 0.0
        hasTriggeredOnce = false
    }

    private func startPoofTransition() {
        guard !isAnimating else { return }
        isAnimating = true
        hasTriggeredOnce = true

        // Create particles for dissolve
        createDissolveParticles()

        // Phase 1: Fade out first content while particles scatter
        withAnimation(.easeOut(duration: 0.15)) {
            firstContentOpacity = 0
        }

        // Animate particles scattering outward
        animateDissolve()

        // Phase 2: After dissolve, start materialize
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            showFirst = false
            createMaterializeParticles()
            animateMaterialize()
        }

        // Phase 3: Show second content as particles converge
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showSecondContent = true
            withAnimation(.easeIn(duration: 0.25)) {
                secondContentOpacity = 1.0
            }
        }

        // Cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            particles.removeAll()
            isAnimating = false
        }
    }

    private func createDissolveParticles() {
        particles.removeAll()

        // Create a grid of particles representing the content (left-aligned)
        let totalWidth: CGFloat = 140
        let totalHeight: CGFloat = 24
        let spacingX = totalWidth / CGFloat(gridColumns)
        let spacingY = totalHeight / CGFloat(gridRows)

        for row in 0..<gridRows {
            for col in 0..<gridColumns {
                // Position from left edge (0) to totalWidth
                let x = CGFloat(col) * spacingX + spacingX / 2
                let y = CGFloat(row) * spacingY - totalHeight / 2 + spacingY / 2

                let particle = PoofParticle(
                    homePosition: CGPoint(x: x, y: y),
                    offset: CGPoint(x: x, y: y),
                    scale: 1.0,
                    opacity: 1.0,
                    color: MPColors.success.opacity(Double.random(in: 0.6...1.0))
                )
                particles.append(particle)
            }
        }
    }

    private func animateDissolve() {
        // Scatter particles outward with random velocities
        for index in particles.indices {
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 40...80)
            let targetX = particles[index].homePosition.x + cos(angle) * distance
            let targetY = particles[index].homePosition.y + sin(angle) * distance

            let delay = Double.random(in: 0...0.1)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.25)) {
                    if index < particles.count {
                        particles[index].offset = CGPoint(x: targetX, y: targetY)
                        particles[index].scale = CGFloat.random(in: 0.3...0.6)
                        particles[index].opacity = 0
                    }
                }
            }
        }
    }

    private func createMaterializeParticles() {
        particles.removeAll()

        // Create particles that will converge to form the second content (left-aligned)
        let totalWidth: CGFloat = 140
        let totalHeight: CGFloat = 24
        let spacingX = totalWidth / CGFloat(gridColumns)
        let spacingY = totalHeight / CGFloat(gridRows)

        for row in 0..<gridRows {
            for col in 0..<gridColumns {
                // Position from left edge (0) to totalWidth
                let homeX = CGFloat(col) * spacingX + spacingX / 2
                let homeY = CGFloat(row) * spacingY - totalHeight / 2 + spacingY / 2

                // Start scattered
                let angle = Double.random(in: 0...(2 * .pi))
                let distance = CGFloat.random(in: 50...90)
                let startX = homeX + cos(angle) * distance
                let startY = homeY + sin(angle) * distance

                let particle = PoofParticle(
                    homePosition: CGPoint(x: homeX, y: homeY),
                    offset: CGPoint(x: startX, y: startY),
                    scale: CGFloat.random(in: 0.3...0.5),
                    opacity: 0,
                    color: MPColors.accentGold.opacity(Double.random(in: 0.6...1.0))
                )
                particles.append(particle)
            }
        }
    }

    private func animateMaterialize() {
        // Converge particles inward to home positions
        for index in particles.indices {
            let delay = Double.random(in: 0...0.15)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if index < particles.count {
                        particles[index].offset = particles[index].homePosition
                        particles[index].scale = 1.0
                        particles[index].opacity = 0.8
                    }
                }
            }

            // Fade out particles as content appears
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.2) {
                withAnimation(.easeOut(duration: 0.15)) {
                    if index < particles.count {
                        particles[index].opacity = 0
                    }
                }
            }
        }
    }
}

// MARK: - Particle Model

struct PoofParticle: Identifiable {
    let id = UUID()
    var homePosition: CGPoint
    var offset: CGPoint
    var scale: CGFloat
    var opacity: Double
    var color: Color
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var showPerfect = false
        @State private var trigger = false

        var body: some View {
            VStack(spacing: 40) {
                PoofTransitionView(
                    showSecond: showPerfect,
                    trigger: trigger
                ) {
                    // First content
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(MPColors.success)
                        Text("3/3 habits completed")
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textSecondary)
                    }
                } secondContent: {
                    // Second content
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(MPColors.accentGold)
                        Text("Perfect Morning!")
                            .font(MPFont.labelMedium())
                            .foregroundColor(MPColors.accentGold)
                    }
                }
                .frame(height: 30)

                Button("Trigger Poof!") {
                    showPerfect = true
                    trigger = true

                    // Reset trigger after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        trigger = false
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Reset") {
                    showPerfect = false
                    trigger = false
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(MPColors.background)
        }
    }

    return PreviewWrapper()
}
