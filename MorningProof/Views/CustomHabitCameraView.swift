import SwiftUI

struct CustomHabitCameraView: View {
    @ObservedObject var manager: MorningProofManager
    @Environment(\.dismiss) var dismiss

    let customHabit: CustomHabit

    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var selectedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var result: CustomVerificationResult?
    @State private var errorMessage: String?
    @State private var errorIcon: String = "exclamationmark.triangle"

    // Animation states for initial capture view
    @State private var showIcon = false
    @State private var showText = false
    @State private var showCameraButton = false

    // Animation states for result view
    @State private var showCheckmark = false
    @State private var showTitle = false
    @State private var showFeedback = false
    @State private var showButton = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
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
                        captureView(geometry: geometry)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(MPColors.textTertiary)
                }

                ToolbarItem(placement: .principal) {
                    HStack(spacing: MPSpacing.sm) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        Text("Morning Proof")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(MPColors.textPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
        }
    }

    // MARK: - Capture View

    func captureView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            if let image = selectedImage {
                // Photo selected state
                photoSelectedView(image: image, geometry: geometry)
            } else {
                // Initial capture state - Apple-like design
                initialCaptureView
            }
        }
    }

    // MARK: - Initial Capture View (No Image)

    var initialCaptureView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Custom habit icon - clean, no rings
            Image(systemName: customHabit.icon)
                .font(.system(size: 80))
                .foregroundColor(MPColors.accent)
                .scaleEffect(showIcon ? 1.0 : 0.5)
                .opacity(showIcon ? 1.0 : 0)
                .frame(height: 120)

            Spacer()
                .frame(height: MPSpacing.xxxl)

            // Text content
            VStack(spacing: MPSpacing.sm) {
                Text(customHabit.allowsScreenshots ? "Verify with a photo" : "Take a photo to verify")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(MPColors.textPrimary)

                if let prompt = customHabit.aiPrompt, !prompt.isEmpty {
                    Text("\"\(prompt)\"")
                        .font(.system(size: 15))
                        .foregroundColor(MPColors.textTertiary)
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, MPSpacing.lg)
                }
            }
            .offset(y: showText ? 0 : 15)
            .opacity(showText ? 1.0 : 0)

            Spacer()

            // Camera button(s)
            VStack(spacing: MPSpacing.lg) {
                // Camera shutter button (iOS Camera style)
                CameraShutterButton {
                    showingCamera = true
                }
                .scaleEffect(showCameraButton ? 1.0 : 0.7)
                .opacity(showCameraButton ? 1.0 : 0)

                // Photo library option (if allowed)
                if customHabit.allowsScreenshots {
                    Button {
                        showingPhotoLibrary = true
                    } label: {
                        HStack(spacing: MPSpacing.sm) {
                            Image(systemName: "photo")
                                .font(.system(size: 16, weight: .medium))
                            Text("Choose from Library")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(MPColors.textTertiary)
                    }
                    .opacity(showCameraButton ? 1.0 : 0)
                }
            }

            Spacer()
                .frame(height: MPSpacing.xxxl + MPSpacing.lg)
        }
        .onAppear {
            startEntranceAnimations()
        }
    }

    private func startEntranceAnimations() {
        // Reset states first
        showIcon = false
        showText = false
        showCameraButton = false

        // Step 1: Icon scales in (0ms, spring)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showIcon = true
        }

        // Step 2: Text fades up (150ms delay)
        withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
            showText = true
        }

        // Step 3: Camera button appears (300ms delay)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.3)) {
            showCameraButton = true
        }
    }

    // MARK: - Photo Selected View

    func photoSelectedView(image: UIImage, geometry: GeometryProxy) -> some View {
        VStack(spacing: MPSpacing.xl) {
            // Photo with refined shadow
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: geometry.size.height * 0.55)
                .cornerRadius(MPRadius.xl)
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                .padding(.horizontal, MPSpacing.xxl)

            // Vertical button layout - close to photo
            VStack(spacing: MPSpacing.md) {
                // Primary verify button
                MPButton(title: "Verify Photo", style: .primary, icon: "checkmark") {
                    Task {
                        await verifyHabit(image: image)
                    }
                }
                .padding(.horizontal, MPSpacing.xxl)

                // Retake as text link (not bordered button)
                Button {
                    selectedImage = nil
                    // Reset entrance animations for when we go back
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        startEntranceAnimations()
                    }
                } label: {
                    Text("Retake Photo")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(MPColors.textTertiary)
                }
                .padding(.vertical, MPSpacing.sm)
            }

            Spacer()
        }
        .padding(.top, MPSpacing.lg)
    }

    // MARK: - Analyzing View

    @ViewBuilder
    var analyzingView: some View {
        if let image = selectedImage {
            VerificationLoadingView(
                image: image,
                accentColor: MPColors.accent,
                statusText: "Verifying..."
            )
        } else {
            ProgressView()
                .scaleEffect(1.5)
        }
    }

    // MARK: - Result View

    func resultView(_ result: CustomVerificationResult) -> some View {
        ZStack {
            VStack(spacing: MPSpacing.xxl) {
                Spacer()

                if result.isVerified {
                    // Success - with sequenced animations
                    ZStack {
                        // Subtle glow behind checkmark
                        Circle()
                            .fill(MPColors.success.opacity(0.2))
                            .frame(width: 140, height: 140)
                            .blur(radius: 20)

                        Circle()
                            .fill(MPColors.successLight)
                            .frame(width: 120, height: 120)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(MPColors.success)
                    }
                    .scaleEffect(showCheckmark ? 1.0 : 0.3)
                    .opacity(showCheckmark ? 1.0 : 0)

                    Text("\(customHabit.name) Verified!")
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
                            .font(.system(size: 80))
                            .foregroundColor(MPColors.error)
                    }
                    .scaleEffect(showCheckmark ? 1.0 : 0.3)
                    .opacity(showCheckmark ? 1.0 : 0)

                    Text("Not Quite...")
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
                    if !result.isVerified {
                        MPButton(title: "Fix & Rescan", style: .primary, icon: "arrow.clockwise") {
                            resetResultAnimations()
                            self.result = nil
                            selectedImage = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                startEntranceAnimations()
                            }
                        }
                        .offset(y: showButton ? 0 : 30)
                        .opacity(showButton ? 1.0 : 0)
                    }

                    MPButton(title: result.isVerified ? "Done" : "Cancel", style: .secondary) {
                        dismiss()
                    }
                    .offset(y: showButton ? 0 : 30)
                    .opacity(showButton ? 1.0 : 0)
                }
                .padding(.horizontal, MPSpacing.xxl)
                .padding(.bottom, MPSpacing.xxxl)
            }

        }
        .onAppear {
            startResultAnimations(isVerified: result.isVerified)
        }
    }

    private func startResultAnimations(isVerified: Bool) {
        // Haptic feedback
        if isVerified {
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

        // Step 4: Haptic feedback - only for success
        if isVerified {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
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
        showButton = false
    }

    // MARK: - Error View (Simplified to 2 buttons)

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

            // Simplified to 2 buttons: Try Again + Cancel
            VStack(spacing: MPSpacing.md) {
                MPButton(title: "Try Again", style: .primary, icon: "arrow.clockwise") {
                    errorMessage = nil
                    errorIcon = "exclamationmark.triangle"
                    if let image = selectedImage {
                        // Retry with existing image
                        Task {
                            await verifyHabit(image: image)
                        }
                    } else {
                        // Open camera if no image
                        showingCamera = true
                    }
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

    // MARK: - Verification

    func verifyHabit(image: UIImage) async {
        isAnalyzing = true
        errorMessage = nil
        errorIcon = "exclamationmark.triangle"

        do {
            result = try await manager.completeCustomHabitVerification(habit: customHabit, image: image)
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
    CustomHabitCameraView(
        manager: MorningProofManager.shared,
        customHabit: CustomHabit(
            name: "Take Vitamins",
            icon: "pill.fill",
            verificationType: .aiVerified,
            aiPrompt: "Show me your orange vitamin pill"
        )
    )
}
