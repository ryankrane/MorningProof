import Foundation
import os.log

// MARK: - MorningProof Logger
// iOS Only - Production-ready logging utility
// Uses Apple's unified logging system (os.log) for efficient, privacy-aware logging

enum MPLogger {
    private static let subsystem = "com.rk.morningproof"

    // MARK: - Category-specific Loggers
    static let subscription = os.Logger(subsystem: subsystem, category: "subscription")
    static let notification = os.Logger(subsystem: subsystem, category: "notification")
    static let migration = os.Logger(subsystem: subsystem, category: "migration")
    static let healthKit = os.Logger(subsystem: subsystem, category: "healthkit")
    static let liveActivity = os.Logger(subsystem: subsystem, category: "liveactivity")
    static let api = os.Logger(subsystem: subsystem, category: "api")
    static let storage = os.Logger(subsystem: subsystem, category: "storage")
    static let screenTime = os.Logger(subsystem: subsystem, category: "screentime")
    static let general = os.Logger(subsystem: subsystem, category: "general")

    // MARK: - Convenience Methods

    /// Log debug message (only in DEBUG builds)
    static func debug(_ message: String, category: os.Logger = general) {
        #if DEBUG
        category.debug("\(message, privacy: .public)")
        #endif
    }

    /// Log info message
    static func info(_ message: String, category: os.Logger = general) {
        category.info("\(message, privacy: .public)")
    }

    /// Log warning message
    static func warning(_ message: String, category: os.Logger = general) {
        category.warning("\(message, privacy: .public)")
    }

    /// Log error message
    static func error(_ message: String, category: os.Logger = general) {
        category.error("\(message, privacy: .public)")
    }

    /// Log error with Error object
    static func error(_ message: String, error: Error, category: os.Logger = general) {
        category.error("\(message, privacy: .public): \(error.localizedDescription, privacy: .public)")
    }
}
