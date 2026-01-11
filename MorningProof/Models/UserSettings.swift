import Foundation

struct UserSettings: Codable {
    var deadlineHour: Int
    var deadlineMinute: Int
    var userName: String

    init() {
        self.deadlineHour = 9
        self.deadlineMinute = 0
        self.userName = ""
    }

    var deadlineTime: Date {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = deadlineHour
        components.minute = deadlineMinute
        return calendar.date(from: components) ?? now
    }

    var timeUntilDeadline: TimeInterval {
        let deadline = deadlineTime
        let now = Date()

        if now > deadline {
            // Deadline passed today, show time until tomorrow's deadline
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: deadline)!
            return tomorrow.timeIntervalSince(now)
        }
        return deadline.timeIntervalSince(now)
    }

    var deadlinePassed: Bool {
        Date() > deadlineTime
    }
}
