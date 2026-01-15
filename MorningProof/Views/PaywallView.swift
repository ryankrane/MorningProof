import SwiftUI
import SuperwallKit

/// PaywallView that triggers Superwall's paywall
/// Used from settings and other places in the app
struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @State private var hasTriggeredPaywall = false

    var body: some View {
        // Loading screen while Superwall presents the paywall
        ZStack {
            MPColors.background
                .ignoresSafeArea()

            VStack(spacing: MPSpacing.xxl) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(MPColors.accentLight)
                        .frame(width: 100, height: 100)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 44))
                        .foregroundColor(MPColors.accent)
                }

                VStack(spacing: MPSpacing.md) {
                    Text("Unlock Premium")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(MPColors.textPrimary)

                    Text("Loading your offer...")
                        .font(.system(size: 16))
                        .foregroundColor(MPColors.textSecondary)
                }

                ProgressView()
                    .scaleEffect(1.2)
                    .tint(MPColors.accent)

                Spacer()
            }
        }
        .onAppear {
            guard !hasTriggeredPaywall else { return }
            hasTriggeredPaywall = true

            // Trigger Superwall paywall for settings
            SuperwallService.shared.register(
                event: SuperwallEvent.settingsPaywall,
                onSkip: {
                    dismiss()
                },
                onPurchase: {
                    dismiss()
                },
                onRestore: {
                    dismiss()
                }
            )
        }
    }
}

#Preview {
    PaywallView()
}
