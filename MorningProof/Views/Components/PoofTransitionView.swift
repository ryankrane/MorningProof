import SwiftUI

/// A view that transitions between two content views with a particle "poof" dissolve effect.
/// The first view dissolves into scattered particles, then the second view materializes from particles.
struct PoofTransitionView<FirstContent: View, SecondContent: View>: View {
    let showSecond: Bool
    let trigger: Bool
    @ViewBuilder let firstContent: () -> FirstContent
    @ViewBuilder let secondContent: () -> SecondContent

    // Animation states
    @State private var dissolveParticles: [PoofParticle] = []
    @State private var materializeParticles: [PoofParticle] = []
    @State private var isAnimating = false
    @State private var showFirstContent = true
    @State private var showSecondContentView = false
    @State private var secondContentOpacity: Double = 0.0
    @State private var hasTriggeredOnce = false

    // Particle configuration
    private let particleCount = 12
    private let particleSize: CGFloat = 8

    var body: some View {
        ZStack(alignment: .leading) {
            // First content - visibility controlled only by showFirstContent
            firstContent()
                .opacity(showFirstContent ? 1.0 : 0.0)

            // Second content
            if showSecondContentView || (showSecond && !isAnimating && hasTriggeredOnce) {
                secondContent()
                    .opacity(secondContentOpacity)
            }

            // Dissolve particles (green, scatter outward)
            ForEach(dissolveParticles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particleSize, height: particleSize)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .offset(x: particle.offset.x, y: particle.offset.y)
            }

            // Materialize particles (gold, converge inward)
            ForEach(materializeParticles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particleSize, height: particleSize)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .offset(x: particle.offset.x, y: particle.offset.y)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, newValue in
            if newValue && showSecond && !hasTriggeredOnce {
                startPoofTransition()
            }
        }
        .onChange(of: showSecond) { oldValue, newValue in
            if oldValue && !newValue {
                resetStates()
            }
            if newValue && !isAnimating && !hasTriggeredOnce && trigger {
                startPoofTransition()
            }
        }
        .onAppear {
            if showSecond {
                showFirstContent = false
                showSecondContentView = true
                secondContentOpacity = 1.0
                hasTriggeredOnce = true
            }
        }
    }

    private func resetStates() {
        dissolveParticles.removeAll()
        materializeParticles.removeAll()
        isAnimating = false
        showFirstContent = true
        showSecondContentView = false
        secondContentOpacity = 0.0
        hasTriggeredOnce = false
    }

    private func startPoofTransition() {
        guard !isAnimating else { return }
        isAnimating = true
        hasTriggeredOnce = true

        // === PHASE 1: DISSOLVE ===
        // Create green particles where the text is
        createDissolveParticles()

        // Hide text, particles now visible in its place
        showFirstContent = false

        // Scatter particles outward
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            scatterDissolveParticles()
        }

        // === PHASE 2: MATERIALIZE ===
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            dissolveParticles.removeAll()
            createMaterializeParticles()
            convergeMaterializeParticles()
        }

        // Show Perfect Morning text as particles converge
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            showSecondContentView = true
            withAnimation(.easeIn(duration: 0.2)) {
                secondContentOpacity = 1.0
            }
        }

        // Cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            materializeParticles.removeAll()
            isAnimating = false
        }
    }

    // MARK: - Dissolve

    private func createDissolveParticles() {
        dissolveParticles.removeAll()

        // Create particles spread across where the text was
        for i in 0..<particleCount {
            let xPos = CGFloat(i) * 12 + 10  // Spread across ~150px
            let yOffset = CGFloat.random(in: -4...4)

            dissolveParticles.append(PoofParticle(
                id: UUID(),
                offset: CGPoint(x: xPos, y: yOffset),
                scale: 1.0,
                opacity: 1.0,
                color: MPColors.success
            ))
        }
    }

    private func scatterDissolveParticles() {
        for index in dissolveParticles.indices {
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 30...60)
            let currentOffset = dissolveParticles[index].offset

            let delay = Double(index) * 0.015

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.3)) {
                    if index < dissolveParticles.count {
                        dissolveParticles[index].offset = CGPoint(
                            x: currentOffset.x + cos(angle) * distance,
                            y: currentOffset.y + sin(angle) * distance
                        )
                        dissolveParticles[index].scale = 0.3
                        dissolveParticles[index].opacity = 0
                    }
                }
            }
        }
    }

    // MARK: - Materialize

    private func createMaterializeParticles() {
        materializeParticles.removeAll()

        // Create particles scattered, they'll converge to text position
        for i in 0..<particleCount {
            let homeX = CGFloat(i) * 12 + 10
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 40...70)

            materializeParticles.append(PoofParticle(
                id: UUID(),
                offset: CGPoint(
                    x: homeX + cos(angle) * distance,
                    y: sin(angle) * distance
                ),
                scale: 0.4,
                opacity: 0.9,
                color: MPColors.accentGold
            ))
        }
    }

    private func convergeMaterializeParticles() {
        for index in materializeParticles.indices {
            let homeX = CGFloat(index) * 12 + 10
            let delay = Double(index) * 0.02

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    if index < materializeParticles.count {
                        materializeParticles[index].offset = CGPoint(x: homeX, y: 0)
                        materializeParticles[index].scale = 1.0
                    }
                }
            }

            // Fade out as text appears
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.15) {
                withAnimation(.easeOut(duration: 0.15)) {
                    if index < materializeParticles.count {
                        materializeParticles[index].opacity = 0
                    }
                }
            }
        }
    }
}

// MARK: - Particle Model

struct PoofParticle: Identifiable {
    let id: UUID
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
                HStack {
                    PoofTransitionView(
                        showSecond: showPerfect,
                        trigger: trigger
                    ) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("3/3 habits completed")
                                .foregroundColor(.gray)
                        }
                    } secondContent: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                            Text("Perfect Morning!")
                                .foregroundColor(.yellow)
                        }
                    }

                    Spacer()
                }
                .frame(height: 24)

                Button("Trigger Poof!") {
                    showPerfect = true
                    trigger = true
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
            .padding(40)
            .background(Color.black)
        }
    }

    return PreviewWrapper()
}
