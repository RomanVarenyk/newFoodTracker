import Foundation
import UIKit
// MARK: - OpenAIService

final class OpenAIService {
    static let shared = OpenAIService()
    private let client: OpenAI
    private let apiToken: String

    private init() {
        let token = Bundle.main.object(forInfoDictionaryKey: "APITOKEN") as? String ?? ""
        self.apiToken = token
        client = OpenAI(apiToken: token)
    }

    func parseRecipe(
        fromText text: String,
        completion: @escaping (Result<Recipe, Error>) -> Void
    ) {
        // Stub implementation; real OpenAI parsing removed for compilation.
        DispatchQueue.main.async {
            completion(.failure(NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "parseRecipe stub"])))
        }
    }

    func analyzeImageNutrition(
        imageData: Data,
        description: String?,
        completion: @escaping (Result<(calories: Int, protein: Int, carbs: Int, fat: Int), Error>) -> Void
    ) {
        // Ensure API token is present
        if apiToken.isEmpty {
            completion(.failure(NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key is missing"])))
            return
        }
        // Convert Data → UIImage → smaller JPEG Data
        guard let originalImage = UIImage(data: imageData),
              let smallerJPEGData = originalImage.resizedJPEGData(maxDimension: 256, compressionQuality: 0.6) else {
            completion(.failure(NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Image resizing/compression failed"])))
            return
        }
        // Base64-encode the resized JPEG
        let base64Image = smallerJPEGData.base64EncodedString()

        // Build prompt
        var prompt = """
        You are a nutrition expert. STRICTLY return only a JSON object with keys: calories, protein, carbs, fat. Do not include any additional text or explanation.
        """
        if let desc = description, !desc.isEmpty {
            prompt += "\nDescription: \(desc)"
        }
        prompt += "\nImage (Base64): \(base64Image)"
        prompt += "\nONLY output a JSON object exactly in the format {\"calories\": <int>, \"protein\": <int>, \"carbs\": <int>, \"fat\": <int>}."

        // Prepare HTTP request
        guard let url = URL(string: "https://api.openai.com/v1/completions") else {
            completion(.failure(NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "prompt": prompt,
            "max_tokens": 150
        ]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let http = response as? HTTPURLResponse,
               !(200...299).contains(http.statusCode) {
                completion(.failure(NSError(
                    domain: "OpenAIService",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"]
                )))
                return
            }
            if let http = response as? HTTPURLResponse,
               !(200...299).contains(http.statusCode) {
                completion(.failure(NSError(
                    domain: "OpenAIService",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"]
                )))
                return
            }
            if let http = response as? HTTPURLResponse,
               !(200...299).contains(http.statusCode) {
                completion(.failure(NSError(
                    domain: "OpenAIService",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"]
                )))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data from API"])))
                return
            }
            // Print the raw API response before parsing for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Full API response:\n\(responseString)")
            }
            do {
                // Print the full response before JSON deserialization
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Full API response (before JSON deserialization):\n\(responseString)")
                }
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let first = choices.first,
                   let text = first["text"] as? String {
                    // Print the raw GPT response text for debugging
                    print("GPT raw response text:\n\(text)")

                    // Attempt to extract JSON object using a regular expression
                    if let matchRange = text.range(of: "\\{[\\s\\S]*\\}", options: .regularExpression) {
                        var jsonSubstring = String(text[matchRange])
                        // Remove potential surrounding backticks or whitespace
                        jsonSubstring = jsonSubstring.trimmingCharacters(in: CharacterSet(charactersIn: "` \n"))
                        print("Extracted JSON substring (regex):\n\(jsonSubstring)")
                        if let jsonData = jsonSubstring.data(using: .utf8) {
                            do {
                                if let respJson = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                                    // Parse each value as Int or String
                                    func intValue(for key: String) -> Int? {
                                        if let i = respJson[key] as? Int {
                                            return i
                                        } else if let s = respJson[key] as? String {
                                            return Int(s.trimmingCharacters(in: .whitespacesAndNewlines))
                                        }
                                        return nil
                                    }
                                    if let calories = intValue(for: "calories"),
                                       let protein = intValue(for: "protein"),
                                       let carbs = intValue(for: "carbs"),
                                       let fat = intValue(for: "fat") {
                                        completion(.success((calories: calories, protein: protein, carbs: carbs, fat: fat)))
                                    } else {
                                        completion(.failure(NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid or non-integer nutrition fields"])))
                                    }
                                } else {
                                    completion(.failure(NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])))
                                }
                            } catch {
                                completion(.failure(error))
                            }
                        } else {
                            completion(.failure(NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to convert JSON substring to Data"])))
                        }
                    } else {
                        completion(.failure(NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No JSON object found in response"])))
                    }
                } else {
                    completion(.failure(NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    // MARK: - Parse Recipe From Image (extract name, ingredients, instructions, macros)
    func parseRecipeFromImage(
        imageData: Data,
        completion: @escaping (Result<(
            name: String,
            ingredients: [String],
            instructions: String,
            calories: Int,
            protein: Int,
            carbs: Int,
            fat: Int
        ), Error>) -> Void
    ) {
        // Ensure API token is present
        if apiToken.isEmpty {
            completion(.failure(NSError(
                domain: "OpenAIService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "OpenAI API key is missing"]
            )))
            return
        }
        // Resize and compress image
        guard let originalImage = UIImage(data: imageData),
              let smallerJPEGData = originalImage.resizedJPEGData(maxDimension: 256, compressionQuality: 0.6) else {
            completion(.failure(NSError(
                domain: "OpenAIService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Image resizing/compression failed"]
            )))
            return
        }
        let base64Image = smallerJPEGData.base64EncodedString()

        // Build prompt that requests full recipe details
        var prompt = """
You are a nutrition expert and chef. Given the following image (in Base64), extract and return a JSON object with keys:
"name" (string),
"ingredients" (array of strings),
"instructions" (string),
"calories" (int),
"protein" (int),
"carbs" (int),
"fat" (int).
Strictly output only the JSON with no additional text.
"""
        prompt += "\nImage (Base64): \(base64Image)"
        prompt += "\nExample format: {\"name\":\"Pancakes\",\"ingredients\":[\"1 cup flour\",\"2 eggs\"],\"instructions\":\"Mix and cook.\",\"calories\":300,\"protein\":8,\"carbs\":45,\"fat\":10}"

        // Prepare HTTP request
        guard let url = URL(string: "https://api.openai.com/v1/completions") else {
            completion(.failure(NSError(
                domain: "OpenAIService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]
            )))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "prompt": prompt,
            "max_tokens": 300
        ]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(
                    domain: "OpenAIService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No data from API"]
                )))
                return
            }
            // Debug print
            if let responseString = String(data: data, encoding: .utf8) {
                print("Full API response (parseRecipeFromImage):\n\(responseString)")
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let first = choices.first,
                   let text = first["text"] as? String {
                    print("GPT raw response text (parseRecipeFromImage):\n\(text)")
                    // Extract JSON using regex
                    if let matchRange = text.range(of: "\\{[\\s\\S]*\\}", options: .regularExpression) {
                        var jsonSubstring = String(text[matchRange])
                        jsonSubstring = jsonSubstring.trimmingCharacters(in: CharacterSet(charactersIn: "` \n"))
                        print("Extracted JSON substring (parseRecipeFromImage):\n\(jsonSubstring)")
                        if let jsonData = jsonSubstring.data(using: .utf8) {
                            if let respJson = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                                // Parse fields
                                guard
                                    let name = respJson["name"] as? String,
                                    let ingredientsAny = respJson["ingredients"] as? [Any],
                                    let instructions = respJson["instructions"] as? String
                                else {
                                    completion(.failure(NSError(
                                        domain: "OpenAIService",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Missing required recipe fields"]
                                    )))
                                    return
                                }
                                let ingredients = ingredientsAny.compactMap {
                                    ($0 as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                                }
                                func intValue(for key: String) -> Int? {
                                    if let i = respJson[key] as? Int { return i }
                                    if let s = respJson[key] as? String {
                                        return Int(s.trimmingCharacters(in: .whitespacesAndNewlines))
                                    }
                                    return nil
                                }
                                guard
                                    let calories = intValue(for: "calories"),
                                    let protein = intValue(for: "protein"),
                                    let carbs = intValue(for: "carbs"),
                                    let fat = intValue(for: "fat")
                                else {
                                    completion(.failure(NSError(
                                        domain: "OpenAIService",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid or missing nutrition fields"]
                                    )))
                                    return
                                }
                                completion(.success((
                                    name: name,
                                    ingredients: ingredients,
                                    instructions: instructions,
                                    calories: calories,
                                    protein: protein,
                                    carbs: carbs,
                                    fat: fat
                                )))
                            } else {
                                completion(.failure(NSError(
                                    domain: "OpenAIService",
                                    code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"]
                                )))
                            }
                        } else {
                            completion(.failure(NSError(
                                domain: "OpenAIService",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Unable to convert JSON substring to Data"]
                            )))
                        }
                    } else {
                        completion(.failure(NSError(
                            domain: "OpenAIService",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "No JSON object found in response"]
                        )))
                    }
                } else {
                    completion(.failure(NSError(
                        domain: "OpenAIService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"]
                    )))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Swift Concurrency Wrappers
    func parseRecipe(fromText text: String) async throws -> Recipe {
        try await withCheckedThrowingContinuation { cont in
            parseRecipe(fromText: text) { result in
                cont.resume(with: result)
            }
        }
    }

    func analyzeImageNutrition(imageData: Data, description: String?) async throws -> (calories: Int, protein: Int, carbs: Int, fat: Int) {
        try await withCheckedThrowingContinuation { cont in
            analyzeImageNutrition(imageData: imageData, description: description) { result in
                cont.resume(with: result)
            }
        }
    }

    func parseRecipeFromImage(imageData: Data) async throws -> (
        name: String,
        ingredients: [String],
        instructions: String,
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int
    ) {
        try await withCheckedThrowingContinuation { cont in
            parseRecipeFromImage(imageData: imageData) { result in
                cont.resume(with: result)
            }
        }
    }
}
