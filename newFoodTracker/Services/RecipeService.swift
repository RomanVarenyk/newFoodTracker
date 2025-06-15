import Foundation

private let kRecipesKey = "recipesKey"

class RecipeService: ObservableObject {
    static let shared = RecipeService()

    @Published var recipes: [Recipe] = [] {
        didSet { save() }
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: kRecipesKey),
           let arr  = try? JSONDecoder().decode([Recipe].self, from: data) {
            recipes = arr
        } else {
            recipes = [
                Recipe(name: "Oatmeal with Banana",
                       ingredients: ["Oats", "Banana", "Milk"],
                       instructions: "Cook oats; top with sliced banana.",
                       calories: 350, protein: 10, carbs: 60, fat: 8),
                Recipe(name: "Greek Yogurt Parfait",
                       ingredients: ["Greek Yogurt", "Mixed Berries", "Granola"],
                       instructions: "Layer yogurt, berries, and granola.",
                       calories: 300, protein: 20, carbs: 30, fat: 5),
                Recipe(name: "Chicken Salad",
                       ingredients: ["Chicken Breast", "Lettuce", "Tomatoes", "Olive Oil"],
                       instructions: "Grill chicken; toss with veggies and oil.",
                       calories: 400, protein: 35, carbs: 10, fat: 20),
                Recipe(name: "Avocado Toast",
                       ingredients: ["Whole Grain Bread", "Avocado", "Lemon Juice"],
                       instructions: "Toast bread; mash avocado with lemon; spread.",
                       calories: 300, protein: 6, carbs: 32, fat: 16),
                Recipe(name: "Protein Smoothie",
                       ingredients: ["Protein Powder", "Spinach", "Banana", "Almond Milk"],
                       instructions: "Blend all ingredients until smooth.",
                       calories: 280, protein: 25, carbs: 30, fat: 4),
                Recipe(name: "Scrambled Eggs & Spinach",
                       ingredients: ["Eggs", "Spinach", "Olive Oil"],
                       instructions: "Sauté spinach; add and scramble eggs.",
                       calories: 250, protein: 15, carbs: 2, fat: 18),
                Recipe(name: "Quinoa Salad",
                       ingredients: ["Quinoa", "Tomatoes", "Cucumber", "Feta"],
                       instructions: "Cook quinoa; mix with veggies and cheese.",
                       calories: 320, protein: 8, carbs: 45, fat: 10),
                Recipe(name: "Turkey Sandwich",
                       ingredients: ["Whole Grain Bread", "Turkey", "Lettuce"],
                       instructions: "Assemble sandwich and serve.",
                       calories: 350, protein: 30, carbs: 40, fat: 8),
                Recipe(name: "Salmon & Veggies",
                       ingredients: ["Salmon", "Broccoli", "Lemon"],
                       instructions: "Bake salmon; steam broccoli; serve with lemon.",
                       calories: 450, protein: 35, carbs: 10, fat: 25),
                Recipe(name: "Beef Stir Fry",
                       ingredients: ["Beef", "Bell Pepper", "Onion"],
                       instructions: "Stir-fry beef with veggies.",
                       calories: 500, protein: 30, carbs: 20, fat: 30),
                Recipe(name: "Veggie Omelette",
                       ingredients: ["Eggs", "Peppers", "Mushrooms"],
                       instructions: "Make omelette with mixed veggies.",
                       calories: 260, protein: 18, carbs: 5, fat: 20),
                Recipe(name: "PB&B Toast",
                       ingredients: ["Whole Grain Bread", "Peanut Butter", "Banana"],
                       instructions: "Spread PB; top with banana slices.",
                       calories: 330, protein: 10, carbs: 35, fat: 15),
                Recipe(name: "Hummus & Veggies",
                       ingredients: ["Hummus", "Carrots", "Celery"],
                       instructions: "Dip veggies into hummus.",
                       calories: 200, protein: 6, carbs: 20, fat: 10),
                Recipe(name: "Cottage Cheese & Fruit",
                       ingredients: ["Cottage Cheese", "Pineapple"],
                       instructions: "Mix and serve chilled.",
                       calories: 220, protein: 20, carbs: 18, fat: 4),
                Recipe(name: "Tuna Salad",
                       ingredients: ["Tuna", "Mayonnaise", "Celery"],
                       instructions: "Mix and serve.",
                       calories: 300, protein: 25, carbs: 2, fat: 18),
                Recipe(name: "Lentil Soup",
                       ingredients: ["Lentils", "Carrot", "Onion"],
                       instructions: "Simmer all ingredients until tender.",
                       calories: 320, protein: 18, carbs: 45, fat: 5),
                Recipe(name: "Roasted Chicken",
                       ingredients: ["Chicken", "Herbs", "Olive Oil"],
                       instructions: "Roast chicken with herbs and oil.",
                       calories: 400, protein: 35, carbs: 0, fat: 25),
                Recipe(name: "Pasta Marinara",
                       ingredients: ["Pasta", "Tomato Sauce"],
                       instructions: "Cook pasta; mix with sauce.",
                       calories: 420, protein: 12, carbs: 70, fat: 8),
                Recipe(name: "Rice & Beans",
                       ingredients: ["Rice", "Black Beans"],
                       instructions: "Cook rice; heat beans.",
                       calories: 390, protein: 15, carbs: 65, fat: 5),
                Recipe(name: "Protein Pancakes",
                       ingredients: ["Oats", "Egg Whites", "Banana"],
                       instructions: "Blend and cook pancakes.",
                       calories: 300, protein: 20, carbs: 40, fat: 5)
            ]
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(recipes) {
            UserDefaults.standard.set(data, forKey: kRecipesKey)
        }
    }
}
