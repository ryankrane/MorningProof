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
                Circle()
                    .fill(Color.white)
                    .frame(width: 140, height: 140)
                    .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)

                Image(systemName: "bed.double.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color(red: 0.75, green: 0.65, blue: 0.55))
            }

            VStack(spacing: 12) {
                Text("Analyzing your bed...")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                Text("AI is checking if it's made")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
            }

            ProgressView()
                .scaleEffect(1.3)
                .tint(Color(red: 0.55, green: 0.45, blue: 0.35))

            Spacer()
        }
    }

    func resultView(_ result: VerificationResult) -> some View {
        VStack(spacing: 24) {
            Spacer()

            if result.isMade {
                // Success
                ZStack {
                    Circle()
                        .fill(Color(red: 0.9, green: 0.97, blue: 0.9))
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(Color(red: 0.55, green: 0.75, blue: 0.55))
                }

                Text("Bed Verified!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                // Score
                VStack(spacing: 8) {
                    Text("Score")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(result.score)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(scoreColor(result.score))
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

                Text(result.feedback)
                    .font(.body)
                    .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
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

                Text("Not Quite...")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                Text(result.feedback)
                    .font(.body)
                    .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 12) {
                if !result.isMade {
                    Button {
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
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
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
