import Foundation

struct Recipe: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var ingredients: [String]
    var instructions: String
    var calories: Int?
    var protein: Int?
    var carbs: Int?
    var fat: Int?
    var imageURL: URL?

    init(name: String,
         ingredients: [String],
         instructions: String,
         calories: Int? = nil,
         protein: Int? = nil,
         carbs: Int? = nil,
         fat: Int? = nil,
         imageURL: URL? = nil) {
        self.id = UUID()
        self.name = name
        self.ingredients = ingredients
        self.instructions = instructions
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.imageURL = imageURL
    }
}
