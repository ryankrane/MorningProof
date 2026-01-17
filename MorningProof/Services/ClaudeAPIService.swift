import Foundation
import UIKit

actor ClaudeAPIService {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"

    init(apiKey: String = Config.claudeAPIKey) {
        self.apiKey = apiKey
    }

    func verifyBed(image: UIImage) async throws -> VerificationResult {
        await MainActor.run {
            CrashReportingService.shared.logAPICall("claude/verify-bed")
        }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            let error = APIError.imageConversionFailed
            await MainActor.run {
                CrashReportingService.shared.recordAPIError(error, endpoint: "claude/verify-bed")
            }
            throw error
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
                            Analyze this photo of a bed. Is it made?

                            Pass if: The covers/blankets are pulled up and the bed looks roughly made. It doesn't need to be perfect - wrinkles and imperfections are fine.
                            Fail if: The bed is clearly unmade with messy/bunched sheets, exposed mattress, or no attempt was made.

                            If this is not a photo of a bed, respond with is_made: false.

                            Respond ONLY with valid JSON:
                            {"is_made": boolean, "feedback": "brief encouraging message"}
                            """
                        ]
                    ]
                ]
            ]
        ]

        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
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
            let error = APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
            await MainActor.run {
                CrashReportingService.shared.recordAPIError(error, endpoint: "claude/verify-bed", statusCode: httpResponse.statusCode)
            }
            throw error
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

    func verifySunlight(image: UIImage) async throws -> SunlightVerificationResult {
        await MainActor.run {
            CrashReportingService.shared.logAPICall("claude/verify-sunlight")
        }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            let error = APIError.imageConversionFailed
            await MainActor.run {
                CrashReportingService.shared.recordAPIError(error, endpoint: "claude/verify-sunlight")
            }
            throw error
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
                            Analyze this photo for natural light exposure.

                            Pass if ANY of these are true:
                            - Photo is taken outdoors (any weather)
                            - Natural daylight is visible through windows
                            - Sky, trees, or outdoor elements are visible
                            - Any natural light is present

                            Be very generous - overcast, cloudy, through a window, any hint of natural light counts.

                            Only fail if it's clearly nighttime or a dark indoor space with no natural light.

                            Respond ONLY with valid JSON:
                            {"is_outside": boolean, "feedback": "brief encouraging message"}
                            """
                        ]
                    ]
                ]
            ]
        ]

        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
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
            let error = APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
            await MainActor.run {
                CrashReportingService.shared.recordAPIError(error, endpoint: "claude/verify-sunlight", statusCode: httpResponse.statusCode)
            }
            throw error
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }),
              let responseText = textContent.text else {
            throw APIError.parsingFailed
        }

        let cleanedJSON = extractJSON(from: responseText)
        guard let cleanedData = cleanedJSON.data(using: .utf8) else {
            throw APIError.parsingFailed
        }

        let result = try JSONDecoder().decode(SunlightVerificationResult.self, from: cleanedData)
        return result
    }

    func verifyHydration(image: UIImage) async throws -> HydrationVerificationResult {
        await MainActor.run {
            CrashReportingService.shared.logAPICall("claude/verify-hydration")
        }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            let error = APIError.imageConversionFailed
            await MainActor.run {
                CrashReportingService.shared.recordAPIError(error, endpoint: "claude/verify-hydration")
            }
            throw error
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
                            Analyze this photo to verify morning hydration.

                            Pass if the photo shows ANY beverage:
                            - Water, coffee, tea, juice, smoothie, protein shake
                            - Any cup, glass, mug, bottle, or tumbler with liquid
                            - Person drinking anything

                            Be very generous - any drink counts for morning hydration.

                            Respond ONLY with valid JSON:
                            {"is_water": boolean, "feedback": "brief encouraging message"}
                            """
                        ]
                    ]
                ]
            ]
        ]

        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
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
            let error = APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
            await MainActor.run {
                CrashReportingService.shared.recordAPIError(error, endpoint: "claude/verify-hydration", statusCode: httpResponse.statusCode)
            }
            throw error
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }),
              let responseText = textContent.text else {
            throw APIError.parsingFailed
        }

        let cleanedJSON = extractJSON(from: responseText)
        guard let cleanedData = cleanedJSON.data(using: .utf8) else {
            throw APIError.parsingFailed
        }

        let result = try JSONDecoder().decode(HydrationVerificationResult.self, from: cleanedData)
        return result
    }

    func verifyCustomHabit(image: UIImage, customHabit: CustomHabit) async throws -> CustomVerificationResult {
        await MainActor.run {
            CrashReportingService.shared.logAPICall("claude/verify-custom-habit")
        }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            let error = APIError.imageConversionFailed
            await MainActor.run {
                CrashReportingService.shared.recordAPIError(error, endpoint: "claude/verify-custom-habit")
            }
            throw error
        }

        let base64Image = imageData.base64EncodedString()

        // Build the prompt based on user's AI instructions
        let userCriteria = customHabit.aiPrompt ?? "Verify that this habit has been completed."
        let prompt = """
            You are verifying a morning habit.
            Habit: \(customHabit.name)
            User's verification criteria: \(userCriteria)

            Analyze the photo and determine if it meets the user's criteria.
            Be reasonably generous - if there's genuine effort, pass it.

            Respond ONLY with valid JSON:
            {"is_verified": boolean, "feedback": "brief encouraging message"}
            """

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
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]

        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
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
            let error = APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
            await MainActor.run {
                CrashReportingService.shared.recordAPIError(error, endpoint: "claude/verify-custom-habit", statusCode: httpResponse.statusCode)
            }
            throw error
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }),
              let responseText = textContent.text else {
            throw APIError.parsingFailed
        }

        let cleanedJSON = extractJSON(from: responseText)
        guard let cleanedData = cleanedJSON.data(using: .utf8) else {
            throw APIError.parsingFailed
        }

        let result = try JSONDecoder().decode(CustomVerificationResult.self, from: cleanedData)
        return result
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
    case invalidURL
    case imageConversionFailed
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL configuration"
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
