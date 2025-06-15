import Foundation

struct Recipe: Identifiable, Codable {
    let id = UUID()
    var name: String
    var ingredients: [String]
    var instructions: String
    var calories: Int?
    var protein: Int?
    var carbs: Int?
    var fat: Int?
}

struct MealPlanDay: Identifiable, Codable {
    let id = UUID()
    var breakfast: Recipe
    var snack1: Recipe
    var lunch: Recipe
    var snack2: Recipe
    var dinner: Recipe
}

extension MealPlanDay {
    subscript(slot: MealPlanService.MealSlot) -> Recipe {
        get {
            switch slot {
            case .breakfast: return breakfast
            case .snack1:    return snack1
            case .lunch:     return lunch
            case .snack2:    return snack2
            case .dinner:    return dinner
            }
        }
        set {
            switch slot {
            case .breakfast: breakfast = newValue
            case .snack1:    snack1 = newValue
            case .lunch:     lunch = newValue
            case .snack2:    snack2 = newValue
            case .dinner:    dinner = newValue
            }
        }
    }
    var totalCalories: Int { [breakfast, snack1, lunch, snack2, dinner].compactMap { $0.calories }.reduce(0, +) }
    var totalProtein:  Int { [breakfast, snack1, lunch, snack2, dinner].compactMap { $0.protein }.reduce(0, +) }
    var totalCarbs:    Int { [breakfast, snack1, lunch, snack2, dinner].compactMap { $0.carbs }.reduce(0, +) }
    var totalFat:      Int { [breakfast, snack1, lunch, snack2, dinner].compactMap { $0.fat }.reduce(0, +) }
}
