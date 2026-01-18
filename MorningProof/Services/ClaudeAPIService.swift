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
                            TASK: Verify if this photo shows a MADE BED.

                            STEP 1 - CRITICAL: First, check if this photo actually contains a bed.
                            A bed must have: a mattress, bedding (sheets/blankets/comforter), and typically a headboard or bed frame.
                            If you do NOT see a bed in this photo, respond with is_made: false and feedback explaining no bed was found.
                            Furniture like couches, chairs, bookcases, desks, or other non-bed items do NOT count.

                            STEP 2 - Only if a bed IS present: Check if it's made.
                            Pass if: Covers/blankets are pulled up and the bed looks roughly tidy. Wrinkles are fine.
                            Fail if: Sheets are bunched/messy, mattress is exposed, or no attempt was made to make it.

                            Respond ONLY with valid JSON:
                            {"is_made": boolean, "feedback": "brief message"}
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

        // Decode the response with robust error handling
        return try await decodeVerificationResult(VerificationResult.self, from: responseText, endpoint: "claude/verify-bed")
    }

    private func extractJSON(from text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove markdown code blocks if present
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }

        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }

        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        // If it already looks like JSON, return it
        if cleaned.hasPrefix("{") && cleaned.hasSuffix("}") {
            return cleaned
        }

        // Try to find JSON object anywhere in the response using regex
        if let range = cleaned.range(of: "\\{[^{}]*\\}", options: .regularExpression) {
            return String(cleaned[range])
        }

        // Last resort: look for JSON with nested braces
        if let startIndex = cleaned.firstIndex(of: "{"),
           let endIndex = cleaned.lastIndex(of: "}") {
            return String(cleaned[startIndex...endIndex])
        }

        return cleaned
    }

    private func decodeVerificationResult<T: Decodable>(_ type: T.Type, from text: String, endpoint: String) async throws -> T {
        let cleanedJSON = extractJSON(from: text)

        guard let cleanedData = cleanedJSON.data(using: .utf8) else {
            await MainActor.run {
                CrashReportingService.shared.recordError(
                    NSError(domain: "ClaudeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert response to data"]),
                    userInfo: ["endpoint": endpoint, "response": String(text.prefix(500))]
                )
            }
            throw APIError.parsingFailed
        }

        do {
            return try JSONDecoder().decode(type, from: cleanedData)
        } catch {
            // Log the actual response for debugging
            await MainActor.run {
                CrashReportingService.shared.recordError(
                    error,
                    userInfo: ["endpoint": endpoint, "cleanedJSON": String(cleanedJSON.prefix(500)), "originalResponse": String(text.prefix(500))]
                )
            }
            throw APIError.parsingFailed
        }
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
                            TASK: Verify this photo shows NATURAL LIGHT exposure.

                            STEP 1 - CRITICAL: Verify this photo shows natural daylight.
                            Natural light sources: sunlight, daylight sky, outdoor environment, daylight through windows.
                            If you see ONLY artificial light (lamps, screens, LEDs, fluorescent lights) with NO natural light, respond with is_outside: false.
                            Indoor photos with visible daylight through windows DO count.

                            STEP 2 - If natural light IS present: Verify exposure quality.
                            Pass if: Any amount of natural daylight is visible - overcast, cloudy, through window, or direct sun.
                            Fail if: Photo is clearly nighttime, dark indoor space, or only shows artificial lighting.

                            Respond ONLY with valid JSON:
                            {"is_outside": boolean, "feedback": "brief message"}
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

        return try await decodeVerificationResult(SunlightVerificationResult.self, from: responseText, endpoint: "claude/verify-sunlight")
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
                            TASK: Verify this photo shows HYDRATION (a beverage or drinking vessel).

                            STEP 1 - CRITICAL: Verify this photo contains a beverage or drinking vessel.
                            Valid items: glass, cup, mug, water bottle, tumbler, or person actively drinking.
                            If you do NOT see any beverage or drinking vessel, respond with is_water: false.
                            Random objects, food items, electronics, or furniture do NOT count.

                            STEP 2 - If a drinking vessel IS present: Verify hydration.
                            Pass if: Any drinking vessel (full, partially full, OR empty - empty means they drank it!), or person drinking.
                            Pass for: water, coffee, tea, juice, smoothie, sports drinks, etc.
                            Fail if: Photo shows no drinking vessel at all.

                            Be lenient - the goal is to encourage hydration, not police it.

                            Respond ONLY with valid JSON:
                            {"is_water": boolean, "feedback": "brief message"}
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

        return try await decodeVerificationResult(HydrationVerificationResult.self, from: responseText, endpoint: "claude/verify-hydration")
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
            TASK: Verify this photo for a custom morning habit.

            Habit name: \(customHabit.name)
            User's verification criteria: \(userCriteria)

            STEP 1 - CRITICAL: Determine if this photo is RELEVANT to the habit "\(customHabit.name)".
            The photo must show something clearly related to the habit being verified.
            If the photo appears completely unrelated to "\(customHabit.name)" (random object, different activity, blank/unclear image), respond with is_verified: false.

            STEP 2 - If the photo IS relevant: Check against the user's criteria.
            Pass if: The photo shows reasonable evidence matching the verification criteria. Be moderately generous - the intent should be clear even if execution isn't perfect.
            Fail if: The photo doesn't demonstrate the habit, contradicts the criteria, or shows no genuine attempt.

            Important: If the user's criteria is vague or impossible to verify from a photo, use your judgment based on whether the photo plausibly relates to "\(customHabit.name)".

            Respond ONLY with valid JSON:
            {"is_verified": boolean, "feedback": "brief message"}
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

        return try await decodeVerificationResult(CustomVerificationResult.self, from: responseText, endpoint: "claude/verify-custom-habit")
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
