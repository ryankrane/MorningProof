import ManagedSettings
import ManagedSettingsUI
import UIKit
import os.log

private let logger = Logger(subsystem: "com.rk.morningproof.shieldconfig", category: "ShieldConfiguration")

/// Extension that customizes the appearance of the blocking shield overlay.
/// This is shown when a user tries to open a blocked app.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override init() {
        super.init()
        logger.info("🛡️ ShieldConfigurationExtension: INITIALIZED - Extension is loading!")
    }

    // MARK: - App Shield Configuration

    /// Returns the shield configuration for a blocked application.
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        logger.info("🛡️ ShieldConfigurationExtension: configuration(shielding application:) called")
        return createShieldConfiguration()
    }

    /// Returns the shield configuration for a blocked application in a category.
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        logger.info("🛡️ ShieldConfigurationExtension: configuration(shielding application: in category:) called")
        return createShieldConfiguration()
    }

    /// Returns the shield configuration for a blocked web domain.
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        logger.info("🛡️ ShieldConfigurationExtension: configuration(shielding webDomain:) called")
        return createShieldConfiguration(isWeb: true)
    }

    /// Returns the shield configuration for a blocked web domain in a category.
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        logger.info("🛡️ ShieldConfigurationExtension: configuration(shielding webDomain: in category:) called")
        return createShieldConfiguration(isWeb: true)
    }

    // MARK: - Helper

    /// Creates the shield configuration with MorningProof branding.
    private func createShieldConfiguration(isWeb: Bool = false) -> ShieldConfiguration {
        logger.info("🛡️ createShieldConfiguration called, isWeb: \(isWeb)")

        // Production version - using Morning Proof brand purple
        let brandPurple = UIColor(red: 0.55, green: 0.45, blue: 0.75, alpha: 1.0)

        return ShieldConfiguration(
            backgroundBlurStyle: .systemThickMaterial,
            backgroundColor: brandPurple,
            icon: UIImage(systemName: "sunrise.fill"),
            title: ShieldConfiguration.Label(
                text: isWeb ? "Website Blocked" : "App Blocked",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Complete your morning routine to unlock",
                color: .white
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Morning Proof",
                color: .black
            ),
            primaryButtonBackgroundColor: .white,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Emergency Unlock",
                color: .systemRed
            )
        )
    }
}
