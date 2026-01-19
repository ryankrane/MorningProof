import SwiftUI

// MARK: - Neural Network Particle Cloud

/// High-end loading animation featuring 50 glowing particles with organic motion
/// and neural network-style connections. Used for the "Building Your Plan" onboarding step.
struct NeuralLoadingView: View {
    let progress: Double           // 0.0 to 1.0
    let isProcessing: Bool         // Controls animation on/off
    @Binding var burstTarget: CGPoint?  // Set to trigger burst toward target
    var onBurstComplete: (() -> Void)?  // Optional callback

    @State private var particles: [NeuralParticle] = []
    @State private var burstParticles: [BurstNeuralParticle] = []
    @State private var startTime: Date?
    @State private var lastProgressScale: CGFloat = 1.0
    @State private var displayedProgress: Int = 0
    @State private var pulsePhase: Double = 0
    @State private var viewSize: CGSize = .zero

    // Colors
    private let electricPurple = Color(red: 0.545, green: 0.361, blue: 0.965)  // #8B5CF6
    private let electricCyan = Color(red: 0.024, green: 0.714, blue: 0.831)    // #06B6D4

    private let particleCount = 50
    private let maxConnectionDistance: CGFloat = 80
    private let maxConnectionsPerParticle = 3

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Canvas layer for particles and connections
                TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isProcessing)) { timeline in
                    Canvas { context, size in
                        let elapsed = timeline.date.timeIntervalSince(startTime ?? timeline.date)

                        // Update particles
                        updateParticles(elapsed: elapsed, size: size)
                        updateBurstParticles(elapsed: elapsed)

                        // 1. Background pulse
                        renderBackgroundPulse(in: context, size: size, elapsed: elapsed)

                        // 2. Network lines (render before particles for depth)
                        renderNetworkLines(in: context, size: size)

                        // 3. Far particles (depth < 0.5)
                        for particle in particles.filter({ $0.depth < 0.5 }) {
                            renderParticle(particle, in: context)
                        }

                        // 4. Near particles (depth >= 0.5)
                        for particle in particles.filter({ $0.depth >= 0.5 }) {
                            renderParticle(particle, in: context)
                        }

                        // 5. Burst particles
                        for particle in burstParticles where particle.opacity > 0.01 {
                            renderBurstParticle(particle, in: context)
                        }
                    }
                }

                // 6. Text overlay (SwiftUI layer)
                percentageText
            }
            .onAppear {
                viewSize = geometry.size
                createParticles(in: geometry.size)
                startTime = Date()
            }
            .onChange(of: burstTarget) { _, newTarget in
                if let target = newTarget {
                    triggerBurst(toward: target)
                    // Reset the binding after triggering
                    DispatchQueue.main.async {
                        burstTarget = nil
                    }
                }
            }
            .onChange(of: progress) { _, newProgress in
                // Spring animation on percentage update
                let newDisplayed = Int(newProgress * 100)
                if newDisplayed != displayedProgress {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        lastProgressScale = 1.15
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) {
                        lastProgressScale = 1.0
                    }
                    displayedProgress = newDisplayed
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Percentage Text

    private var percentageText: some View {
        Text("\(displayedProgress)%")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [electricPurple, electricCyan],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .scaleEffect(lastProgressScale)
            .contentTransition(.numericText())
    }

    // MARK: - Particle Creation

    private func createParticles(in size: CGSize) {
        var newParticles: [NeuralParticle] = []

        for i in 0..<particleCount {
            // Size distribution: 60% small (3-5pt), 30% medium (6-8pt), 10% large (9-12pt)
            let sizeCategory = Double.random(in: 0...1)
            let particleSize: CGFloat
            if sizeCategory < 0.6 {
                particleSize = CGFloat.random(in: 3...5)
            } else if sizeCategory < 0.9 {
                particleSize = CGFloat.random(in: 6...8)
            } else {
                particleSize = CGFloat.random(in: 9...12)
            }

            // Color distribution: 40% Purple, 40% Cyan, 20% mixed
            let colorCategory = Double.random(in: 0...1)
            let baseColor: Color
            if colorCategory < 0.4 {
                baseColor = electricPurple
            } else if colorCategory < 0.8 {
                baseColor = electricCyan
            } else {
                // Mixed - interpolate
                let mix = Double.random(in: 0...1)
                baseColor = Color(
                    red: 0.545 * (1 - mix) + 0.024 * mix,
                    green: 0.361 * (1 - mix) + 0.714 * mix,
                    blue: 0.965 * (1 - mix) + 0.831 * mix
                )
            }

            let particle = NeuralParticle(
                index: i,
                // Orbital properties
                angleOffset: Double.random(in: 0...(2 * .pi)),
                orbitRadius: CGFloat.random(in: 0.25...0.45),  // As fraction of container
                frequency: Double.random(in: 0.3...0.8),
                // Secondary wobble
                secondaryFreq: Double.random(in: 0.4...1.2),
                secondaryAmplitudeX: CGFloat.random(in: 10...30),
                secondaryAmplitudeY: CGFloat.random(in: 10...30),
                phaseX: Double.random(in: 0...(2 * .pi)),
                phaseY: Double.random(in: 0...(2 * .pi)),
                // Micro-noise
                noiseFreq: Double.random(in: 2...5),
                noiseAmplitude: CGFloat.random(in: 2...6),
                noisePhaseX: Double.random(in: 0...(2 * .pi)),
                noisePhaseY: Double.random(in: 0...(2 * .pi)),
                // Depth oscillation
                depthFreq: Double.random(in: 0.2...0.6),
                depthPhase: Double.random(in: 0...(2 * .pi)),
                // Visual
                baseSize: particleSize,
                color: baseColor
            )
            newParticles.append(particle)
        }

        particles = newParticles
    }

    // MARK: - Particle Update

    private func updateParticles(elapsed: TimeInterval, size: CGSize) {
        guard !particles.isEmpty else { return }

        let centerX = size.width / 2
        let centerY = size.height / 2
        let baseRadius = min(size.width, size.height) / 2

        // Progress dynamics
        let speedMultiplier = 1.0 + progress * 1.5  // 1.0x at 0% → 2.5x at 100%
        let radiusMultiplier = 1.0 - (progress * 0.6)  // Full radius at 0% → 40% at 100%
        let glowIntensity = 0.3 + progress * 0.4  // Glow increases with progress

        for i in particles.indices {
            let p = particles[i]

            // Primary orbital sweep
            let primaryAngle = p.angleOffset + elapsed * p.frequency * speedMultiplier
            let currentRadius = baseRadius * p.orbitRadius * radiusMultiplier
            let primaryX = cos(primaryAngle) * currentRadius
            let primaryY = sin(primaryAngle) * currentRadius

            // Secondary wobble (breaks circular path)
            let wobbleX = sin(elapsed * p.secondaryFreq * 2.3 * speedMultiplier + p.phaseX) * p.secondaryAmplitudeX
            let wobbleY = cos(elapsed * p.secondaryFreq * 1.8 * speedMultiplier + p.phaseY) * p.secondaryAmplitudeY

            // Micro-noise for organic feel
            let noiseX = sin(elapsed * p.noiseFreq * speedMultiplier + p.noisePhaseX) * p.noiseAmplitude
            let noiseY = cos(elapsed * p.noiseFreq * 1.3 * speedMultiplier + p.noisePhaseY) * p.noiseAmplitude

            // Combine positions
            particles[i].x = centerX + primaryX + wobbleX + noiseX
            particles[i].y = centerY + primaryY + wobbleY + noiseY

            // Depth oscillation (0 to 1, affects size and opacity)
            let rawDepth = sin(elapsed * p.depthFreq * speedMultiplier + p.depthPhase)
            particles[i].depth = (rawDepth + 1) / 2  // Normalize to 0-1

            // Calculate current size based on depth (closer = bigger)
            let depthScale = 0.6 + particles[i].depth * 0.8  // 0.6 to 1.4
            particles[i].currentSize = p.baseSize * depthScale

            // Calculate opacity based on depth
            particles[i].opacity = 0.4 + particles[i].depth * 0.6  // 0.4 to 1.0

            // Store glow intensity
            particles[i].glowIntensity = glowIntensity
        }
    }

    // MARK: - Background Pulse

    private func renderBackgroundPulse(in context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        let centerX = size.width / 2
        let centerY = size.height / 2

        // Pulse speed/intensity increases with progress
        let pulseSpeed = 1.0 + progress * 1.5
        let pulseIntensity = 0.05 + progress * 0.08

        // Multiple concentric pulse waves
        for wave in 0..<3 {
            let phase = elapsed * pulseSpeed + Double(wave) * 0.7
            let expansion = (sin(phase) + 1) / 2  // 0 to 1

            let maxRadius = min(size.width, size.height) * 0.5
            let radius = maxRadius * (0.3 + expansion * 0.4)
            let opacity = pulseIntensity * (1 - expansion * 0.5)

            // Gradient from center
            let gradient = Gradient(colors: [
                electricPurple.opacity(opacity),
                electricCyan.opacity(opacity * 0.5),
                Color.clear
            ])

            let rect = CGRect(
                x: centerX - radius,
                y: centerY - radius,
                width: radius * 2,
                height: radius * 2
            )

            context.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(
                    gradient,
                    center: CGPoint(x: centerX, y: centerY),
                    startRadius: 0,
                    endRadius: radius
                )
            )
        }
    }

    // MARK: - Network Lines

    private func renderNetworkLines(in context: GraphicsContext, size: CGSize) {
        var connectionCounts: [Int: Int] = [:]

        for i in particles.indices {
            let p1 = particles[i]
            guard (connectionCounts[i] ?? 0) < maxConnectionsPerParticle else { continue }

            for j in (i + 1)..<particles.count {
                guard (connectionCounts[j] ?? 0) < maxConnectionsPerParticle else { continue }

                let p2 = particles[j]
                let dx = p2.x - p1.x
                let dy = p2.y - p1.y
                let distance = sqrt(dx * dx + dy * dy)

                if distance < maxConnectionDistance && distance > 5 {
                    // Opacity falloff: closer = brighter (inverse square-ish)
                    let normalizedDist = distance / maxConnectionDistance
                    let lineOpacity = pow(1 - normalizedDist, 2) * 0.4 * (p1.glowIntensity + 0.3)

                    // Interpolate color based on particle colors
                    let lineColor = electricPurple.opacity(lineOpacity)

                    var path = Path()
                    path.move(to: CGPoint(x: p1.x, y: p1.y))
                    path.addLine(to: CGPoint(x: p2.x, y: p2.y))

                    context.stroke(
                        path,
                        with: .color(lineColor),
                        lineWidth: 1
                    )

                    connectionCounts[i, default: 0] += 1
                    connectionCounts[j, default: 0] += 1
                }
            }
        }
    }

    // MARK: - Particle Rendering

    private func renderParticle(_ particle: NeuralParticle, in context: GraphicsContext) {
        var ctx = context
        ctx.opacity = particle.opacity

        let center = CGPoint(x: particle.x, y: particle.y)
        let size = particle.currentSize
        let glowSize = size * (2.5 + particle.glowIntensity)

        // Outer glow
        let glowRect = CGRect(
            x: center.x - glowSize,
            y: center.y - glowSize,
            width: glowSize * 2,
            height: glowSize * 2
        )
        ctx.fill(
            Path(ellipseIn: glowRect),
            with: .color(particle.color.opacity(0.15 * particle.glowIntensity))
        )

        // Mid glow
        let midGlowSize = size * 1.5
        let midGlowRect = CGRect(
            x: center.x - midGlowSize,
            y: center.y - midGlowSize,
            width: midGlowSize * 2,
            height: midGlowSize * 2
        )
        ctx.fill(
            Path(ellipseIn: midGlowRect),
            with: .color(particle.color.opacity(0.3))
        )

        // Core
        let coreRect = CGRect(
            x: center.x - size / 2,
            y: center.y - size / 2,
            width: size,
            height: size
        )
        ctx.fill(
            Path(ellipseIn: coreRect),
            with: .color(particle.color)
        )

        // Bright center highlight
        let highlightSize = size * 0.4
        let highlightRect = CGRect(
            x: center.x - highlightSize / 2,
            y: center.y - highlightSize / 2,
            width: highlightSize,
            height: highlightSize
        )
        ctx.fill(
            Path(ellipseIn: highlightRect),
            with: .color(.white.opacity(0.8))
        )
    }

    // MARK: - Burst Effect

    /// Triggers a burst of particles toward a target point
    func triggerBurst(toward point: CGPoint) {
        HapticManager.shared.habitBurst()

        // Create 20 burst particles from center
        var newBurstParticles: [BurstNeuralParticle] = []

        // Get a few particles near the center to use as burst origins
        let sortedByCenter = particles.sorted { p1, p2 in
            let d1 = sqrt(pow(p1.x - point.x, 2) + pow(p1.y - point.y, 2))
            let d2 = sqrt(pow(p2.x - point.x, 2) + pow(p2.y - point.y, 2))
            return d1 > d2  // Farther particles burst toward target
        }

        for i in 0..<20 {
            let sourceParticle = sortedByCenter[i % sortedByCenter.count]

            // Direction toward target with spread
            let spread = CGFloat.random(in: -0.3...0.3)
            let dx = point.x - sourceParticle.x
            let dy = point.y - sourceParticle.y
            let baseAngle = atan2(dy, dx)
            let angle = baseAngle + spread

            let speed = CGFloat.random(in: 400...600)

            let burstParticle = BurstNeuralParticle(
                x: sourceParticle.x,
                y: sourceParticle.y,
                velocityX: cos(angle) * speed,
                velocityY: sin(angle) * speed,
                size: sourceParticle.baseSize * 0.8,
                color: sourceParticle.color,
                opacity: 1.0,
                drag: 0.92,
                birthTime: Date()
            )
            newBurstParticles.append(burstParticle)
        }

        burstParticles.append(contentsOf: newBurstParticles)

        // Clean up after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            onBurstComplete?()
        }
    }

    // MARK: - Burst Particle Update

    private func updateBurstParticles(elapsed: TimeInterval) {
        let dt: CGFloat = 1.0 / 60.0

        for i in burstParticles.indices {
            // Apply drag
            burstParticles[i].velocityX *= burstParticles[i].drag
            burstParticles[i].velocityY *= burstParticles[i].drag

            // Update position
            burstParticles[i].x += burstParticles[i].velocityX * dt
            burstParticles[i].y += burstParticles[i].velocityY * dt

            // Fade out over 0.6s
            let age = Date().timeIntervalSince(burstParticles[i].birthTime)
            let fadeProgress = min(1.0, age / 0.6)
            burstParticles[i].opacity = max(0, 1.0 - fadeProgress)
        }

        // Remove dead particles
        burstParticles.removeAll { $0.opacity <= 0.01 }
    }

    // MARK: - Burst Particle Rendering

    private func renderBurstParticle(_ particle: BurstNeuralParticle, in context: GraphicsContext) {
        var ctx = context
        ctx.opacity = particle.opacity

        let center = CGPoint(x: particle.x, y: particle.y)

        // Glow trail
        let glowSize = particle.size * 3
        let glowRect = CGRect(
            x: center.x - glowSize,
            y: center.y - glowSize,
            width: glowSize * 2,
            height: glowSize * 2
        )
        ctx.fill(
            Path(ellipseIn: glowRect),
            with: .color(particle.color.opacity(0.3))
        )

        // Core
        let coreRect = CGRect(
            x: center.x - particle.size / 2,
            y: center.y - particle.size / 2,
            width: particle.size,
            height: particle.size
        )
        ctx.fill(
            Path(ellipseIn: coreRect),
            with: .color(particle.color)
        )
    }
}

// MARK: - Particle Types

struct NeuralParticle {
    let index: Int

    // Orbital properties
    let angleOffset: Double
    let orbitRadius: CGFloat
    let frequency: Double

    // Secondary wobble
    let secondaryFreq: Double
    let secondaryAmplitudeX: CGFloat
    let secondaryAmplitudeY: CGFloat
    let phaseX: Double
    let phaseY: Double

    // Micro-noise
    let noiseFreq: Double
    let noiseAmplitude: CGFloat
    let noisePhaseX: Double
    let noisePhaseY: Double

    // Depth oscillation
    let depthFreq: Double
    let depthPhase: Double

    // Visual properties (immutable)
    let baseSize: CGFloat
    let color: Color

    // Computed state (mutable)
    var x: CGFloat = 0
    var y: CGFloat = 0
    var depth: Double = 0.5
    var currentSize: CGFloat = 0
    var opacity: Double = 1.0
    var glowIntensity: Double = 0.3
}

struct BurstNeuralParticle {
    var x: CGFloat
    var y: CGFloat
    var velocityX: CGFloat
    var velocityY: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
    var drag: CGFloat
    var birthTime: Date
}

// MARK: - Preview

struct NeuralLoadingViewPreview: View {
    @State private var burstTarget: CGPoint? = nil
    @State private var progress: Double = 0.65

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                NeuralLoadingView(
                    progress: progress,
                    isProcessing: true,
                    burstTarget: $burstTarget
                )
                .frame(width: 220, height: 220)

                HStack(spacing: 20) {
                    Button("Burst") {
                        burstTarget = CGPoint(x: 110, y: 300)
                    }
                    .foregroundColor(.white)

                    Button("Progress +10%") {
                        progress = min(1.0, progress + 0.1)
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    NeuralLoadingViewPreview()
}
