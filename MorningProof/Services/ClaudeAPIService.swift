import Foundation
import UIKit

actor ClaudeAPIService {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let maxImageBytes = 4_500_000 // Stay under 5MB API limit with some buffer

    init(apiKey: String = Config.claudeAPIKey) {
        self.apiKey = apiKey
    }

    /// Compresses and resizes image to stay under the API size limit
    private func prepareImageData(_ image: UIImage) throws -> Data {
        // Start with the original image, resize if very large
        var workingImage = image
        let maxDimension: CGFloat = 2048

        if image.size.width > maxDimension || image.size.height > maxDimension {
            let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            if let resized = UIGraphicsGetImageFromCurrentImageContext() {
                workingImage = resized
            }
            UIGraphicsEndImageContext()
        }

        // Try progressively lower compression until under size limit
        let compressionLevels: [CGFloat] = [0.7, 0.5, 0.3, 0.2]

        for quality in compressionLevels {
            if let data = workingImage.jpegData(compressionQuality: quality),
               data.count <= maxImageBytes {
                return data
            }
        }

        // Last resort: resize smaller and compress heavily
        let smallScale: CGFloat = 0.5
        let smallSize = CGSize(width: workingImage.size.width * smallScale, height: workingImage.size.height * smallScale)
        UIGraphicsBeginImageContextWithOptions(smallSize, false, 1.0)
        workingImage.draw(in: CGRect(origin: .zero, size: smallSize))
        if let smallImage = UIGraphicsGetImageFromCurrentImageContext(),
           let data = smallImage.jpegData(compressionQuality: 0.3) {
            UIGraphicsEndImageContext()
            return data
        }
        UIGraphicsEndImageContext()

        throw APIError.imageConversionFailed
    }

    func verifyBed(image: UIImage) async throws -> VerificationResult {
        await MainActor.run {
            CrashReportingService.shared.logAPICall("claude/verify-bed")
        }

        let imageData: Data
        do {
            imageData = try prepareImageData(image)
        } catch {
            await MainActor.run {
                CrashReportingService.shared.recordAPIError(APIError.imageConversionFailed, endpoint: "claude/verify-bed")
            }
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

        let imageData: Data
        do {
            imageData = try prepareImageData(image)
        } catch {
            await MainActor.run {
                CrashReportingService.shared.recordAPIError(APIError.imageConversionFailed, endpoint: "claude/verify-sunlight")
            }
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

        let imageData: Data
        do {
            imageData = try prepareImageData(image)
        } catch {
            await MainActor.run {
                CrashReportingService.shared.recordAPIError(APIError.imageConversionFailed, endpoint: "claude/verify-hydration")
            }
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

        let imageData: Data
        do {
            imageData = try prepareImageData(image)
        } catch {
            await MainActor.run {
                CrashReportingService.shared.recordAPIError(APIError.imageConversionFailed, endpoint: "claude/verify-custom-habit")
            }
            throw APIError.imageConversionFailed
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
            return "Something went wrong. Please try again."
        case .imageConversionFailed:
            return "Couldn't process your photo. Please try again."
        case .invalidResponse:
            return "Couldn't connect to the server. Please check your connection and try again."
        case .serverError(let code, _):
            // Return user-friendly messages based on status code
            switch code {
            case 400:
                return "Couldn't process your photo. Please try taking another one."
            case 401, 403:
                return "Authentication error. Please restart the app and try again."
            case 429:
                return "Too many requests. Please wait a moment and try again."
            case 500...599:
                return "Server is temporarily unavailable. Please try again later."
            default:
                return "Something went wrong. Please try again."
            }
        case .parsingFailed:
            return "Couldn't understand the response. Please try again."
        }
    }
}
