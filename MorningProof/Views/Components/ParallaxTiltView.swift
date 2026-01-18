import SwiftUI
import CoreMotion

/// A view modifier that adds parallax tilt effect based on device accelerometer
/// Creates a premium, interactive feel for empty states and hero elements
struct ParallaxTiltModifier: ViewModifier {
    @StateObject private var motionManager = MotionManager()
    let intensity: CGFloat
    let perspective: CGFloat

    init(intensity: CGFloat = 15, perspective: CGFloat = 0.5) {
        self.intensity = intensity
        self.perspective = perspective
    }

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(motionManager.pitch * intensity),
                axis: (x: 1, y: 0, z: 0),
                perspective: perspective
            )
            .rotation3DEffect(
                .degrees(motionManager.roll * intensity),
                axis: (x: 0, y: 1, z: 0),
                perspective: perspective
            )
            .offset(
                x: motionManager.roll * intensity * 0.5,
                y: motionManager.pitch * intensity * 0.5
            )
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: motionManager.pitch)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: motionManager.roll)
    }
}

/// Manages device motion updates for parallax effects
class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()

    @Published var pitch: Double = 0
    @Published var roll: Double = 0

    init() {
        // Check if device motion is available
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 FPS

        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let motion = motion, error == nil else { return }

            DispatchQueue.main.async {
                // Normalize values to -1...1 range for smooth effect
                // Pitch: forward/backward tilt
                // Roll: left/right tilt
                self?.pitch = motion.attitude.pitch / .pi * 2
                self?.roll = motion.attitude.roll / .pi * 2
            }
        }
    }

    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}

extension View {
    /// Adds parallax tilt effect based on device motion
    /// - Parameters:
    ///   - intensity: How much the view rotates (default: 15 degrees max)
    ///   - perspective: 3D perspective depth (default: 0.5)
    func parallaxTilt(intensity: CGFloat = 15, perspective: CGFloat = 0.5) -> some View {
        modifier(ParallaxTiltModifier(intensity: intensity, perspective: perspective))
    }
}

#Preview {
    ZStack {
        MPColors.background
            .ignoresSafeArea()

        VStack(spacing: 40) {
            // Bed icon with parallax
            ZStack {
                Circle()
                    .fill(MPColors.accent.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                Image(systemName: "bed.double.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MPColors.accent, MPColors.accent.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .parallaxTilt(intensity: 15)

            Text("Tilt your device!")
                .font(MPFont.bodyMedium())
                .foregroundColor(MPColors.textTertiary)
        }
    }
}
