import Foundation

struct VerificationResult: Codable {
    let isMade: Bool
    let feedback: String
    let detectedSubject: String?

    enum CodingKeys: String, CodingKey {
        case isMade = "is_made"
        case feedback
        case detectedSubject = "detected_subject"
    }

    init(isMade: Bool, feedback: String, detectedSubject: String? = nil) {
        self.isMade = isMade
        self.feedback = feedback
        self.detectedSubject = detectedSubject
    }
}

struct SunlightVerificationResult: Codable {
    let isOutside: Bool
    let feedback: String
    let detectedSubject: String?

    enum CodingKeys: String, CodingKey {
        case isOutside = "is_outside"
        case feedback
        case detectedSubject = "detected_subject"
    }

    init(isOutside: Bool, feedback: String, detectedSubject: String? = nil) {
        self.isOutside = isOutside
        self.feedback = feedback
        self.detectedSubject = detectedSubject
    }
}

struct HydrationVerificationResult: Codable {
    let isWater: Bool
    let feedback: String
    let detectedSubject: String?

    enum CodingKeys: String, CodingKey {
        case isWater = "is_water"
        case feedback
        case detectedSubject = "detected_subject"
    }

    init(isWater: Bool, feedback: String, detectedSubject: String? = nil) {
        self.isWater = isWater
        self.feedback = feedback
        self.detectedSubject = detectedSubject
    }
}

struct CustomVerificationResult: Codable {
    let isVerified: Bool
    let feedback: String
    let detectedSubject: String?

    enum CodingKeys: String, CodingKey {
        case isVerified = "is_verified"
        case feedback
        case detectedSubject = "detected_subject"
    }

    init(isVerified: Bool, feedback: String, detectedSubject: String? = nil) {
        self.isVerified = isVerified
        self.feedback = feedback
        self.detectedSubject = detectedSubject
    }
}
