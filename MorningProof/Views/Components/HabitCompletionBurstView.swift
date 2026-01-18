import SwiftUI

// MARK: - Burst Particle Types

enum BurstParticleType {
    case goldFoil       // Primary celebration particles with 3D tumbling
    case microSpark     // Fast, tiny particles that fade quickly
    case atmosphericOrb // Slow, blurry background orbs for depth
}

enum BurstShapeType {
    case rectangle
    case diamond
    case circle
}

enum ParticleLayer {
    case behind  // Rendered behind the card
    case front   // Rendered in front of the card
}

struct BurstParticle: Identifiable {
    let id = UUID()
    let type: BurstParticleType
    let layer: ParticleLayer  // For 3D layering effect

    // Position
    var x: CGFloat
    var y: CGFloat

    // Velocity
    var velocityX: CGFloat
    var velocityY: CGFloat

    // 3D rotation (for gold foil tumbling)
    var rotationX: Double
    var rotationY: Double
    var rotationZ: Double
    var rotationSpeedX: Double
    var rotationSpeedY: Double
    var rotationSpeedZ: Double

    // Visual properties
    var scale: CGFloat
    var opacity: Double
    var drag: CGFloat  // Air resistance factor (0.88-0.95)

    // Size
    var width: CGFloat
    var height: CGFloat

    // Shape (for variety)
    var shapeType: BurstShapeType
}

// MARK: - High-Performance Burst View using TimelineView

struct HabitCompletionBurstView: View {
    @Environment(\.colorScheme) private var colorScheme

    let originX: CGFloat
    let originY: CGFloat

    @State private var particles: [BurstParticle] = []
    @State private var startTime: Date?
    @State private var isComplete = false

    private let duration: Double = 1.3  // Short and punchy (under 1.5s)

    init(originX: CGFloat = 0, originY: CGFloat = 0) {
        self.originX = originX
        self.originY = originY
    }

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: isComplete)) { timeline in
                Canvas { context, _ in
                    let elapsed = timeline.date.timeIntervalSince(startTime ?? timeline.date)

                    // Update particles on each frame
                    if !isComplete {
                        updateParticles(elapsed: elapsed, deltaTime: 1.0 / 60.0)
                    }

                    // Render particles
                    for particle in particles {
                        renderParticle(particle, in: context)
                    }
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                startTime = Date()

                // Trigger haptic at burst moment
                HapticManager.shared.habitBurst()

                // Mark complete after duration
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    isComplete = true
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Particle Creation

    private func createParticles(in size: CGSize) {
        let centerX = originX > 0 ? originX : size.width / 2
        let centerY = originY > 0 ? originY : size.height / 2

        var newParticles: [BurstParticle] = []

        // Gold Foil Particles (20 particles) - Primary celebration
        newParticles.append(contentsOf: createGoldFoilParticles(centerX: centerX, centerY: centerY))

        // Micro-Sparks (20 particles) - Fast, fleeting sparkles
        newParticles.append(contentsOf: createMicroSparkParticles(centerX: centerX, centerY: centerY))

        // Atmospheric Orbs (5 particles) - Slow, dreamy background
        newParticles.append(contentsOf: createAtmosphericOrbParticles(centerX: centerX, centerY: centerY))

        particles = newParticles
    }

    private func createGoldFoilParticles(centerX: CGFloat, centerY: CGFloat) -> [BurstParticle] {
        var result: [BurstParticle] = []

        for i in 0..<20 {
            // Confetti cannon style: upward fan from -150° to -30° (in screen coords where -90° is up)
            let angle = Double.random(in: (-5 * .pi / 6)...(-1 * .pi / 6))
            let isInnerRing = i < 10
            let speed: CGFloat = isInnerRing
                ? CGFloat.random(in: 500...700)
                : CGFloat.random(in: 700...950)

            let baseDrag: CGFloat = isInnerRing ? 0.93 : 0.90
            let velocityDragFactor = (speed - 500) / 450 * 0.02
            let layer: ParticleLayer = i % 3 == 0 ? .behind : .front
            let shape: BurstShapeType = Bool.random() ? .rectangle : .diamond

            let particle = BurstParticle(
                type: .goldFoil,
                layer: layer,
                x: centerX,
                y: centerY,
                velocityX: cos(angle) * speed,
                velocityY: sin(angle) * speed,
                rotationX: Double.random(in: 0...360),
                rotationY: Double.random(in: 0...360),
                rotationZ: Double.random(in: 0...360),
                rotationSpeedX: Double.random(in: -900...900),
                rotationSpeedY: Double.random(in: -900...900),
                rotationSpeedZ: Double.random(in: -600...600),
                scale: CGFloat.random(in: 0.8...1.3),
                opacity: 1.0,
                drag: baseDrag - velocityDragFactor,
                width: CGFloat.random(in: 10...14),
                height: CGFloat.random(in: 5...7),
                shapeType: shape
            )
            result.append(particle)
        }

        return result
    }

    private func createMicroSparkParticles(centerX: CGFloat, centerY: CGFloat) -> [BurstParticle] {
        var result: [BurstParticle] = []

        for i in 0..<20 {
            // Wider upward fan for sparks: -160° to -20° (slightly wider spread than gold foil)
            let angle = Double.random(in: (-8 * .pi / 9)...(-1 * .pi / 9))
            let speed = CGFloat.random(in: 800...1200)
            let layer: ParticleLayer = i % 2 == 0 ? .behind : .front

            let particle = BurstParticle(
                type: .microSpark,
                layer: layer,
                x: centerX,
                y: centerY,
                velocityX: cos(angle) * speed,
                velocityY: sin(angle) * speed,
                rotationX: 0,
                rotationY: 0,
                rotationZ: Double.random(in: 0...360),
                rotationSpeedX: 0,
                rotationSpeedY: 0,
                rotationSpeedZ: 0,
                scale: 1.0,
                opacity: 1.0,
                drag: 0.87,
                width: 3,
                height: 3,
                shapeType: .circle
            )
            result.append(particle)
        }

        return result
    }

    private func createAtmosphericOrbParticles(centerX: CGFloat, centerY: CGFloat) -> [BurstParticle] {
        var result: [BurstParticle] = []

        for _ in 0..<5 {
            // Gentle upward drift: -135° to -45° (narrower, more focused upward)
            let angle = Double.random(in: (-3 * .pi / 4)...(-1 * .pi / 4))
            let speed = CGFloat.random(in: 80...160)

            let particle = BurstParticle(
                type: .atmosphericOrb,
                layer: .behind,
                x: centerX,
                y: centerY,
                velocityX: cos(angle) * speed,
                velocityY: sin(angle) * speed,
                rotationX: 0,
                rotationY: 0,
                rotationZ: 0,
                rotationSpeedX: 0,
                rotationSpeedY: 0,
                rotationSpeedZ: 0,
                scale: CGFloat.random(in: 0.7...1.0),
                opacity: 0.6,
                drag: 0.97,
                width: 18,
                height: 18,
                shapeType: .circle
            )
            result.append(particle)
        }

        return result
    }

    // MARK: - Physics Update (60fps)

    private func updateParticles(elapsed: TimeInterval, deltaTime: Double) {
        guard elapsed < duration else { return }

        let dt = CGFloat(deltaTime)
        let progress = elapsed / duration

        // Gravity kicks in after initial explosion (0.08s)
        let gravityEnabled = elapsed > 0.08
        let gravityStrength: CGFloat = 280

        for i in particles.indices {
            // Apply air resistance (exponential decay)
            particles[i].velocityX *= particles[i].drag
            particles[i].velocityY *= particles[i].drag

            // Apply gravity after initial burst
            if gravityEnabled {
                particles[i].velocityY += gravityStrength * dt
            }

            // Update position
            particles[i].x += particles[i].velocityX * dt
            particles[i].y += particles[i].velocityY * dt

            // Update 3D rotation (for gold foil tumbling)
            if particles[i].type == .goldFoil {
                particles[i].rotationX += particles[i].rotationSpeedX * deltaTime
                particles[i].rotationY += particles[i].rotationSpeedY * deltaTime
                particles[i].rotationZ += particles[i].rotationSpeedZ * deltaTime

                // Slow down rotation over time (damping)
                particles[i].rotationSpeedX *= 0.992
                particles[i].rotationSpeedY *= 0.992
                particles[i].rotationSpeedZ *= 0.992
            }

            // Fade based on particle type and timing
            updateParticleFade(index: i, progress: progress)
        }
    }

    private func updateParticleFade(index: Int, progress: Double) {
        switch particles[index].type {
        case .microSpark:
            // Micro-sparks fade very quickly (gone by 35%)
            let fadeProgress = min(1.0, progress / 0.35)
            particles[index].opacity = max(0, 1.0 - fadeProgress)

        case .goldFoil:
            // Gold foil: hold, then fade (starts at 40%, gone by 95%)
            if progress > 0.4 {
                let fadeProgress = (progress - 0.4) / 0.55
                particles[index].opacity = max(0, 1.0 - fadeProgress)
            }

        case .atmosphericOrb:
            // Orbs fade slowest (starts at 50%, gone by 100%)
            if progress > 0.5 {
                let fadeProgress = (progress - 0.5) / 0.5
                particles[index].opacity = max(0, 0.6 - fadeProgress * 0.6)
            }
        }
    }

    // MARK: - Canvas Rendering

    private func renderParticle(_ particle: BurstParticle, in context: GraphicsContext) {
        guard particle.opacity > 0.01 else { return }

        var ctx = context
        ctx.opacity = particle.opacity

        switch particle.type {
        case .goldFoil:
            renderGoldFoil(particle, in: &ctx)

        case .microSpark:
            renderMicroSpark(particle, in: &ctx)

        case .atmosphericOrb:
            renderAtmosphericOrb(particle, in: &ctx)
        }
    }

    private func renderGoldFoil(_ particle: BurstParticle, in ctx: inout GraphicsContext) {
        let color: Color = colorScheme == .dark
            ? Color(red: 1.0, green: 0.95, blue: 0.85)
            : Color(red: 1.0, green: 0.84, blue: 0.0)

        // Apply 3D rotation effect through scale (simplified for Canvas)
        let rotX = cos(particle.rotationX * .pi / 180)
        let rotY = cos(particle.rotationY * .pi / 180)
        let scaleX = abs(rotX) * particle.scale
        let scaleY = abs(rotY) * particle.scale

        let halfWidth = (particle.width * scaleX) / 2
        let halfHeight = (particle.height * scaleY) / 2

        let transformedRect = CGRect(
            x: particle.x - halfWidth,
            y: particle.y - halfHeight,
            width: particle.width * scaleX,
            height: particle.height * scaleY
        )

        // Draw glow for dark mode
        if colorScheme == .dark {
            let glowRect = transformedRect.insetBy(dx: -3, dy: -3)
            let glowColor = Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4)
            ctx.fill(
                Path(roundedRect: glowRect, cornerRadius: 2),
                with: .color(glowColor)
            )
        }

        // Draw particle based on shape
        if particle.shapeType == .diamond {
            var path = Path()
            path.move(to: CGPoint(x: transformedRect.midX, y: transformedRect.minY))
            path.addLine(to: CGPoint(x: transformedRect.maxX, y: transformedRect.midY))
            path.addLine(to: CGPoint(x: transformedRect.midX, y: transformedRect.maxY))
            path.addLine(to: CGPoint(x: transformedRect.minX, y: transformedRect.midY))
            path.closeSubpath()
            ctx.fill(path, with: .color(color))
        } else {
            ctx.fill(
                Path(roundedRect: transformedRect, cornerRadius: 1),
                with: .color(color)
            )
        }
    }

    private func renderMicroSpark(_ particle: BurstParticle, in ctx: inout GraphicsContext) {
        let color: Color = colorScheme == .dark
            ? Color.white
            : Color(red: 1.0, green: 0.84, blue: 0.0)

        let center = CGPoint(x: particle.x, y: particle.y)
        let radius = particle.width / 2

        // Glow effect for dark mode
        if colorScheme == .dark {
            let glowRadius = radius * 2
            let glowRect = CGRect(
                x: center.x - glowRadius,
                y: center.y - glowRadius,
                width: glowRadius * 2,
                height: glowRadius * 2
            )
            ctx.fill(
                Path(ellipseIn: glowRect),
                with: .color(Color.white.opacity(0.3))
            )
        }

        // Core
        let coreRect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        ctx.fill(
            Path(ellipseIn: coreRect),
            with: .color(color)
        )
    }

    private func renderAtmosphericOrb(_ particle: BurstParticle, in ctx: inout GraphicsContext) {
        let color = Color(red: 0.6, green: 0.4, blue: 0.8)

        let center = CGPoint(x: particle.x, y: particle.y)
        let radius = particle.width / 2 * particle.scale

        // Blurred orb effect (multiple layered circles)
        for i in stride(from: 3, through: 1, by: -1) {
            let layerRadius = radius * CGFloat(i) / 2
            let layerOpacity = 0.15 / Double(i)
            let layerRect = CGRect(
                x: center.x - layerRadius,
                y: center.y - layerRadius,
                width: layerRadius * 2,
                height: layerRadius * 2
            )

            ctx.fill(
                Path(ellipseIn: layerRect),
                with: .color(color.opacity(layerOpacity))
            )
        }
    }
}

// MARK: - View Modifier for Habit Completion Burst

struct HabitCompletionBurstModifier: ViewModifier {
    @Binding var isTriggered: Bool
    @State private var cardScale: CGFloat = 1.0
    @State private var showBurst = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(cardScale)
            .overlay(
                Group {
                    if showBurst {
                        HabitCompletionBurstView()
                            .allowsHitTesting(false)
                    }
                }
            )
            .onChange(of: isTriggered) { _, triggered in
                if triggered {
                    triggerBurst()
                }
            }
    }

    private func triggerBurst() {
        // Card "launcher" pulse: shrink then expand
        withAnimation(.spring(response: 0.12, dampingFraction: 0.5)) {
            cardScale = 0.97
        }

        // Show burst and expand card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            showBurst = true
            withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) {
                cardScale = 1.0
            }
        }

        // Clear burst after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            showBurst = false
            isTriggered = false
        }
    }
}

extension View {
    func habitCompletionBurst(isTriggered: Binding<Bool>) -> some View {
        modifier(HabitCompletionBurstModifier(isTriggered: isTriggered))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(red: 0.98, green: 0.96, blue: 0.93)
            .ignoresSafeArea()

        VStack {
            Text("Habit Completion Burst")
                .font(.headline)

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .frame(width: 300, height: 80)
                    .shadow(radius: 4)

                HabitCompletionBurstView()
            }
            .frame(width: 300, height: 200)
        }
    }
}
