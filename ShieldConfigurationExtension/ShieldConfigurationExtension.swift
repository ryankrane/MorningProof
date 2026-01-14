import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Extension that customizes the appearance of the blocking shield overlay.
/// This is shown when a user tries to open a blocked app.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    // MARK: - App Shield Configuration

    /// Returns the shield configuration for a blocked application.
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        createShieldConfiguration()
    }

    /// Returns the shield configuration for a blocked application in a category.
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        createShieldConfiguration()
    }

    /// Returns the shield configuration for a blocked web domain.
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        createShieldConfiguration(isWeb: true)
    }

    /// Returns the shield configuration for a blocked web domain in a category.
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        createShieldConfiguration(isWeb: true)
    }

    // MARK: - Helper

    /// Creates the shield configuration with MorningProof branding.
    private func createShieldConfiguration(isWeb: Bool = false) -> ShieldConfiguration {
        // Use system colors that adapt to light/dark mode
        let primaryColor = UIColor.systemBlue

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(systemName: "sunrise.fill"),
            title: ShieldConfiguration.Label(
                text: isWeb ? "Website Blocked" : "App Blocked",
                color: .label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Complete your morning habits to unlock",
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Morning Proof",
                color: .white
            ),
            primaryButtonBackgroundColor: primaryColor,
            // Emergency unlock option - breaks streak but allows access
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Emergency Unlock",
                color: .systemRed
            )
        )
    }
}
