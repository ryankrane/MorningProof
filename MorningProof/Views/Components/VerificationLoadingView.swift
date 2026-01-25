import SwiftUI

/// Clean AI verification loading view with native components
struct VerificationLoadingView: View {
    let image: UIImage
    let accentColor: Color
    let statusText: String

    var body: some View {
        VStack(spacing: MPSpacing.xxl) {
            Spacer()

            // Clean photo
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 350)
                .cornerRadius(MPRadius.xl)
                .mpShadow(.medium)
                .padding(.horizontal, MPSpacing.xxl)

            // Native loading indicator
            VStack(spacing: MPSpacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(accentColor)

                Text("Analyzing...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(MPColors.textTertiary)
            }

            Spacer()
        }
    }
}

#Preview {
    ZStack {
        MPColors.background
            .ignoresSafeArea()

        VerificationLoadingView(
            image: UIImage(systemName: "bed.double.fill")!,
            accentColor: MPColors.accent,
            statusText: "Verifying..."
        )
    }
}
