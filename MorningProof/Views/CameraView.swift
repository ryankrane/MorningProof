import SwiftUI
import PhotosUI

struct CameraView: View {
    @EnvironmentObject var viewModel: BedVerificationViewModel
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?

    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.96, blue: 0.93)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                HStack {
                    Button {
                        viewModel.goHome()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Cancel")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.35))
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)

                Text("Take a photo of your bed")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                Spacer()

                // Image preview or placeholder
                if let image = selectedImage {
                    VStack(spacing: 20) {
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
                                viewModel.verifyBed(image: image)
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
                    }
                } else {
                    VStack(spacing: 24) {
                        // Placeholder card
                        VStack(spacing: 20) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 80))
                                .foregroundColor(Color(red: 0.8, green: 0.75, blue: 0.7))

                            Text("Capture your made bed")
                                .font(.subheadline)
                                .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
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
            .padding(.top)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
        }
        .swipeBack { viewModel.goHome() }
    }
}

#Preview {
    CameraView()
        .environmentObject(BedVerificationViewModel())
}
