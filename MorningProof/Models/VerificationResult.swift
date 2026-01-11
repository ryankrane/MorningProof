import Foundation

struct VerificationResult: Codable {
    let isMade: Bool
    let score: Int
    let feedback: String

    enum CodingKeys: String, CodingKey {
        case isMade = "is_made"
        case score
        case feedback
    }
}
