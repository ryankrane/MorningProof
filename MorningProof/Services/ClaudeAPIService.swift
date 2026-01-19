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
            "max_tokens": 512,
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
                            ROLE: You are a STRICT bed inspection AI. Users want honest, exacting feedback.

                            TASK: Score this bed photo using the EXACT rubric below.

                            ═══════════════════════════════════════════════════════════════
                            STEP 1: VERIFY THIS IS A BED
                            ═══════════════════════════════════════════════════════════════
                            A bed MUST have: mattress + bedding. If NO BED visible: score = 0, is_made = false.
                            Couches, chairs, floors = NOT A BED.

                            ═══════════════════════════════════════════════════════════════
                            STEP 2: SCORE EACH CRITERION (0-25 points each)
                            ═══════════════════════════════════════════════════════════════

                            DUVET/COMFORTER SMOOTHNESS (0-25):
                              25: Perfectly smooth, hotel-quality
                              20: Mostly smooth with 1-2 minor creases
                              15: Some wrinkles but clearly pulled up
                              10: Multiple wrinkles, hastily done
                              5:  Bunched, twisted, or half-pulled
                              0:  Not pulled up, mattress exposed

                            PILLOW ALIGNMENT (0-25):
                              25: Perfectly centered, fluffed, symmetrical
                              20: In place, minor asymmetry
                              15: Roughly positioned
                              10: Askew or not fluffed
                              5:  Scattered or partially visible
                              0:  No pillows visible OR completely disorganized

                            EDGES TUCKED (0-25):
                              25: All edges tight, military-corner quality
                              20: Tucked, minor looseness
                              15: Most edges covered, some gaps
                              10: Hanging or uneven
                              5:  Significant mattress visible
                              0:  Not tucked at all

                            OVERALL TIDINESS (0-25):
                              25: Magazine-quality
                              20: Very neat, minor imperfections
                              15: Acceptable, clear effort
                              10: Messy but functional attempt
                              5:  Minimal effort visible
                              0:  No attempt made

                            ═══════════════════════════════════════════════════════════════
                            STEP 3: CALCULATE AND RESPOND
                            ═══════════════════════════════════════════════════════════════
                            - Total score = sum of all four criteria (0-100)
                            - is_made = true ONLY if score >= 65
                            - Feedback should be SPECIFIC and PERSONALITY-DRIVEN based on score tier:
                              * Score >= 85: Celebrate with energy ("Pristine! That's hotel-worthy!")
                              * Score 65-84: Acknowledge success, maybe a tip ("Solid work! Those corners could be tighter next time.")
                              * Score 40-64: Specific actionable fix ("That duvet looks like a crumpled napkin. Smooth it from the corners!")
                              * Score < 40: Playful challenge ("Is that a bed or a laundry pile? Show me what you've got!")

                            Respond ONLY with valid JSON (score is for your internal use, do not include in response):
                            {"is_made": boolean, "feedback": "specific message based on score tier"}
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
            ROLE: You are a STRICT habit verification AI. Users want honest, exacting feedback.

            TASK: Verify this photo for the custom habit "\(customHabit.name)" using the user's criteria.

            User's verification criteria: \(userCriteria)

            ═══════════════════════════════════════════════════════════════
            STEP 1: VERIFY PHOTO RELEVANCE
            ═══════════════════════════════════════════════════════════════
            - Photo MUST show something clearly related to "\(customHabit.name)"
            - If completely unrelated (random object, blank, wrong activity): score = 0

            ═══════════════════════════════════════════════════════════════
            STEP 2: SCORE THE PHOTO (0-100 points)
            ═══════════════════════════════════════════════════════════════

            RELEVANCE TO HABIT (0-40):
              40: Perfectly captures the habit being done
              30: Clearly shows the habit activity
              20: Related but indirect evidence
              10: Loosely connected
              0:  Completely unrelated

            CRITERIA MATCH (0-40):
              40: Fully meets user's verification criteria
              30: Mostly meets criteria with minor gaps
              20: Partially meets criteria
              10: Barely addresses criteria
              0:  Doesn't match criteria at all

            CLARITY & EFFORT (0-20):
              20: Clear photo, obvious effort made
              15: Reasonably clear
              10: Somewhat unclear but acceptable
              5:  Poor quality but discernible
              0:  Cannot determine what's shown

            ═══════════════════════════════════════════════════════════════
            STEP 3: CALCULATE AND RESPOND
            ═══════════════════════════════════════════════════════════════
            - Total score = sum of all criteria (0-100)
            - is_verified = true ONLY if score >= 65
            - Feedback should be SPECIFIC based on score tier:
              * Score >= 85: "Perfect! That's exactly what I'm looking for!"
              * Score 65-84: Acknowledge completion with encouragement
              * Score 40-64: Specific feedback on what's missing
              * Score < 40: Explain what would count as valid proof

            Respond ONLY with valid JSON:
            {"is_verified": boolean, "feedback": "specific message"}
            """

        let requestBody: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": 512,
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
