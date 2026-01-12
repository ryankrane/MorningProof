import Foundation
import FirebaseCrashlytics

/// Service for crash reporting and analytics via Firebase Crashlytics
@MainActor
class CrashReportingService {
    static let shared = CrashReportingService()

    private init() {}

    // MARK: - User Identification

    /// Set user identifier for crash reports (use anonymous ID, not PII)
    func setUserID(_ userID: String) {
        Crashlytics.crashlytics().setUserID(userID)
    }

    // MARK: - Custom Keys (for debugging context)

    /// Set a custom key-value pair for crash reports
    func setCustomValue(_ value: Any, forKey key: String) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }

    /// Set current streak for crash context
    func setCurrentStreak(_ streak: Int) {
        setCustomValue(streak, forKey: "current_streak")
    }

    /// Set current screen for crash context
    func setCurrentScreen(_ screen: String) {
        setCustomValue(screen, forKey: "current_screen")
    }

    /// Set habit count for crash context
    func setEnabledHabitCount(_ count: Int) {
        setCustomValue(count, forKey: "enabled_habits")
    }

    // MARK: - Breadcrumbs (Log messages for crash context)

    /// Log a breadcrumb message that will appear in crash reports
    func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }

    /// Log habit completion event
    func logHabitCompleted(_ habitType: String) {
        log("Habit completed: \(habitType)")
    }

    /// Log API call
    func logAPICall(_ endpoint: String) {
        log("API call: \(endpoint)")
    }

    /// Log navigation event
    func logNavigation(to screen: String) {
        log("Navigated to: \(screen)")
        setCurrentScreen(screen)
    }

    // MARK: - Non-Fatal Error Reporting

    /// Record a non-fatal error (e.g., API errors, validation failures)
    func recordError(_ error: Error, userInfo: [String: Any]? = nil) {
        var info = userInfo ?? [:]
        info["timestamp"] = Date().ISO8601Format()

        Crashlytics.crashlytics().record(error: error, userInfo: info)
    }

    /// Record an API error with context
    func recordAPIError(_ error: Error, endpoint: String, statusCode: Int? = nil) {
        var userInfo: [String: Any] = [
            "endpoint": endpoint,
            "timestamp": Date().ISO8601Format()
        ]
        if let code = statusCode {
            userInfo["status_code"] = code
        }
        recordError(error, userInfo: userInfo)
    }

    /// Record a custom error with message
    func recordCustomError(_ message: String, code: Int = -1, domain: String = "com.rk.morningproof") {
        let error = NSError(domain: domain, code: code, userInfo: [
            NSLocalizedDescriptionKey: message
        ])
        recordError(error)
    }

    // MARK: - Crash Testing (Debug only)

    #if DEBUG
    /// Force a crash for testing (DEBUG ONLY)
    func forceCrash() {
        fatalError("Test crash triggered")
    }
    #endif
}

// MARK: - Custom Error Types for Crash Reporting

enum MorningProofError: LocalizedError {
    case apiError(String)
    case verificationFailed(String)
    case healthKitError(String)
    case storageError(String)
    case authenticationError(String)
    case subscriptionError(String)

    var errorDescription: String? {
        switch self {
        case .apiError(let message): return "API Error: \(message)"
        case .verificationFailed(let message): return "Verification Failed: \(message)"
        case .healthKitError(let message): return "HealthKit Error: \(message)"
        case .storageError(let message): return "Storage Error: \(message)"
        case .authenticationError(let message): return "Auth Error: \(message)"
        case .subscriptionError(let message): return "Subscription Error: \(message)"
        }
    }
}
