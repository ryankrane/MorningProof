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

    /// Makes an API request with automatic retry logic for transient failures
    /// Uses exponential backoff: 1s → 2s → 4s
    private func performRequestWithRetry(_ request: URLRequest, endpoint: String, maxRetries: Int = 3) async throws -> Data {
        var lastError: Error = APIError.invalidResponse
        let retryDelays: [UInt64] = [1_000_000_000, 2_000_000_000, 4_000_000_000] // 1s, 2s, 4s in nanoseconds

        for attempt in 0..<maxRetries {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }

                // Success
                if httpResponse.statusCode == 200 {
                    return data
                }

                // Classify the error
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                let error = classifyHTTPError(statusCode: httpResponse.statusCode, message: errorMessage)

                // Log the error
                await MainActor.run {
                    CrashReportingService.shared.recordAPIError(error, endpoint: endpoint, statusCode: httpResponse.statusCode)
                }

                // If retryable and we have attempts left, retry with backoff
                if error.isRetryable && attempt < maxRetries - 1 {
                    try await Task.sleep(nanoseconds: retryDelays[attempt])
                    continue
                }

                throw error
            } catch let urlError as URLError {
                // Network errors - classify and potentially retry
                let error = APIError.networkError(underlyingError: urlError)
                lastError = error

                if attempt < maxRetries - 1 {
                    try await Task.sleep(nanoseconds: retryDelays[attempt])
                    continue
                }

                await MainActor.run {
                    CrashReportingService.shared.recordAPIError(error, endpoint: endpoint)
                }
                throw error
            } catch let apiError as APIError {
                throw apiError
            } catch {
                lastError = error
                if attempt < maxRetries - 1 {
                    try await Task.sleep(nanoseconds: retryDelays[attempt])
                    continue
                }
                throw lastError
            }
        }

        throw lastError
    }

    /// Classifies HTTP status codes into appropriate APIError types
    private func classifyHTTPError(statusCode: Int, message: String) -> APIError {
        switch statusCode {
        case 429:
            return .rateLimited
        case 401, 403:
            // Often rate limiting or temporary issues get misreported as auth errors
            // Treat as service unavailable to be user-friendly
            return .serviceUnavailable
        case 500...599:
            return .serviceUnavailable
        default:
            return .serverError(statusCode: statusCode, message: message)
        }
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
                            ROLE: You are a sharp-eyed bed inspector AI. Be honest, specific, and catch any gaming attempts.

                            ═══════════════════════════════════════════════════════════════
                            STEP 1: IDENTIFY WHAT'S IN THE PHOTO
                            ═══════════════════════════════════════════════════════════════
                            First, describe what you ACTUALLY see. Set detected_subject to one of:
                            - "bed" - if a real bed with mattress/bedding is visible
                            - "bathroom" - toilet, shower, sink, etc.
                            - "kitchen" - stove, fridge, counters, etc.
                            - "desk" - workspace, computer setup
                            - "couch" - sofa or loveseat (NOT a bed)
                            - "screenshot" - clearly a photo of a screen or another photo
                            - "stock_photo" - unnaturally perfect/staged, watermarks, or obviously not personal
                            - "other" - anything else (pet, food, random object, person without bed)

                            If detected_subject is NOT "bed", respond immediately:
                            {"is_made": false, "detected_subject": "[what you see]", "feedback": "I see [specific thing], but I need to see your bed. Try again!"}

                            ═══════════════════════════════════════════════════════════════
                            STEP 2: SCORE THE BED (only if bed is visible)
                            ═══════════════════════════════════════════════════════════════

                            DUVET/COMFORTER (0-25):
                              25: Perfectly smooth, hotel-quality
                              20: Mostly smooth, 1-2 minor creases
                              15: Some wrinkles but clearly pulled up
                              10: Multiple wrinkles, hastily done
                              5:  Bunched or half-pulled
                              0:  Not pulled up, mattress showing

                            PILLOWS (0-25):
                              25: Perfectly arranged and fluffed
                              20: In place, minor asymmetry
                              15: Roughly positioned
                              10: Askew or flat
                              5:  Scattered
                              0:  Missing or chaos

                            EDGES (0-25):
                              25: Tight, military-corner quality
                              20: Tucked, minor looseness
                              15: Most edges covered
                              10: Hanging unevenly
                              5:  Significant mattress visible
                              0:  No attempt

                            OVERALL (0-25):
                              25: Magazine-worthy
                              20: Very neat
                              15: Acceptable effort
                              10: Messy but tried
                              5:  Minimal effort
                              0:  No attempt

                            ═══════════════════════════════════════════════════════════════
                            STEP 3: RESPOND
                            ═══════════════════════════════════════════════════════════════
                            - is_made = true if score >= 65
                            - Feedback must be SPECIFIC to what you see:
                              * Score >= 85: Celebrate! ("Pristine! Those hospital corners are chef's kiss!")
                              * Score 65-84: Praise + one tip ("Looking good! Fluff those pillows for perfection.")
                              * Score 40-64: Name the specific issue ("Those pillows are scattered - line them up!")
                              * Score < 40: Call out what's wrong ("That duvet's still crumpled in the corner. Smooth it out!")

                            JSON format (detected_subject required):
                            {"is_made": boolean, "detected_subject": "bed", "feedback": "specific message"}
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

        // Use retry logic for resilience against transient failures
        let data = try await performRequestWithRetry(request, endpoint: "claude/verify-bed")

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

                            ═══════════════════════════════════════════════════════════════
                            STEP 1: IDENTIFY WHAT'S IN THE PHOTO
                            ═══════════════════════════════════════════════════════════════
                            Set detected_subject to what best describes the scene:
                            - "outdoor_daylight" - outside with natural sunlight/daylight
                            - "window_daylight" - indoors but with visible natural light from windows
                            - "dark_indoor" - indoor space with no natural light
                            - "artificial_light" - room lit only by lamps/screens/LEDs
                            - "nighttime" - clearly night (dark sky, stars, moon)
                            - "screenshot" - photo of a screen or another image
                            - "unrelated" - random object with no light context

                            ═══════════════════════════════════════════════════════════════
                            STEP 2: DETERMINE PASS/FAIL
                            ═══════════════════════════════════════════════════════════════
                            PASS (is_outside: true) if:
                            - Outdoor daylight (sunny, overcast, cloudy all count)
                            - Indoors with visible natural daylight through windows

                            FAIL (is_outside: false) if:
                            - Nighttime scene
                            - Only artificial lighting visible
                            - Dark indoor space
                            - Screenshot or unrelated image

                            ═══════════════════════════════════════════════════════════════
                            STEP 3: RESPOND WITH SPECIFIC FEEDBACK
                            ═══════════════════════════════════════════════════════════════
                            - If unrelated/screenshot: "I see [what's there], but I need to see natural light exposure!"
                            - If artificial light only: "That's artificial light - step outside or near a window!"
                            - If nighttime: "It's dark out! Catch some rays tomorrow morning."
                            - If passed: Acknowledge the light ("Beautiful morning light!" or "Good window setup!")

                            JSON format:
                            {"is_outside": boolean, "detected_subject": "category", "feedback": "specific message"}
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

        // Use retry logic for resilience
        let data = try await performRequestWithRetry(request, endpoint: "claude/verify-sunlight")

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

                            ═══════════════════════════════════════════════════════════════
                            STEP 1: IDENTIFY WHAT'S IN THE PHOTO
                            ═══════════════════════════════════════════════════════════════
                            Set detected_subject to what you see:
                            - "water_bottle" - reusable water bottle or tumbler
                            - "glass" - drinking glass with beverage
                            - "mug" - coffee mug or tea cup
                            - "person_drinking" - someone actively drinking
                            - "food" - food items (not drinks)
                            - "electronics" - phone, computer, etc.
                            - "furniture" - bed, desk, couch
                            - "screenshot" - photo of a screen
                            - "other" - anything else unrelated

                            ═══════════════════════════════════════════════════════════════
                            STEP 2: DETERMINE PASS/FAIL
                            ═══════════════════════════════════════════════════════════════
                            PASS (is_water: true) if:
                            - Any drinking vessel visible (full, partially full, or empty)
                            - Person actively drinking
                            - Water, coffee, tea, juice, smoothie, sports drink - all count!

                            FAIL (is_water: false) if:
                            - No drinking vessel at all
                            - Only food, no drinks
                            - Random objects, electronics, furniture

                            Be lenient - the goal is encouraging hydration!

                            ═══════════════════════════════════════════════════════════════
                            STEP 3: SPECIFIC FEEDBACK
                            ═══════════════════════════════════════════════════════════════
                            - If wrong subject: "I see [what's there], but where's your drink?"
                            - If passed: Acknowledge what you see ("Nice water bottle!" or "Coffee counts!")
                            - Empty vessel: "Already finished? That's the spirit!"

                            JSON format:
                            {"is_water": boolean, "detected_subject": "category", "feedback": "specific message"}
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

        // Use retry logic for resilience
        let data = try await performRequestWithRetry(request, endpoint: "claude/verify-hydration")

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
            ROLE: You are a sharp-eyed habit verification AI. Be honest, specific, and catch gaming attempts.

            TASK: Verify this photo for the custom habit "\(customHabit.name)" using the user's criteria.

            User's verification criteria: \(userCriteria)

            ═══════════════════════════════════════════════════════════════
            STEP 1: IDENTIFY WHAT'S IN THE PHOTO
            ═══════════════════════════════════════════════════════════════
            Set detected_subject to a brief description of what you actually see.
            Examples: "person exercising", "notebook with writing", "kitchen counter", "bathroom sink", "random object", "screenshot"

            Gaming detection - FAIL immediately if you see:
            - Screenshot of another photo or screen
            - Stock photo / obviously not personal
            - Completely unrelated to "\(customHabit.name)"

            If unrelated, respond:
            {"is_verified": false, "detected_subject": "[what you see]", "feedback": "I see [specific thing], but I need to see proof of \(customHabit.name)!"}

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
              30: Mostly meets criteria
              20: Partially meets criteria
              10: Barely addresses criteria
              0:  Doesn't match at all

            CLARITY & EFFORT (0-20):
              20: Clear photo, obvious effort
              15: Reasonably clear
              10: Somewhat unclear but acceptable
              5:  Poor quality but discernible
              0:  Cannot determine what's shown

            ═══════════════════════════════════════════════════════════════
            STEP 3: RESPOND WITH SPECIFIC FEEDBACK
            ═══════════════════════════════════════════════════════════════
            - is_verified = true ONLY if score >= 65
            - Feedback must be SPECIFIC to what you see:
              * Score >= 85: Celebrate! ("Perfect! That's exactly what I'm looking for!")
              * Score 65-84: Acknowledge with encouragement
              * Score 40-64: Name what's missing ("I see X, but I need to see Y")
              * Score < 40: Explain what would count as valid proof

            JSON format (detected_subject required):
            {"is_verified": boolean, "detected_subject": "brief description", "feedback": "specific message"}
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

        // Use retry logic for resilience
        let data = try await performRequestWithRetry(request, endpoint: "claude/verify-custom-habit")

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
    case networkError(underlyingError: Error)
    case rateLimited
    case serviceUnavailable
    case serverError(statusCode: Int, message: String)
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Something went wrong. Please try again."
        case .imageConversionFailed:
            return "Couldn't process your photo. Please try again."
        case .invalidResponse:
            return "Couldn't connect to the server. Please check your connection."
        case .networkError:
            return "Please check your internet connection and try again."
        case .rateLimited:
            return "Please wait a moment and try again."
        case .serviceUnavailable:
            return "Service temporarily unavailable. Please try again in a few minutes."
        case .serverError(let code, _):
            // Return user-friendly messages based on status code
            switch code {
            case 400:
                return "Couldn't process your photo. Please try taking another one."
            case 401, 403:
                // Don't blame the user - this is likely a temporary issue
                return "Service temporarily unavailable. Please try again."
            case 500...599:
                return "Service temporarily unavailable. Please try again later."
            default:
                return "Something went wrong. Please try again."
            }
        case .parsingFailed:
            return "Couldn't understand the response. Please try again."
        }
    }

    /// Icon name to display for this error type
    var iconName: String {
        switch self {
        case .networkError:
            return "wifi.exclamationmark"
        case .rateLimited:
            return "clock.arrow.circlepath"
        case .serviceUnavailable, .serverError:
            return "icloud.slash"
        default:
            return "exclamationmark.triangle"
        }
    }

    /// Whether this error is likely transient and worth retrying
    var isRetryable: Bool {
        switch self {
        case .networkError, .rateLimited, .serviceUnavailable:
            return true
        case .serverError(let code, _):
            return code >= 500 || code == 429
        default:
            return false
        }
    }
}
