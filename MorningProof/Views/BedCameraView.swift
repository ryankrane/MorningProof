import SwiftUI

struct BedCameraView: View {
    @ObservedObject var manager: MorningProofManager
    @Environment(\.dismiss) var dismiss

    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var result: VerificationResult?
    @State private var errorMessage: String?

    // Animation states for analyzing view
    @State private var scanRotation: Double = 0
    @State private var glowScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.4
    @State private var bedIconScale: CGFloat = 1.0
    @State private var analysisProgress: CGFloat = 0
    @State private var dotCount: Int = 0

    // Animation states for result view
    @State private var showCheckmark = false
    @State private var showTitle = false
    @State private var showScore = false
    @State private var animatedScore: Int = 0
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
                } else if let result = result {
                    resultView(result)
                } else {
                    captureView
                }
            }
            .navigationTitle("Verify Bed")
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
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
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
                            await verifyBed(image: image)
                        }
                    }
                }
                .padding(.horizontal, MPSpacing.xxl)
            } else {
                VStack(spacing: MPSpacing.xl) {
                    VStack(spacing: MPSpacing.xl) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(MPColors.border)

                        Text("Take a photo of your made bed")
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .background(MPColors.surface)
                    .cornerRadius(MPRadius.xl)
                    .mpShadow(.medium)
                    .padding(.horizontal, MPSpacing.xxl)

                    VStack(spacing: MPSpacing.md) {
                        MPButton(title: "Open Camera", style: .primary, icon: "camera.fill") {
                            showingCamera = true
                        }

                        Button {
                            showingImagePicker = true
                        } label: {
                            HStack(spacing: MPSpacing.sm) {
                                Image(systemName: "photo.on.rectangle")
                                Text("Choose from Library")
                            }
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.primary)
                        }
                        .padding(.top, MPSpacing.xs)
                    }
                    .padding(.horizontal, MPSpacing.xxl)
                }
            }

            Spacer()
        }
    }

    var analyzingView: some View {
        VStack(spacing: MPSpacing.xxxl) {
            Spacer()

            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [MPColors.accent.opacity(0.6), MPColors.accentGold.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(glowScale)
                    .opacity(glowOpacity)

                // Rotating scan line
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(
                        LinearGradient(
                            colors: [MPColors.accent, MPColors.accent.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(scanRotation))

                // White background circle
                Circle()
                    .fill(MPColors.surface)
                    .frame(width: 130, height: 130)
                    .shadow(color: MPColors.accent.opacity(0.3), radius: 20, x: 0, y: 5)

                // Bed icon with pulse
                Image(systemName: "bed.double.fill")
                    .font(.system(size: MPIconSize.xxl))
                    .foregroundColor(MPColors.primaryLight)
                    .scaleEffect(bedIconScale)
            }

            VStack(spacing: MPSpacing.md) {
                Text("Analyzing\(String(repeating: ".", count: dotCount))")
                    .font(MPFont.headingSmall())
                    .foregroundColor(MPColors.textPrimary)
                    .frame(width: 150, alignment: .leading)

                Text("AI is checking if it's made")
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textTertiary)
            }

            // Progress bar
            VStack(spacing: MPSpacing.sm) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: MPRadius.xs)
                            .fill(MPColors.progressBg)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: MPRadius.xs)
                            .fill(MPColors.accentGradient)
                            .frame(width: geometry.size.width * analysisProgress, height: 8)
                    }
                }
                .frame(height: 8)
                .frame(maxWidth: 200)

                Text("\(Int(analysisProgress * 100))%")
                    .font(MPFont.labelSmall())
                    .foregroundColor(MPColors.textTertiary)
            }

            Spacer()
        }
        .onAppear {
            startAnalyzingAnimations()
        }
        .onDisappear {
            resetAnalyzingAnimations()
        }
    }

    private func startAnalyzingAnimations() {
        // Rotating scan line
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            scanRotation = 360
        }

        // Glow pulse
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            glowScale = 1.15
            glowOpacity = 0.7
        }

        // Bed icon subtle pulse
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            bedIconScale = 1.05
        }

        // Progress bar (fake progress over ~3 seconds)
        withAnimation(.easeInOut(duration: 3.0)) {
            analysisProgress = 0.95
        }

        // Animated dots
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { timer in
            if !isAnalyzing {
                timer.invalidate()
                return
            }
            dotCount = (dotCount + 1) % 4
        }
    }

    private func resetAnalyzingAnimations() {
        scanRotation = 0
        glowScale = 1.0
        glowOpacity = 0.4
        bedIconScale = 1.0
        analysisProgress = 0
        dotCount = 0
    }

    func resultView(_ result: VerificationResult) -> some View {
        ZStack {
            VStack(spacing: MPSpacing.xxl) {
                Spacer()

                if result.isMade {
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

                    Text("Bed Verified!")
                        .font(MPFont.headingMedium())
                        .foregroundColor(MPColors.textPrimary)
                        .offset(y: showTitle ? 0 : 20)
                        .opacity(showTitle ? 1.0 : 0)

                    // Score with animated counter
                    VStack(spacing: MPSpacing.sm) {
                        Text("Score")
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textTertiary)

                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(animatedScore)")
                                .font(MPFont.displayMedium())
                                .foregroundColor(scoreColor(result.score))
                                .contentTransition(.numericText())
                            Text("/10")
                                .font(.title3)
                                .foregroundColor(MPColors.textTertiary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MPSpacing.xl)
                    .background(MPColors.surface)
                    .cornerRadius(MPRadius.lg)
                    .mpShadow(.medium)
                    .padding(.horizontal, 40)
                    .scaleEffect(showScore ? 1.0 : 0.8)
                    .opacity(showScore ? 1.0 : 0)

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
                    if !result.isMade {
                        MPButton(title: "Try Again", style: .primary, icon: "camera.fill") {
                            resetResultAnimations()
                            self.result = nil
                            selectedImage = nil
                        }
                        .offset(y: showButton ? 0 : 30)
                        .opacity(showButton ? 1.0 : 0)
                    }

                    MPButton(title: result.isMade ? "Done" : "Cancel", style: .secondary) {
                        dismiss()
                    }
                    .offset(y: showButton ? 0 : 30)
                    .opacity(showButton ? 1.0 : 0)
                }
                .padding(.horizontal, MPSpacing.xxl)
                .padding(.bottom, MPSpacing.xxxl)
            }

            // Confetti overlay for success
            if showConfetti && result.isMade {
                MiniConfettiView(particleCount: 30)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            startResultAnimations(isMade: result.isMade, score: result.score)
        }
    }

    private func startResultAnimations(isMade: Bool, score: Int) {
        // Haptic feedback
        if isMade {
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

        // Step 3: Score card appears (0.3s)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.3)) {
            showScore = true
        }

        // Step 4: Animate score counter (0.4s)
        if isMade {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                animateScoreCounter(to: score)
            }
        }

        // Step 5: Feedback text (0.5s)
        withAnimation(.easeOut(duration: 0.3).delay(0.5)) {
            showFeedback = true
        }

        // Step 6: Confetti burst (0.6s) - only for success
        if isMade {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showConfetti = true
                HapticManager.shared.habitCompleted()
            }
        }

        // Step 7: Button slides up (0.7s)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.7)) {
            showButton = true
        }
    }

    private func animateScoreCounter(to targetScore: Int) {
        let duration: Double = 0.6
        let steps = targetScore
        let interval = duration / Double(steps)

        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                withAnimation(.easeOut(duration: 0.05)) {
                    animatedScore = i
                }
            }
        }
    }

    private func resetResultAnimations() {
        showCheckmark = false
        showTitle = false
        showScore = false
        animatedScore = 0
        showFeedback = false
        showConfetti = false
        showButton = false
    }

    func scoreColor(_ score: Int) -> Color {
        switch score {
        case 9...10: return MPColors.success
        case 7...8: return MPColors.success
        case 5...6: return MPColors.warning
        default: return MPColors.accent
        }
    }

    func verifyBed(image: UIImage) async {
        isAnalyzing = true
        result = await manager.completeBedVerification(image: image)
        isAnalyzing = false
    }
}

#Preview {
    BedCameraView(manager: MorningProofManager.shared)
}
