import SwiftUI

/// A premium holographic trading card effect for photo verification
/// Features: rainbow shimmer, specular highlight, 3D rotation, animated border, and orbiting particles
struct HolographicCardView: View {
    let image: UIImage
    let isAnimating: Bool

    @StateObject private var motionManager = MotionManager()

    // Animation states
    @State private var hologramRotation: Double = 0
    @State private var borderRotation: Double = 0
    @State private var shimmerOffset: CGFloat = -1
    @State private var baseOscillationX: Double = 0
    @State private var baseOscillationY: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var appearScale: CGFloat = 0.8
    @State private var appearOpacity: Double = 0

    private let cornerRadius: CGFloat = MPRadius.xl

    var body: some View {
        ZStack {
            // Orbiting particles (behind card)
            OrbitingParticlesView(isAnimating: isAnimating)

            // Main holographic card
            cardContent
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(holographicOverlays)
                .overlay(animatedBorder)
                .rotation3DEffect(
                    .degrees(baseOscillationX + motionManager.pitch * 12),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.4
                )
                .rotation3DEffect(
                    .degrees(baseOscillationY + motionManager.roll * 12),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.4
                )
                .scaleEffect(pulseScale * appearScale)
                .opacity(appearOpacity)
                .mpShadow(.large)
        }
        .onAppear {
            if isAnimating {
                startAnimations()
            }
        }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
    }

    // MARK: - Holographic Overlays

    private var holographicOverlays: some View {
        ZStack {
            // Layer 1: Rainbow rotation
            AngularGradient(
                colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red],
                center: .center,
                angle: .degrees(hologramRotation)
            )
            .blendMode(.overlay)
            .opacity(0.35)

            // Layer 2: Specular highlight that follows device tilt
            specularHighlight

            // Layer 3: Shimmer sweep
            shimmerSweep
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .allowsHitTesting(false)
    }

    private var specularHighlight: some View {
        GeometryReader { geometry in
            let highlightX = geometry.size.width / 2 + motionManager.roll * 30
            let highlightY = geometry.size.height / 2 + motionManager.pitch * 30

            RadialGradient(
                colors: [
                    Color.white.opacity(0.6),
                    Color.white.opacity(0.3),
                    Color.white.opacity(0)
                ],
                center: UnitPoint(
                    x: highlightX / geometry.size.width,
                    y: highlightY / geometry.size.height
                ),
                startRadius: 0,
                endRadius: geometry.size.width * 0.6
            )
            .blendMode(.plusLighter)
            .opacity(0.25)
        }
    }

    private var shimmerSweep: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [
                    Color.white.opacity(0),
                    Color.white.opacity(0.4),
                    Color.white.opacity(0.6),
                    Color.white.opacity(0.4),
                    Color.white.opacity(0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 0.4)
            .offset(x: shimmerOffset * geometry.size.width * 1.4)
            .blendMode(.plusLighter)
        }
    }

    // MARK: - Animated Border

    private var animatedBorder: some View {
        ZStack {
            // Rainbow border
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    AngularGradient(
                        colors: [.cyan, .blue, .purple, .pink, .red, .orange, .yellow, .green, .cyan],
                        center: .center,
                        angle: .degrees(borderRotation)
                    ),
                    lineWidth: 3
                )

            // Glow effects
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    AngularGradient(
                        colors: [.cyan, .blue, .purple, .pink, .red, .orange, .yellow, .green, .cyan],
                        center: .center,
                        angle: .degrees(borderRotation)
                    ),
                    lineWidth: 6
                )
                .blur(radius: 8)
                .opacity(0.5)

            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    AngularGradient(
                        colors: [.purple, .cyan, .purple],
                        center: .center,
                        angle: .degrees(borderRotation * 1.5)
                    ),
                    lineWidth: 4
                )
                .blur(radius: 12)
                .opacity(0.3)
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Appear animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            appearScale = 1.0
            appearOpacity = 1.0
        }

        // Hologram rotation (8s per cycle)
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            hologramRotation = 360
        }

        // Border rotation (3s per cycle, opposite direction)
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            borderRotation = -360
        }

        // Shimmer sweep (2.5s per sweep)
        animateShimmer()

        // Base oscillation (4s rock back and forth)
        animateOscillation()

        // Subtle pulse (2s cycle)
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulseScale = 1.02
        }
    }

    private func animateShimmer() {
        shimmerOffset = -1
        withAnimation(.easeInOut(duration: 2.5)) {
            shimmerOffset = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            animateShimmer()
        }
    }

    private func animateOscillation() {
        // Oscillate X axis: -3° to +3°
        withAnimation(.easeInOut(duration: 2)) {
            baseOscillationX = 3
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 2)) {
                baseOscillationX = -3
            }
        }

        // Oscillate Y axis with offset timing: -3° to +3°
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(.easeInOut(duration: 2)) {
                baseOscillationY = 3
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeInOut(duration: 2)) {
                baseOscillationY = -3
            }
        }

        // Repeat
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            animateOscillation()
        }
    }
}

#Preview {
    ZStack {
        MPColors.background
            .ignoresSafeArea()

        HolographicCardView(
            image: UIImage(systemName: "bed.double.fill")!,
            isAnimating: true
        )
        .frame(maxHeight: 450)
        .padding()
    }
}
