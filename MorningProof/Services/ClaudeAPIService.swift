import Foundation
import UIKit

actor ClaudeAPIService {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"

    init(apiKey: String = Config.claudeAPIKey) {
        self.apiKey = apiKey
    }

    func verifyBed(image: UIImage) async throws -> VerificationResult {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw APIError.imageConversionFailed
        }

        let base64Image = imageData.base64EncodedString()

        let requestBody: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": 256,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": """
                            Analyze this photo of a bed. Determine:
                            1. Is the bed made? (yes/no)
                            2. If yes, rate the neatness from 1-10 where:
                               - 1-3: Barely made, still messy
                               - 4-6: Decent effort, some wrinkles/imperfections
                               - 7-9: Well made, neat and tidy
                               - 10: Hotel/military quality, perfect
                            3. Brief feedback (one sentence)

                            Be generous - if someone clearly made an effort, count it as made.
                            If this is not a photo of a bed, respond with is_made: false.

                            Respond ONLY with valid JSON in this exact format:
                            {"is_made": boolean, "score": number, "feedback": "string"}
                            """
                        ]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        // Parse Claude's response
        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }),
              let responseText = textContent.text else {
            throw APIError.parsingFailed
        }

        // Extract JSON from the response (handle potential markdown code blocks)
        let cleanedJSON = extractJSON(from: responseText)
        guard let cleanedData = cleanedJSON.data(using: .utf8) else {
            throw APIError.parsingFailed
        }

        let result = try JSONDecoder().decode(VerificationResult.self, from: cleanedData)
        return result
    }

    private func extractJSON(from text: String) -> String {
        // Remove markdown code blocks if present
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }

        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Response Models

struct ClaudeResponse: Codable {
    let content: [ContentBlock]
}

struct ContentBlock: Codable {
    let type: String
    let text: String?
}

// MARK: - Errors

enum APIError: LocalizedError {
    case imageConversionFailed
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to process image"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .parsingFailed:
            return "Failed to parse response"
        }
    }
}
