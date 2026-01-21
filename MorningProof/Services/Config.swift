import Foundation

enum Config {
    // Firebase Cloud Functions base URL (set after deploying functions)
    // Format: https://<region>-<project-id>.cloudfunctions.net
    static let firebaseFunctionsBaseURL = Secrets.firebaseFunctionsBaseURL

    // Legacy: Direct Claude API key (only used if Firebase functions not configured)
    static let claudeAPIKey = Secrets.claudeAPIKey
}
