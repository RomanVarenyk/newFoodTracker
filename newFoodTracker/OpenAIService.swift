//
//  OpenAIService.swift
//  newFoodTracker
//
//  Created by You on 2025-05-26.
//

import Foundation
import OpenAI

/// A singleton wrapper around the MacPaw OpenAI client.
final class OpenAIService {
    static let shared = OpenAIService()
    private let client: OpenAI

    private init() {
        // Make sure you have an entry “OPENAI_API_KEY” in your Info.plist
        let token = Bundle.main
            .object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String ?? ""
        client = OpenAI(apiToken: token)
    }

    // MARK: – Recipe parsing

    /// Parses free-form recipe text into our `Recipe` model.
    func parseRecipe(
        fromText text: String,
        completion: @escaping (Result<Recipe, Error>) -> Void
    ) {
        // 1) Build the system + user messages (these initializers are failable)
        guard
            let systemMsg = ChatQuery.ChatCompletionMessageParam(
                role: .system,
                content: """
                You are a helpful assistant that extracts name, ingredients (as a JSON array \
                of strings), instructions, and approximate calories/protein/carbs/fat into JSON \
                matching the Recipe struct:
                {
                  "name": String,
                  "ingredients": [String],
                  "instructions": String,
                  "calories": Int,
                  "protein": Int,
                  "carbs": Int,
                  "fat": Int
                }
                """
            ),
            let userMsg = ChatQuery.ChatCompletionMessageParam(
                role: .user,
                content: text
            )
        else {
            completion(.failure(
                NSError(
                    domain: "OpenAIService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to build messages"]
                )
            ))
            return
        }

        // 2) Create the chat-completion query (messages first, then model)
        let query = ChatQuery(
            messages: [systemMsg, userMsg],
            model: .gpt3_5Turbo
        )

        // 3) Fire off the async call
        Task {
            do {
                let response = try await client.chats(query: query)
                guard
                    let raw = response.choices.first?.message.content,
                    let data = raw.data(using: .utf8)
                else {
                    throw NSError(
                        domain: "OpenAIService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Empty or invalid response"]
                    )
                }

                // 4) Decode directly into our Recipe struct
                let recipe = try JSONDecoder().decode(Recipe.self, from: data)
                DispatchQueue.main.async { completion(.success(recipe)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    // MARK: – Image nutrition analysis stub

    /// Analyze raw JPEG `Data` (and optional description) into estimated macros.
    /// Currently a stub — replace with a real OpenAI image‐analysis call.
    func analyzeImageNutrition(
        imageData: Data,
        description: String?,
        completion: @escaping (Result<(calories: Int, protein: Int, carbs: Int, fat: Int), Error>) -> Void
    ) {
        // TODO: hook this up to OpenAI’s Vision endpoint or custom endpoint
        let err = NSError(
            domain: "OpenAIService",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "analyzeImageNutrition(_:) not implemented yet"]
        )
        completion(.failure(err))
    }
}
