import SwiftUI

/// A clean, minimal loading view for AI verification
/// Apple-like design: photo + simple spinner + status text
struct VerificationLoadingView: View {
    let image: UIImage
    let accentColor: Color
    let statusText: String

    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: MPSpacing.xl) {
            Spacer()

            // Photo - clean, no effects
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 350)
                .cornerRadius(MPRadius.xl)
                .mpShadow(.medium)
                .padding(.horizontal, MPSpacing.xxl)

            // Spinner + text
            VStack(spacing: MPSpacing.md) {
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(rotation))

                Text(statusText)
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textTertiary)
            }

            Spacer()
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
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
