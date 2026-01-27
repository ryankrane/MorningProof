import SwiftUI
import FamilyControls

// MARK: - App Blocking Explainer Step
// Consolidated step that explains app blocking value, privacy, and requests permission once

struct AppBlockingExplainerStep: View {
    let onContinue: () -> Void

    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @State private var showShield = false
    @State private var showCards = [false, false, false]
    @State private var showPrivacy = false
    @State private var showButton = false
    @State private var isRequesting = false
    @State private var shieldPulse: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.4

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MPSpacing.xxl) {
                    // Header with animated shield
                    headerSection
                        .padding(.top, MPSpacing.xl)

                    // Feature cards
                    featureCards
                        .padding(.horizontal, MPSpacing.xl)

                    // Privacy section
                    privacySection
                        .padding(.horizontal, MPSpacing.xl)

                    // Spacer for button
                    Spacer()
                        .frame(height: 120)
                }
            }

            // Bottom buttons
            bottomButtons
        }
        .background(MPColors.background.ignoresSafeArea())
        .onAppear {
            startAnimationSequence()
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: MPSpacing.md) {
            // Animated shield icon with glow
            ZStack {
                // Outer pulsing glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.red.opacity(glowOpacity), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(shieldPulse)

                // Inner glow ring
                Circle()
                    .stroke(Color.red.opacity(0.3), lineWidth: 2)
                    .frame(width: 90, height: 90)
                    .scaleEffect(shieldPulse * 1.05)

                // Main shield circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.35, blue: 0.2), Color(red: 0.9, green: 0.2, blue: 0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.red.opacity(0.5), radius: 15, x: 0, y: 5)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white)
            }
            .opacity(showShield ? 1 : 0)
            .scaleEffect(showShield ? 1 : 0.5)

            Text("Lock Your Time-Wasters")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(MPColors.textPrimary)
                .opacity(showShield ? 1 : 0)
                .offset(y: showShield ? 0 : 10)

            Text("Stay focused until your morning routine is done")
                .font(.system(size: 15))
                .foregroundColor(MPColors.textSecondary)
                .multilineTextAlignment(.center)
                .opacity(showShield ? 1 : 0)
                .offset(y: showShield ? 0 : 10)
        }
    }

    // MARK: - Feature Cards

    @ViewBuilder
    private var featureCards: some View {
        VStack(spacing: MPSpacing.md) {
            FeatureCard(
                icon: "lock.fill",
                iconColor: Color(red: 1.0, green: 0.35, blue: 0.2),
                title: "Apps Stay Locked",
                description: "Distractions blocked until habits complete",
                isVisible: showCards[0]
            )

            FeatureCard(
                icon: "iphone",
                iconColor: MPColors.primary,
                title: "You Choose Which Apps",
                description: "Select apps to block in Settings later",
                isVisible: showCards[1]
            )

            FeatureCard(
                icon: "lock.open.fill",
                iconColor: MPColors.success,
                title: "Instant Unlock",
                description: "Complete habits → apps unlock immediately",
                isVisible: showCards[2]
            )
        }
    }

    // MARK: - Privacy Badge

    @ViewBuilder
    private var privacySection: some View {
        HStack(spacing: MPSpacing.sm) {
            Image(systemName: "apple.logo")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(MPColors.textTertiary)

            Text("Powered by Apple Screen Time")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(MPColors.textTertiary)
        }
        .opacity(showPrivacy ? 1 : 0)
    }

    // MARK: - Bottom Buttons

    @ViewBuilder
    private var bottomButtons: some View {
        VStack(spacing: MPSpacing.md) {
            // Fade gradient at top
            LinearGradient(
                colors: [MPColors.background.opacity(0), MPColors.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 30)

            VStack(spacing: MPSpacing.md) {
                // Primary CTA button
                Button {
                    requestAuthorization()
                } label: {
                    HStack(spacing: MPSpacing.sm) {
                        if isRequesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        Text(isRequesting ? "Connecting..." : "Enable App Locking")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: MPButtonHeight.lg)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.35, blue: 0.2), Color(red: 0.9, green: 0.2, blue: 0.15)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(MPRadius.lg)
                    .shadow(color: Color.red.opacity(0.35), radius: 12, x: 0, y: 6)
                }
                .disabled(isRequesting)
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 20)

                // Skip button
                Button {
                    onContinue()
                } label: {
                    Text("Skip for now")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(MPColors.textTertiary)
                }
                .opacity(showButton ? 1 : 0)
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .background(MPColors.background.ignoresSafeArea(edges: .bottom))
    }

    // MARK: - Animation Sequence

    private func startAnimationSequence() {
        // Shield appears with spring + haptic
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showShield = true
        }
        HapticManager.shared.medium()

        // Start pulsing glow animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            shieldPulse = 1.08
            glowOpacity = 0.6
        }

        // Feature cards stagger in with light haptics
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + Double(i) * 0.15) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showCards[i] = true
                }
                HapticManager.shared.light()
            }
        }

        // Privacy section fades in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.5)) {
                showPrivacy = true
            }
        }

        // Button slides up
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showButton = true
            }
        }
    }

    // MARK: - Authorization

    private func requestAuthorization() {
        isRequesting = true
        Task {
            do {
                try await screenTimeManager.requestAuthorization()
                await MainActor.run {
                    isRequesting = false
                    if screenTimeManager.isAuthorized {
                        HapticManager.shared.success()
                        onContinue()
                    }
                }
            } catch {
                await MainActor.run {
                    isRequesting = false
                }
            }
        }
    }
}

// MARK: - Feature Card Component

private struct FeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let isVisible: Bool

    var body: some View {
        HStack(spacing: MPSpacing.md) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MPColors.textPrimary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer()
        }
        .padding(MPSpacing.md)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.md)
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -25)
    }
}

// MARK: - Preview

#Preview {
    AppBlockingExplainerStep {
        print("Continue tapped")
    }
    .preferredColorScheme(.dark)
}
