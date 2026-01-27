import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @ObservedObject var manager: MorningProofManager
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showOnboarding = false
    @State private var showAuthError = false
    @State private var authErrorMessage = ""
    @State private var showAppleSetupAlert = false
    @State private var showGoogleSetupAlert = false

    var body: some View {
        ZStack {
            // Background
            MPColors.surface
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // App branding
                VStack(spacing: MPSpacing.xl) {
                    Text("Morning Proof")
                        .font(.system(size: 36, weight: .bold, design: .default))
                        .foregroundColor(MPColors.textPrimary)
                        .tracking(-0.5)

                    // Soft gradient orb
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        MPColors.accentLight.opacity(0.8),
                                        MPColors.accent.opacity(0.4),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)

                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [MPColors.accent, MPColors.accentGold],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }

                Spacer()
                    .frame(height: 60)

                // Purpose statement
                VStack(spacing: MPSpacing.md) {
                    Text("Build your morning routine")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(MPColors.textPrimary)

                    Text("Prove your habits with AI verification.\nTrack streaks, stay accountable, win your mornings.")
                        .font(MPFont.bodyMedium())
                        .foregroundColor(MPColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, MPSpacing.xxxl)

                Spacer()

                // Auth buttons
                VStack(spacing: MPSpacing.md) {
                    // Sign in with Apple (requires paid developer team to be selected)
                    Button {
                        showAppleSetupAlert = true
                    } label: {
                        HStack(spacing: MPSpacing.sm) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 18))
                            Text("Continue with Apple")
                                .font(.system(size: 17, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.black)
                        .cornerRadius(MPRadius.lg)
                    }

                    // Sign in with Google
                    Button {
                        showGoogleSetupAlert = true
                    } label: {
                        HStack(spacing: MPSpacing.md) {
                            Image("GoogleLogo")
                                .resizable()
                                .renderingMode(.original)
                                .frame(width: 20, height: 20)

                            Text("Continue with Google")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(MPColors.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(MPColors.surface)
                        .cornerRadius(MPRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: MPRadius.lg)
                                .stroke(MPColors.border, lineWidth: 1)
                        )
                    }

                    // Get Started (main action)
                    Button {
                        proceedWithoutAuth()
                    } label: {
                        HStack(spacing: MPSpacing.xs) {
                            Text("Get Started")
                                .font(.system(size: 17, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(MPColors.primary)
                        .cornerRadius(MPRadius.lg)
                    }
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.bottom, 50)
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingFlowView(manager: manager)
        }
        .alert("Sign In", isPresented: $showAuthError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authErrorMessage)
        }
        .alert("Apple Sign In", isPresented: $showAppleSetupAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your Apple Developer Program enrollment may still be processing. Once approved, select your paid team in Xcode under Signing & Capabilities.")
        }
        .alert("Google Sign In", isPresented: $showGoogleSetupAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Google Sign In requires setup in Google Cloud Console. Tap 'Get Started' to continue without sign in.")
        }
    }

    private func proceedAfterAuth() {
        if manager.hasCompletedOnboarding {
            // User already onboarded, go straight to dashboard
            manager.hasCompletedOnboarding = true
        } else {
            showOnboarding = true
        }
    }

    private func proceedWithoutAuth() {
        showOnboarding = true
    }
}

#Preview {
    WelcomeView(manager: MorningProofManager.shared)
}
