import SwiftUI

/// Placeholder view for video verification of custom habits
/// TODO: Implement full video verification flow
struct VideoVerificationView: View {
    @ObservedObject var manager: MorningProofManager
    @Environment(\.dismiss) var dismiss

    let customHabit: CustomHabit

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                VStack(spacing: MPSpacing.xl) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 60))
                        .foregroundColor(MPColors.textTertiary)

                    Text("Video Verification")
                        .font(MPFont.headingMedium())
                        .foregroundColor(MPColors.textPrimary)

                    Text("Video verification for \(customHabit.name) coming soon.")
                        .font(MPFont.bodyMedium())
                        .foregroundColor(MPColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, MPSpacing.xl)
                }
            }
            .navigationTitle("Verify \(customHabit.name)")
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
    }
}
