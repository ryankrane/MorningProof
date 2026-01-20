import SwiftUI

struct HydrationCameraView: View {
    @ObservedObject var manager: MorningProofManager
    @Environment(\.dismiss) var dismiss

    @State private var showingCamera = false
    @State private var selectedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var result: HydrationVerificationResult?
    @State private var errorMessage: String?
    @State private var errorIcon: String = "exclamationmark.triangle"

    // Animation states for result view
    @State private var showCheckmark = false
    @State private var showTitle = false
    @State private var showFeedback = false
    @State private var showConfetti = false
    @State private var showButton = false

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                if isAnalyzing {
                    analyzingView
                } else if let error = errorMessage {
                    errorView(error)
                } else if let result = result {
                    resultView(result)
                } else {
                    captureView
                }
            }
            .navigationTitle("Verify Hydration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(MPColors.textTertiary)
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
    }

    var captureView: some View {
        VStack(spacing: MPSpacing.xxl) {
            Spacer()

            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 350)
                    .cornerRadius(MPRadius.xl)
                    .mpShadow(.medium)
                    .padding(.horizontal, MPSpacing.xxl)

                HStack(spacing: MPSpacing.md) {
                    MPButton(title: "Retake", style: .secondary) {
                        selectedImage = nil
                    }

                    MPButton(title: "Verify", style: .primary) {
                        Task {
                            await verifyHydration(image: image)
                        }
                    }
                }
                .padding(.horizontal, MPSpacing.xxl)
            } else {
                VStack(spacing: MPSpacing.xl) {
                    VStack(spacing: MPSpacing.xl) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 80))
                            .foregroundColor(MPColors.textTertiary)

                        Text("Take a photo of your water")
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textTertiary)

                        Text("Show us your glass or water bottle!")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textTertiary.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .background(MPColors.surface)
                    .cornerRadius(MPRadius.xl)
                    .mpShadow(.medium)
                    .padding(.horizontal, MPSpacing.xxl)

                    MPButton(title: "Open Camera", style: .primary, icon: "camera.fill") {
                        showingCamera = true
                    }
                    .padding(.horizontal, MPSpacing.xxl)
                }
            }

            Spacer()
        }
    }

    @ViewBuilder
    var analyzingView: some View {
        if let image = selectedImage {
            VerificationLoadingView(
                image: image,
                accentColor: MPColors.primary,
                statusText: "Verifying..."
            )
        } else {
            // Fallback if no image (shouldn't happen)
            ProgressView()
                .scaleEffect(1.5)
        }
    }

    func resultView(_ result: HydrationVerificationResult) -> some View {
        ZStack {
            VStack(spacing: MPSpacing.xxl) {
                Spacer()

                if result.isWater {
                    // Success - with sequenced animations
                    ZStack {
                        Circle()
                            .fill(MPColors.successLight)
                            .frame(width: 120, height: 120)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(MPColors.success)
                    }
                    .scaleEffect(showCheckmark ? 1.0 : 0.3)
                    .opacity(showCheckmark ? 1.0 : 0)

                    Text("Hydration Verified!")
                        .font(MPFont.headingMedium())
                        .foregroundColor(MPColors.textPrimary)
                        .offset(y: showTitle ? 0 : 20)
                        .opacity(showTitle ? 1.0 : 0)

                    Text(result.feedback)
                        .font(MPFont.bodyLarge())
                        .foregroundColor(MPColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, MPSpacing.xxxl)
                        .offset(y: showFeedback ? 0 : 15)
                        .opacity(showFeedback ? 1.0 : 0)
                } else {
                    // Failure
                    ZStack {
                        Circle()
                            .fill(MPColors.errorLight)
                            .frame(width: 120, height: 120)

                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(MPColors.error)
                    }
                    .scaleEffect(showCheckmark ? 1.0 : 0.3)
                    .opacity(showCheckmark ? 1.0 : 0)

                    Text("Not Water...")
                        .font(MPFont.headingMedium())
                        .foregroundColor(MPColors.textPrimary)
                        .offset(y: showTitle ? 0 : 20)
                        .opacity(showTitle ? 1.0 : 0)

                    Text(result.feedback)
                        .font(MPFont.bodyLarge())
                        .foregroundColor(MPColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, MPSpacing.xxxl)
                        .offset(y: showFeedback ? 0 : 15)
                        .opacity(showFeedback ? 1.0 : 0)
                }

                Spacer()

                VStack(spacing: MPSpacing.md) {
                    if !result.isWater {
                        MPButton(title: "Fix & Rescan", style: .primary, icon: "arrow.clockwise") {
                            resetResultAnimations()
                            self.result = nil
                            selectedImage = nil
                        }
                        .offset(y: showButton ? 0 : 30)
                        .opacity(showButton ? 1.0 : 0)
                    }

                    MPButton(title: result.isWater ? "Done" : "Cancel", style: .secondary) {
                        dismiss()
                    }
                    .offset(y: showButton ? 0 : 30)
                    .opacity(showButton ? 1.0 : 0)
                }
                .padding(.horizontal, MPSpacing.xxl)
                .padding(.bottom, MPSpacing.xxxl)
            }

            // Confetti overlay for success
            if showConfetti && result.isWater {
                MiniConfettiView(particleCount: 30)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            startResultAnimations(isWater: result.isWater)
        }
    }

    private func startResultAnimations(isWater: Bool) {
        // Haptic feedback
        if isWater {
            HapticManager.shared.success()
        } else {
            HapticManager.shared.warning()
        }

        // Step 1: Checkmark/X scales in (0.0s)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showCheckmark = true
        }

        // Step 2: Title fades up (0.15s)
        withAnimation(.easeOut(duration: 0.3).delay(0.15)) {
            showTitle = true
        }

        // Step 3: Feedback text (0.3s)
        withAnimation(.easeOut(duration: 0.3).delay(0.3)) {
            showFeedback = true
        }

        // Step 4: Confetti burst (0.4s) - only for success
        if isWater {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showConfetti = true
                HapticManager.shared.habitCompleted()
            }
        }

        // Step 5: Button slides up (0.5s)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.5)) {
            showButton = true
        }
    }

    private func resetResultAnimations() {
        showCheckmark = false
        showTitle = false
        showFeedback = false
        showConfetti = false
        showButton = false
    }

    func errorView(_ message: String) -> some View {
        VStack(spacing: MPSpacing.xxl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(MPColors.errorLight)
                    .frame(width: 120, height: 120)

                Image(systemName: errorIcon)
                    .font(.system(size: 50))
                    .foregroundColor(MPColors.error)
            }

            Text("Verification Failed")
                .font(MPFont.headingMedium())
                .foregroundColor(MPColors.textPrimary)

            Text(message)
                .font(MPFont.bodyMedium())
                .foregroundColor(MPColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MPSpacing.xxxl)

            Spacer()

            VStack(spacing: MPSpacing.md) {
                if selectedImage != nil {
                    MPButton(title: "Try Again", style: .primary, icon: "arrow.clockwise") {
                        errorMessage = nil
                        errorIcon = "exclamationmark.triangle"
                        Task {
                            await verifyHydration(image: selectedImage!)
                        }
                    }
                }

                MPButton(title: "Retake Photo", style: .secondary, icon: "camera.fill") {
                    errorMessage = nil
                    errorIcon = "exclamationmark.triangle"
                    selectedImage = nil
                }

                MPButton(title: "Cancel", style: .secondary) {
                    dismiss()
                }
            }
            .padding(.horizontal, MPSpacing.xxl)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .onAppear {
            HapticManager.shared.error()
        }
    }

    func verifyHydration(image: UIImage) async {
        isAnalyzing = true
        errorMessage = nil
        errorIcon = "exclamationmark.triangle"

        do {
            result = try await manager.completeHydrationVerification(image: image)
            isAnalyzing = false
        } catch let apiError as APIError {
            errorMessage = apiError.localizedDescription
            errorIcon = apiError.iconName
            isAnalyzing = false
        } catch {
            errorMessage = error.localizedDescription
            errorIcon = "exclamationmark.triangle"
            isAnalyzing = false
        }
    }
}

#Preview {
    HydrationCameraView(manager: MorningProofManager.shared)
}
