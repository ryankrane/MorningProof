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

        // Schedule countdown warnings
        await scheduleCountdownWarnings(
            cutoffMinutes: settings.morningCutoffMinutes,
            warnings: settings.countdownWarnings
        )

        // Schedule cutoff passed notification
        await scheduleCutoffPassed(cutoffMinutes: settings.morningCutoffMinutes)
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

    func scheduleCountdownWarnings(cutoffMinutes: Int, warnings: [Int]) async {
        for warningMinutes in warnings {
            let notificationMinutes = cutoffMinutes - warningMinutes
            guard notificationMinutes > 0 else { continue }

            let hour = notificationMinutes / 60
            let minute = notificationMinutes % 60

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            let content = UNMutableNotificationContent()
            content.sound = .default
            content.categoryIdentifier = "COUNTDOWN_WARNING"

            switch warningMinutes {
            case 15:
                content.title = "15 Minutes Left!"
                content.body = "15 minutes until your morning cutoff. Finish strong!"
            case 5:
                content.title = "5 Minutes Left!"
                content.body = "Only 5 minutes to complete your habits!"
            case 1:
                content.title = "Last Minute!"
                content.body = "1 minute left! Finish your morning routine now!"
            default:
                content.title = "\(warningMinutes) Minutes Left"
                content.body = "\(warningMinutes) minutes until your morning cutoff."
            }

            let identifier: String
            switch warningMinutes {
            case 15: identifier = countdownWarning15ID
            case 5: identifier = countdownWarning5ID
            case 1: identifier = countdownWarning1ID
            default: identifier = "countdown_\(warningMinutes)"
            }

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            do {
                try await notificationCenter.add(request)
            } catch {
                MPLogger.error("Failed to schedule \(warningMinutes)min warning", error: error, category: MPLogger.notification)
            }
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
