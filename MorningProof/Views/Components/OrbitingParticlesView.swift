import SwiftUI

/// Canvas-based orbiting particle system for holographic card effect
/// Features: sparkles, gold dust, and rainbow orbs with elliptical orbits and depth fading
struct OrbitingParticlesView: View {
    let isAnimating: Bool

    @State private var particles: [OrbitingParticle] = []
    @State private var startTime: Date?

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isAnimating)) { timeline in
                Canvas { context, size in
                    let elapsed = timeline.date.timeIntervalSince(startTime ?? timeline.date)

                    // Update and render particles
                    for i in particles.indices {
                        updateParticle(index: i, elapsed: elapsed, size: size)
                        renderParticle(particles[i], in: context, size: size)
                    }
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                startTime = Date()
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Particle Creation

    private func createParticles(in size: CGSize) {
        var newParticles: [OrbitingParticle] = []

        // 8 sparkles - fast, close to card edge
        for _ in 0..<8 {
            newParticles.append(OrbitingParticle(
                type: .sparkle,
                angle: Double.random(in: 0...(2 * .pi)),
                angularSpeed: Double.random(in: 0.8...1.5),
                orbitRadiusX: CGFloat.random(in: 0.52...0.58),
                orbitRadiusY: CGFloat.random(in: 0.52...0.58),
                particleSize: CGFloat.random(in: 3...6),
                color: [Color.cyan, Color.pink, Color.white].randomElement()!,
                phaseOffset: Double.random(in: 0...(2 * .pi))
            ))
        }

        // 4 gold dust - slower, wider orbit
        for _ in 0..<4 {
            newParticles.append(OrbitingParticle(
                type: .goldDust,
                angle: Double.random(in: 0...(2 * .pi)),
                angularSpeed: Double.random(in: 0.3...0.6),
                orbitRadiusX: CGFloat.random(in: 0.58...0.68),
                orbitRadiusY: CGFloat.random(in: 0.58...0.68),
                particleSize: CGFloat.random(in: 4...8),
                color: Color(red: 1.0, green: 0.84, blue: 0.0),
                phaseOffset: Double.random(in: 0...(2 * .pi))
            ))
        }

        // 4 rainbow orbs - slowest, largest, blurred
        for _ in 0..<4 {
            newParticles.append(OrbitingParticle(
                type: .rainbowOrb,
                angle: Double.random(in: 0...(2 * .pi)),
                angularSpeed: Double.random(in: 0.15...0.25),
                orbitRadiusX: CGFloat.random(in: 0.65...0.75),
                orbitRadiusY: CGFloat.random(in: 0.65...0.75),
                particleSize: CGFloat.random(in: 12...18),
                color: [Color.purple, Color.cyan, Color.pink, Color.blue].randomElement()!,
                phaseOffset: Double.random(in: 0...(2 * .pi))
            ))
        }

        particles = newParticles
    }

    // MARK: - Particle Update

    private func updateParticle(index: Int, elapsed: TimeInterval, size: CGSize) {
        guard index < particles.count else { return }

        // Update angle based on angular speed
        let newAngle = particles[index].angle + particles[index].angularSpeed * (1.0 / 60.0)
        particles[index].angle = newAngle.truncatingRemainder(dividingBy: 2 * .pi)

        // Calculate position on elliptical orbit
        let centerX = size.width / 2
        let centerY = size.height / 2
        let radiusX = size.width * particles[index].orbitRadiusX / 2
        let radiusY = size.height * particles[index].orbitRadiusY / 2

        particles[index].x = centerX + cos(particles[index].angle) * radiusX
        particles[index].y = centerY + sin(particles[index].angle) * radiusY

        // Calculate depth (for fading when "behind" the card)
        // sin(angle) > 0 means particle is in front (bottom half of orbit visually)
        let depth = sin(particles[index].angle)
        particles[index].depthFade = depth > 0 ? 1.0 : 0.4

        // Sparkle twinkle effect
        if particles[index].type == .sparkle {
            let twinkle = sin(elapsed * 8 + particles[index].phaseOffset) * 0.3 + 0.7
            particles[index].currentOpacity = twinkle * particles[index].depthFade
        } else {
            particles[index].currentOpacity = particles[index].depthFade
        }
    }

    // MARK: - Particle Rendering

    private func renderParticle(_ particle: OrbitingParticle, in context: GraphicsContext, size: CGSize) {
        var ctx = context
        ctx.opacity = particle.currentOpacity

        let center = CGPoint(x: particle.x, y: particle.y)

        switch particle.type {
        case .sparkle:
            renderSparkle(center: center, size: particle.particleSize, color: particle.color, in: &ctx)

        case .goldDust:
            renderGoldDust(center: center, size: particle.particleSize, color: particle.color, in: &ctx)

        case .rainbowOrb:
            renderRainbowOrb(center: center, size: particle.particleSize, color: particle.color, in: &ctx)
        }
    }

    private func renderSparkle(center: CGPoint, size: CGFloat, color: Color, in ctx: inout GraphicsContext) {
        // Glow
        let glowRect = CGRect(
            x: center.x - size,
            y: center.y - size,
            width: size * 2,
            height: size * 2
        )
        ctx.fill(
            Path(ellipseIn: glowRect),
            with: .color(color.opacity(0.3))
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
            with: .color(color)
        )

        // Bright center
        let brightRect = CGRect(
            x: center.x - size / 4,
            y: center.y - size / 4,
            width: size / 2,
            height: size / 2
        )
        ctx.fill(
            Path(ellipseIn: brightRect),
            with: .color(.white)
        )
    }

    private func renderGoldDust(center: CGPoint, size: CGFloat, color: Color, in ctx: inout GraphicsContext) {
        // Soft glow
        let glowRect = CGRect(
            x: center.x - size * 1.5,
            y: center.y - size * 1.5,
            width: size * 3,
            height: size * 3
        )
        ctx.fill(
            Path(ellipseIn: glowRect),
            with: .color(color.opacity(0.2))
        )

        // Main particle
        let rect = CGRect(
            x: center.x - size / 2,
            y: center.y - size / 2,
            width: size,
            height: size
        )
        ctx.fill(
            Path(ellipseIn: rect),
            with: .color(color.opacity(0.8))
        )
    }

    private func renderRainbowOrb(center: CGPoint, size: CGFloat, color: Color, in ctx: inout GraphicsContext) {
        // Multiple layers for blur effect
        for i in stride(from: 4, through: 1, by: -1) {
            let layerSize = size * CGFloat(i) / 2
            let layerOpacity = 0.15 / Double(i)
            let layerRect = CGRect(
                x: center.x - layerSize,
                y: center.y - layerSize,
                width: layerSize * 2,
                height: layerSize * 2
            )
            ctx.fill(
                Path(ellipseIn: layerRect),
                with: .color(color.opacity(layerOpacity))
            )
        }

        // Core
        let coreRect = CGRect(
            x: center.x - size / 3,
            y: center.y - size / 3,
            width: size / 1.5,
            height: size / 1.5
        )
        ctx.fill(
            Path(ellipseIn: coreRect),
            with: .color(color.opacity(0.4))
        )
    }
}

// MARK: - Particle Types

enum OrbitingParticleType {
    case sparkle      // Fast, small, twinkly
    case goldDust     // Medium, warm glow
    case rainbowOrb   // Slow, large, blurred
}

struct OrbitingParticle {
    let type: OrbitingParticleType

    // Orbital properties
    var angle: Double
    let angularSpeed: Double  // radians per second
    let orbitRadiusX: CGFloat // as fraction of container width
    let orbitRadiusY: CGFloat // as fraction of container height

    // Visual properties
    let particleSize: CGFloat
    let color: Color
    let phaseOffset: Double   // for twinkle timing variety

    // Computed position
    var x: CGFloat = 0
    var y: CGFloat = 0

    // Depth and opacity
    var depthFade: Double = 1.0
    var currentOpacity: Double = 1.0
}

#Preview {
    ZStack {
        MPColors.background
            .ignoresSafeArea()

        ZStack {
            // Placeholder card
            RoundedRectangle(cornerRadius: MPRadius.xl)
                .fill(MPColors.surface)
                .frame(width: 300, height: 400)

            OrbitingParticlesView(isAnimating: true)
                .frame(width: 350, height: 450)
        }
    }
}
