import Foundation

struct VerificationResult: Codable {
    let isMade: Bool
    let feedback: String

    enum CodingKeys: String, CodingKey {
        case isMade = "is_made"
        case feedback
    }
}

struct SunlightVerificationResult: Codable {
    let isOutside: Bool
    let feedback: String

    enum CodingKeys: String, CodingKey {
        case isOutside = "is_outside"
        case feedback
    }
}

struct HydrationVerificationResult: Codable {
    let isWater: Bool
    let feedback: String

    enum CodingKeys: String, CodingKey {
        case isWater = "is_water"
        case feedback
    }
}
