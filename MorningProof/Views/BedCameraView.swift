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
                Color(red: 0.98, green: 0.96, blue: 0.93)
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
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
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
        VStack(spacing: 24) {
            Spacer()

            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 350)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    Button {
                        selectedImage = nil
                    } label: {
                        Text("Retake")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.55, green: 0.45, blue: 0.35))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(14)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }

                    Button {
                        Task {
                            await verifyBed(image: image)
                        }
                    } label: {
                        Text("Verify")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.55, green: 0.45, blue: 0.35))
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 24)
            } else {
                VStack(spacing: 20) {
                    VStack(spacing: 20) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(Color(red: 0.8, green: 0.75, blue: 0.7))

                        Text("Take a photo of your made bed")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
                    .padding(.horizontal, 24)

                    VStack(spacing: 12) {
                        Button {
                            showingCamera = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "camera.fill")
                                Text("Open Camera")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color(red: 0.55, green: 0.45, blue: 0.35))
                            .cornerRadius(16)
                        }

                        Button {
                            showingImagePicker = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "photo.on.rectangle")
                                Text("Choose from Library")
                            }
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.55, green: 0.45, blue: 0.35))
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                }
            }

            Spacer()
        }
    }

    var analyzingView: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.9, green: 0.6, blue: 0.35).opacity(0.6),
                                Color(red: 0.85, green: 0.65, blue: 0.2).opacity(0.3)
                            ],
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
                            colors: [
                                Color(red: 0.9, green: 0.6, blue: 0.35),
                                Color(red: 0.9, green: 0.6, blue: 0.35).opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(scanRotation))

                // White background circle
                Circle()
                    .fill(Color.white)
                    .frame(width: 130, height: 130)
                    .shadow(color: Color(red: 0.9, green: 0.6, blue: 0.35).opacity(0.3), radius: 20, x: 0, y: 5)

                // Bed icon with pulse
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 45))
                    .foregroundColor(Color(red: 0.75, green: 0.65, blue: 0.55))
                    .scaleEffect(bedIconScale)
            }

            VStack(spacing: 12) {
                Text("Analyzing\(String(repeating: ".", count: dotCount))")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))
                    .frame(width: 150, alignment: .leading)

                Text("AI is checking if it's made")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
            }

            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 0.92, green: 0.9, blue: 0.87))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.9, green: 0.6, blue: 0.35),
                                        Color(red: 0.85, green: 0.65, blue: 0.2)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * analysisProgress, height: 8)
                    }
                }
                .frame(height: 8)
                .frame(maxWidth: 200)

                Text("\(Int(analysisProgress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
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
            VStack(spacing: 24) {
                Spacer()

                if result.isMade {
                    // Success - with sequenced animations
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.9, green: 0.97, blue: 0.9))
                            .frame(width: 120, height: 120)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(Color(red: 0.55, green: 0.75, blue: 0.55))
                    }
                    .scaleEffect(showCheckmark ? 1.0 : 0.3)
                    .opacity(showCheckmark ? 1.0 : 0)

                    Text("Bed Verified!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))
                        .offset(y: showTitle ? 0 : 20)
                        .opacity(showTitle ? 1.0 : 0)

                    // Score with animated counter
                    VStack(spacing: 8) {
                        Text("Score")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))

                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(animatedScore)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(scoreColor(result.score))
                                .contentTransition(.numericText())
                            Text("/10")
                                .font(.title3)
                                .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 3)
                    .padding(.horizontal, 40)
                    .scaleEffect(showScore ? 1.0 : 0.8)
                    .opacity(showScore ? 1.0 : 0)

                    Text(result.feedback)
                        .font(.body)
                        .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .offset(y: showFeedback ? 0 : 15)
                        .opacity(showFeedback ? 1.0 : 0)
                } else {
                    // Failure
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.98, green: 0.93, blue: 0.92))
                            .frame(width: 120, height: 120)

                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(Color(red: 0.85, green: 0.55, blue: 0.5))
                    }
                    .scaleEffect(showCheckmark ? 1.0 : 0.3)
                    .opacity(showCheckmark ? 1.0 : 0)

                    Text("Not Quite...")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))
                        .offset(y: showTitle ? 0 : 20)
                        .opacity(showTitle ? 1.0 : 0)

                    Text(result.feedback)
                        .font(.body)
                        .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .offset(y: showFeedback ? 0 : 15)
                        .opacity(showFeedback ? 1.0 : 0)
                }

                Spacer()

                VStack(spacing: 12) {
                    if !result.isMade {
                        Button {
                            resetResultAnimations()
                            self.result = nil
                            selectedImage = nil
                        } label: {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Try Again")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.55, green: 0.45, blue: 0.35))
                            .cornerRadius(14)
                        }
                        .offset(y: showButton ? 0 : 30)
                        .opacity(showButton ? 1.0 : 0)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text(result.isMade ? "Done" : "Cancel")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.55, green: 0.45, blue: 0.35))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(14)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .offset(y: showButton ? 0 : 30)
                    .opacity(showButton ? 1.0 : 0)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
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
        case 9...10: return Color(red: 0.4, green: 0.7, blue: 0.4)
        case 7...8: return Color(red: 0.5, green: 0.7, blue: 0.5)
        case 5...6: return Color(red: 0.8, green: 0.7, blue: 0.4)
        default: return Color(red: 0.85, green: 0.6, blue: 0.4)
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
