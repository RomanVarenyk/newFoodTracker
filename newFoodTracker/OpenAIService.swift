import Foundation
import OpenAI

class OpenAIService {
    static let shared = OpenAIService()
    private let client: OpenAI

    private init() {
        let key = Bundle.main.object(
            forInfoDictionaryKey: "OPENAI_API_KEY"
        ) as? String ?? ""
        client = OpenAI(apiKey: key)
    }

    /// Convert free-form text into a structured Recipe
    func parseRecipe(fromText text: String,
                     completion: @escaping (Result<Recipe, Error>) -> Void) {
        Task {
            do {
                let system = ChatMessage(
                    role: .system,
                    content: """
                    You are a helpful assistant that converts free-form recipe text \
                    into strict JSON with fields matching the `Recipe` Codable struct.
                    """
                )
                let user = ChatMessage(role: .user, content: text)
                let resp = try await client.chats.create(
                    model: .gpt4,
                    messages: [system, user]
                )
                guard let content = resp.choices.first?.message.content,
                      let data = content.data(using: .utf8)
                else {
                    throw URLError(.badServerResponse)
                }
                let recipe = try JSONDecoder().decode(Recipe.self, from: data)
                DispatchQueue.main.async { completion(.success(recipe)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    /// Analyze an image for nutrition (stub – implement with vision API)
    func analyzeImageNutrition(imageData: Data,
                               description: String? = nil,
                               completion:
                                 @escaping (Result<
                                            (calories: Int, protein: Int, carbs: Int, fat: Int),
                                            Error
                                          >
                                 ) -> Void) {
        // TODO: call your OpenAI vision endpoint here
        completion(.failure(NSError(domain: "NotImplemented", code: -1)))
    }

    /// Fetch a recipe image via a search API (stub)
    func fetchImage(forRecipe name: String,
                    completion: @escaping (Result<URL, Error>) -> Void) {
        // TODO: integrate Google Custom Search or similar
        completion(.failure(NSError(domain: "NotImplemented", code: -1)))
    }
}
