import Foundation
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject, Sendable {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private let notificationCenter = UNUserNotificationCenter.current()

    // Notification identifiers
    private let morningReminderID = "morning_reminder"
    private let countdownWarning15ID = "countdown_15"
    private let countdownWarning5ID = "countdown_5"
    private let countdownWarning1ID = "countdown_1"
    private let cutoffPassedID = "cutoff_passed"

    init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Permission Handling

    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                isAuthorized = granted
            }
            return granted
        } catch {
            MPLogger.error("Notification permission error", error: error, category: MPLogger.notification)
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Schedule Notifications

    func updateNotificationSchedule(settings: MorningProofSettings) async {
        // Cancel all existing notifications first
        await cancelAllNotifications()

        guard settings.notificationsEnabled && isAuthorized else { return }

        // Schedule morning reminder
        await scheduleMorningReminder(at: settings.morningReminderTime)

        // Schedule countdown warnings and cutoff notifications
        if settings.customDeadlinesEnabled {
            // Schedule separate notifications for weekdays and weekends
            await scheduleCountdownWarningsPerDay(
                weekdayMinutes: settings.weekdayDeadlineMinutes,
                weekendMinutes: settings.weekendDeadlineMinutes,
                warnings: settings.countdownWarnings
            )
            await scheduleCutoffPassedPerDay(
                weekdayMinutes: settings.weekdayDeadlineMinutes,
                weekendMinutes: settings.weekendDeadlineMinutes
            )
        } else {
            // Use single cutoff time for all days
            await scheduleCountdownWarnings(
                cutoffMinutes: settings.morningCutoffMinutes,
                warnings: settings.countdownWarnings
            )
            await scheduleCutoffPassed(cutoffMinutes: settings.morningCutoffMinutes)
        }
    }

    func scheduleMorningReminder(at minutes: Int) async {
        let hour = minutes / 60
        let minute = minutes % 60

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Good Morning!"
        content.body = "Time to start your morning routine. Let's make it a great day!"
        content.sound = .default
        content.categoryIdentifier = "MORNING_REMINDER"

        let request = UNNotificationRequest(
            identifier: morningReminderID,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            MPLogger.error("Failed to schedule morning reminder", error: error, category: MPLogger.notification)
        }
    }

    /// Schedules the 15-minute countdown warning notification.
    func scheduleCountdownWarnings(cutoffMinutes: Int, warnings: [Int]) async {
        // Only schedule 15-minute warning (single notification before deadline)
        guard warnings.contains(15) else { return }

        let notificationMinutes = cutoffMinutes - 15
        guard notificationMinutes > 0 else { return }

        let hour = notificationMinutes / 60
        let minute = notificationMinutes % 60

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        content.sound = .default
        content.categoryIdentifier = "COUNTDOWN_WARNING"
        content.title = "15 Minutes Left!"
        content.body = "15 minutes until your morning cutoff. Finish strong!"

        let request = UNNotificationRequest(
            identifier: countdownWarning15ID,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            MPLogger.error("Failed to schedule 15min warning", error: error, category: MPLogger.notification)
        }
    }

    func scheduleCutoffPassed(cutoffMinutes: Int) async {
        let hour = cutoffMinutes / 60
        let minute = cutoffMinutes % 60

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Morning Cutoff Passed"
        content.body = "Keep the streak going tomorrow! Every morning is a fresh start."
        content.sound = .default
        content.categoryIdentifier = "CUTOFF_PASSED"

        let request = UNNotificationRequest(
            identifier: cutoffPassedID,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            MPLogger.error("Failed to schedule cutoff passed notification", error: error, category: MPLogger.notification)
        }
    }

    // MARK: - Per-Day Notifications (Weekday vs Weekend)

    /// Schedules the 15-minute countdown warning with different times for weekdays vs weekends.
    /// Uses dateComponents.weekday to target specific days:
    /// - Weekdays: Mon=2, Tue=3, Wed=4, Thu=5, Fri=6
    /// - Weekends: Sun=1, Sat=7
    func scheduleCountdownWarningsPerDay(weekdayMinutes: Int, weekendMinutes: Int, warnings: [Int]) async {
        // Only schedule 15-minute warning
        guard warnings.contains(15) else { return }

        let content = createCountdownContent(warningMinutes: 15)

        // Schedule weekday warning (Mon-Fri) - 15 minutes before weekday deadline
        let weekdayNotificationMinutes = weekdayMinutes - 15
        if weekdayNotificationMinutes > 0 {
            let hour = weekdayNotificationMinutes / 60
            let minute = weekdayNotificationMinutes % 60

            for weekday in 2...6 {
                var dateComponents = DateComponents()
                dateComponents.weekday = weekday
                dateComponents.hour = hour
                dateComponents.minute = minute

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let identifier = "countdown_15_weekday_\(weekday)"

                let request = UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )

                do {
                    try await notificationCenter.add(request)
                } catch {
                    MPLogger.error("Failed to schedule weekday 15min warning", error: error, category: MPLogger.notification)
                }
            }
        }

        // Schedule weekend warning (Sat=7, Sun=1) - 15 minutes before weekend deadline
        let weekendNotificationMinutes = weekendMinutes - 15
        if weekendNotificationMinutes > 0 {
            let hour = weekendNotificationMinutes / 60
            let minute = weekendNotificationMinutes % 60

            for weekday in [1, 7] {
                var dateComponents = DateComponents()
                dateComponents.weekday = weekday
                dateComponents.hour = hour
                dateComponents.minute = minute

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let identifier = "countdown_15_weekend_\(weekday)"

                let request = UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )

                do {
                    try await notificationCenter.add(request)
                } catch {
                    MPLogger.error("Failed to schedule weekend 15min warning", error: error, category: MPLogger.notification)
                }
            }
        }
    }

    /// Schedules cutoff passed notifications with different times for weekdays vs weekends.
    func scheduleCutoffPassedPerDay(weekdayMinutes: Int, weekendMinutes: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "Morning Cutoff Passed"
        content.body = "Keep the streak going tomorrow! Every morning is a fresh start."
        content.sound = .default
        content.categoryIdentifier = "CUTOFF_PASSED"

        // Schedule for weekdays (Mon=2 through Fri=6)
        let weekdayHour = weekdayMinutes / 60
        let weekdayMinute = weekdayMinutes % 60

        for weekday in 2...6 {
            var dateComponents = DateComponents()
            dateComponents.weekday = weekday
            dateComponents.hour = weekdayHour
            dateComponents.minute = weekdayMinute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let identifier = "\(cutoffPassedID)_weekday_\(weekday)"

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            do {
                try await notificationCenter.add(request)
            } catch {
                MPLogger.error("Failed to schedule weekday cutoff notification", error: error, category: MPLogger.notification)
            }
        }

        // Schedule for weekends (Sat=7, Sun=1)
        let weekendHour = weekendMinutes / 60
        let weekendMinute = weekendMinutes % 60

        for weekday in [1, 7] {
            var dateComponents = DateComponents()
            dateComponents.weekday = weekday
            dateComponents.hour = weekendHour
            dateComponents.minute = weekendMinute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let identifier = "\(cutoffPassedID)_weekend_\(weekday)"

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            do {
                try await notificationCenter.add(request)
            } catch {
                MPLogger.error("Failed to schedule weekend cutoff notification", error: error, category: MPLogger.notification)
            }
        }
    }

    /// Creates content for the 15-minute countdown warning notification.
    private func createCountdownContent(warningMinutes: Int) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.categoryIdentifier = "COUNTDOWN_WARNING"
        content.title = "15 Minutes Left!"
        content.body = "15 minutes until your morning cutoff. Finish strong!"
        return content
    }

    // MARK: - Immediate Notifications

    /// Sends an immediate notification for goal completion.
    /// Used by HealthKitBackgroundDeliveryService when health goals are met.
    func sendImmediateGoalNotification(identifier: String, title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "GOAL_COMPLETE"

        // nil trigger = immediate delivery
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        do {
            try await notificationCenter.add(request)
        } catch {
            MPLogger.error("Failed to send immediate notification", error: error, category: MPLogger.notification)
        }
    }

    // MARK: - Cancel Notifications

    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Helpers

    static func formatTime(minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }

    static let reminderTimeOptions: [(minutes: Int, label: String)] = {
        stride(from: 300, through: 720, by: 30).map { mins in
            (mins, formatTime(minutes: mins))
        }
    }()

    static let gracePeriodOptions: [(minutes: Int, label: String)] = [
        (5, "5 minutes"),
        (10, "10 minutes"),
        (15, "15 minutes"),
        (30, "30 minutes")
    ]
}
