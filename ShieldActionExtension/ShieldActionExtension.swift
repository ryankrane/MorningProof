import ManagedSettings
import ManagedSettingsUI

/// Extension that handles button taps on the shield overlay.
/// When the user taps "Open Morning Proof", this defers to allow the system
/// to potentially open the main app (though iOS doesn't guarantee this).
class ShieldActionExtension: ShieldActionDelegate {

    // MARK: - App Shield Actions

    /// Handles button presses on the shield for a blocked application.
    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }

    /// Handles button presses on the shield for a blocked web domain.
    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }

    // MARK: - Helper

    /// Common handler for shield actions.
    /// - `.defer` tells the system to keep the shield in place but allow
    ///   the user to potentially switch apps
    /// - `.close` would close the app entirely
    /// - `.none` keeps the shield and does nothing
    private func handleAction(
        _ action: ShieldAction,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            // "Open Morning Proof" was tapped
            // Defer allows the user to switch to another app (hopefully MorningProof)
            // Note: iOS doesn't have a way to directly open another app from here
            completionHandler(.defer)

        case .secondaryButtonPressed:
            // We don't have a secondary button, but handle it anyway
            completionHandler(.defer)

        @unknown default:
            completionHandler(.defer)
        }
    }
}
