import SwiftUI

/// Elegant flame animation that flies up and snaps into the streak fire
/// Simple, magical, Disney-inspired - no overlays or stats cards
struct AllHabitsCompleteCelebrationView: View {
    @Binding var isShowing: Bool
    let streakCount: Int
    let onFlameArrived: () -> Void  // Callback to trigger StreakHeroCard pulse

    // Animation state
    @State private var flameScale: CGFloat = 0
    @State private var flameOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var glowScale: CGFloat = 0.8
    @State private var flamePosition: CGPoint = .zero
    @State private var phase: AnimationPhase = .forming

    enum AnimationPhase {
        case forming
        case pulsing
        case flying
        case arrived
    }

    // Fire colors
    private let fireOrange = Color(red: 1.0, green: 0.55, blue: 0.0)
    private let fireYellow = Color(red: 1.0, green: 0.8, blue: 0.0)

    var body: some View {
        GeometryReader { geometry in
            let screenCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            // Target: StreakHeroCard flame position (top-left area)
            let targetPosition = CGPoint(x: 52, y: 180)

            ZStack {
                // The flame with glow - no background overlay!
                ZStack {
                    // Outer glow
                    Text("🔥")
                        .font(.system(size: 100))
                        .blur(radius: 25)
                        .opacity(glowOpacity * 0.5)
                        .scaleEffect(glowScale)

                    // Inner glow
                    Text("🔥")
                        .font(.system(size: 85))
                        .blur(radius: 12)
                        .opacity(glowOpacity * 0.7)

                    // Core flame
                    Text("🔥")
                        .font(.system(size: 80))
                        .shadow(color: fireOrange.opacity(0.8), radius: 15)
                        .shadow(color: fireYellow.opacity(0.5), radius: 25)
                }
                .scaleEffect(flameScale)
                .opacity(flameOpacity)
                .position(flamePosition == .zero ? screenCenter : flamePosition)
            }
            .onAppear {
                flamePosition = screenCenter
                startAnimation(screenCenter: screenCenter, targetPosition: targetPosition)
            }
        }
        .allowsHitTesting(false)  // Don't block user interaction
    }

    private func startAnimation(screenCenter: CGPoint, targetPosition: CGPoint) {
        // Initial haptic
        HapticManager.shared.lightTap()

        // ===== PHASE 1: FLAME FORMS (0.0s - 0.4s) =====
        phase = .forming

        // Flame appears with spring bounce
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            flameScale = 1.0
            flameOpacity = 1.0
            glowOpacity = 1.0
            glowScale = 1.0
        }

        // ===== PHASE 2: FLAME PULSES (0.4s - 0.9s) =====
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            phase = .pulsing

            // First pulse
            withAnimation(.easeInOut(duration: 0.2)) {
                flameScale = 1.08
                glowScale = 1.15
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    flameScale = 1.0
                    glowScale = 1.0
                }
            }

            // Second smaller pulse
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    flameScale = 1.05
                    glowOpacity = 1.2
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    flameScale = 1.0
                    glowOpacity = 1.0
                }
            }
        }

        // ===== PHASE 3: DISNEY-STYLE FLIGHT (0.9s - 1.4s) =====
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            phase = .flying

            // Calculate waypoints for S-curve path
            let startX = screenCenter.x
            let startY = screenCenter.y
            let endX = targetPosition.x
            let endY = targetPosition.y

            // Waypoint 1: Hop up and right
            let waypoint1 = CGPoint(
                x: startX + 40,
                y: startY - 80
            )

            // Waypoint 2: Curve left
            let waypoint2 = CGPoint(
                x: startX - 30,
                y: startY - 180
            )

            // Waypoint 3: Swoop toward target
            let waypoint3 = CGPoint(
                x: endX + 60,
                y: endY + 80
            )

            // Shrink and start moving
            withAnimation(.easeOut(duration: 0.15)) {
                flameScale = 0.7
            }

            // Waypoint 1: hop right
            withAnimation(.easeOut(duration: 0.12)) {
                flamePosition = waypoint1
            }

            // Waypoint 2: curve left
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeInOut(duration: 0.12)) {
                    flamePosition = waypoint2
                    flameScale = 0.55
                }
            }

            // Waypoint 3: swoop toward target
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                withAnimation(.easeIn(duration: 0.1)) {
                    flamePosition = waypoint3
                    flameScale = 0.45
                }
            }

            // Final snap to target
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
                withAnimation(.spring(response: 0.12, dampingFraction: 0.7)) {
                    flamePosition = targetPosition
                    flameScale = 0.4
                }
            }
        }

        // ===== PHASE 4: SNAP & INTEGRATE (1.35s - 1.6s) =====
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
            phase = .arrived

            // Satisfying snap haptic
            HapticManager.shared.mediumTap()

            // Brief flash on arrival
            withAnimation(.easeOut(duration: 0.08)) {
                glowOpacity = 2.0
                glowScale = 1.5
            }

            // Fade out the flying flame
            withAnimation(.easeOut(duration: 0.15)) {
                flameOpacity = 0
                glowOpacity = 0
            }

            // Notify StreakHeroCard to pulse
            onFlameArrived()
        }

        // ===== CLEANUP (1.6s) =====
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            isShowing = false
        }
    }
}

// Simplified version for settings test (doesn't need the callback)
struct TestFlameAnimationView: View {
    @Binding var isShowing: Bool

    var body: some View {
        AllHabitsCompleteCelebrationView(
            isShowing: $isShowing,
            streakCount: 1,
            onFlameArrived: { }
        )
    }
}

#Preview {
    ZStack {
        Color(red: 0.98, green: 0.96, blue: 0.93)
            .ignoresSafeArea()

        VStack {
            Text("🔥 14 day streak")
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .padding(.top, 150)

            Spacer()
        }

        AllHabitsCompleteCelebrationView(
            isShowing: .constant(true),
            streakCount: 1,
            onFlameArrived: { print("Flame arrived!") }
        )
    }
}
