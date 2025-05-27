import SwiftUI

class RecipeService: ObservableObject {
    static let shared = RecipeService()
    @Published private(set) var recipes: [Recipe] = [
        // seed with a couple of basics
        Recipe(name: "Oatmeal with Berries",
               ingredients: ["1 cup oats", "1/2 cup berries", "1 cup milk"],
               instructions: "Cook oats in milk 5 min; top with berries.",
               calories: 300, protein: 10, carbs: 45, fat: 6),
        Recipe(name: "Avocado Toast",
               ingredients: ["2 slices bread", "1/2 avocado", "salt & pepper"],
               instructions: "Toast bread; smash avocado; season.",
               calories: 250, protein: 6, carbs: 30, fat: 12)
    ]

    func addManual(name: String,
                   ingredients: [String],
                   instructions: String,
                   image: UIImage? = nil,
                   completion: @escaping (Result<Recipe, Error>) -> Void) {
        var r = Recipe(name: name,
                       ingredients: ingredients,
                       instructions: instructions)
        // TODO: upload `image` to storage and set r.imageURL
        recipes.append(r)
        completion(.success(r))
    }

    func addFromText(_ text: String,
                     completion: @escaping (Result<Recipe, Error>) -> Void) {
        OpenAIService.shared.parseRecipe(fromText: text) { result in
            if case .success(let r) = result {
                self.recipes.append(r)
            }
            completion(result)
        }
    }

    func addFromImage(_ image: UIImage,
                      description: String?,
                      completion: @escaping (Result<Recipe, Error>) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return completion(.failure(NSError(domain: "ImageError", code: -1)))
        }
        // you could first call analyzeImageNutrition, then parseRecipe…
        OpenAIService.shared.analyzeImageNutrition(imageData: data, description: description) { _ in
            // stub
            completion(.failure(NSError(domain: "NotImplemented", code: -1)))
        }
    }
}
