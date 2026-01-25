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
        // MorningProof brand purple color (matches app theme)
        let brandPurple = UIColor(red: 0.55, green: 0.45, blue: 0.75, alpha: 1.0)

        // Load app icon from extension's asset catalog
        let appIcon = UIImage(named: "ShieldIcon")

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: appIcon,
            title: ShieldConfiguration.Label(
                text: isWeb ? "Website Blocked" : "App Blocked",
                color: .label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Complete your morning routine to unlock",
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Morning Proof",
                color: .white
            ),
            primaryButtonBackgroundColor: brandPurple,
            // Emergency unlock option - breaks streak but allows access
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Emergency Unlock",
                color: .systemRed
            )
        )
    }
}
