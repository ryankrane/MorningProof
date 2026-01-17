import Foundation

// MARK: - Unified Habit Identifier

/// Unified identifier for any habit (predefined or custom)
enum HabitIdentifier: Codable, Hashable, Identifiable {
    case predefined(HabitType)
    case custom(id: UUID)

    var id: String {
        switch self {
        case .predefined(let type):
            return "predefined_\(type.rawValue)"
        case .custom(let uuid):
            return "custom_\(uuid.uuidString)"
        }
    }

    var isPredefined: Bool {
        if case .predefined = self { return true }
        return false
    }

    var isCustom: Bool {
        if case .custom = self { return true }
        return false
    }

    var predefinedType: HabitType? {
        if case .predefined(let type) = self { return type }
        return nil
    }

    var customId: UUID? {
        if case .custom(let id) = self { return id }
        return nil
    }
}

// MARK: - Custom Verification Type

/// How a custom habit is verified
enum CustomVerificationType: String, Codable, CaseIterable {
    case aiVerified = "ai_verified"
    case honorSystem = "honor_system"

    var displayName: String {
        switch self {
        case .aiVerified: return "Photo Verified"
        case .honorSystem: return "Hold to Confirm"
        }
    }

    var description: String {
        switch self {
        case .aiVerified: return "Take a photo and AI verifies completion"
        case .honorSystem: return "Hold to confirm you completed the habit"
        }
    }

    var icon: String {
        switch self {
        case .aiVerified: return "camera.fill"
        case .honorSystem: return "hand.tap.fill"
        }
    }
}

// MARK: - Custom Habit

/// User-created custom habit definition
struct CustomHabit: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var icon: String          // SF Symbol name
    var verificationType: CustomVerificationType
    var aiPrompt: String?     // User's verification instructions (for AI verified)
    var createdAt: Date
    var isActive: Bool
    var activeDays: Set<Int>  // 1=Sunday...7=Saturday (matches Calendar.weekday)

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        verificationType: CustomVerificationType,
        aiPrompt: String? = nil,
        createdAt: Date = Date(),
        isActive: Bool = true,
        activeDays: Set<Int>? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.verificationType = verificationType
        self.aiPrompt = aiPrompt
        self.createdAt = createdAt
        self.isActive = isActive
        self.activeDays = activeDays ?? Set(1...7) // Default to all days
    }

    // Custom decoder for backward compatibility (existing users get all days)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        verificationType = try container.decode(CustomVerificationType.self, forKey: .verificationType)
        aiPrompt = try container.decodeIfPresent(String.self, forKey: .aiPrompt)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        activeDays = try container.decodeIfPresent(Set<Int>.self, forKey: .activeDays) ?? Set(1...7)
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, icon, verificationType, aiPrompt, createdAt, isActive, activeDays
    }

    /// Convert to HabitIdentifier
    var identifier: HabitIdentifier {
        .custom(id: id)
    }

    /// Static list of curated icons for the picker
    static let availableIcons: [String] = [
        "star.fill",
        "heart.fill",
        "bolt.fill",
        "leaf.fill",
        "flame.fill",
        "book.fill",
        "pencil",
        "lightbulb.fill",
        "cup.and.saucer.fill",
        "pill.fill",
        "dumbbell.fill",
        "figure.run",
        "brain.head.profile",
        "eye.fill",
        "moon.fill"
    ]
}

// MARK: - Custom Habit Config

/// Configuration for a custom habit (mirrors HabitConfig structure)
struct CustomHabitConfig: Codable, Identifiable {
    var id: UUID
    var customHabitId: UUID
    var isEnabled: Bool
    var displayOrder: Int

    init(customHabitId: UUID, isEnabled: Bool = true, displayOrder: Int = 0) {
        self.id = UUID()
        self.customHabitId = customHabitId
        self.isEnabled = isEnabled
        self.displayOrder = displayOrder
    }
}

// MARK: - Custom Habit Completion

/// A single custom habit completion record
struct CustomHabitCompletion: Codable, Identifiable {
    var id: UUID
    var customHabitId: UUID
    var date: Date
    var isCompleted: Bool
    var verificationData: VerificationData?
    var completedAt: Date?

    struct VerificationData: Codable {
        var photoURL: String?
        var aiFeedback: String?
    }

    init(customHabitId: UUID, date: Date = Date()) {
        self.id = UUID()
        self.customHabitId = customHabitId
        self.date = Calendar.current.startOfDay(for: date)
        self.isCompleted = false
        self.verificationData = nil
        self.completedAt = nil
    }
}
