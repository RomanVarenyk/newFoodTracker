//
//  ContentView.swift
//  newFoodTracker (Monolithic)
//
//  Combined single-file implementation of newFoodTracker app.
//


import SwiftUI
import Combine
import Foundation
import UIKit
import AVFoundation
import OpenAI

// MARK: - UIImage Resize Helper
extension UIImage {
    /// Resize this image to the specified max dimension (keeping aspect ratio) and then JPEG-compress.
    func resizedJPEGData(maxDimension: CGFloat = 256, compressionQuality: CGFloat = 0.6) -> Data? {
        let aspectRatio = size.width / size.height
        let targetSize: CGSize
        if aspectRatio > 1 {
            targetSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            targetSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        draw(in: CGRect(origin: .zero, size: targetSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage?.jpegData(compressionQuality: compressionQuality)
    }
}

// MARK: - Theme Extensions

extension Color {
    static let brandPurple     = Color(red: 128/255, green:  87/255, blue: 231/255)
    static let backgroundGray     = Color(UIColor.systemGray5)
    static let cardBackground     = Color(UIColor.secondarySystemBackground)
    static let textPrimary        = Color.black.opacity(0.85)
    static let textSecondary      = Color.gray
    static let primaryBackground  = Color(UIColor.systemBackground)
    // cardBackground already defined as dynamic
}

extension Font {
    static let heading  = Font.system(size: 20, weight: .semibold)
    static let subhead  = Font.system(size: 16, weight: .medium)
    static let body     = Font.system(size: 14, weight: .regular)
}

// Helper for SwiftUI share sheet
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Models

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
            case .snack1:    snack1    = newValue
            case .lunch:     lunch     = newValue
            case .snack2:    snack2    = newValue
            case .dinner:    dinner    = newValue
            }
        }
    }
    var totalCalories: Int { [breakfast, snack1, lunch, snack2, dinner].compactMap { $0.calories }.reduce(0, +) }
    var totalProtein:  Int { [breakfast, snack1, lunch, snack2, dinner].compactMap { $0.protein  }.reduce(0, +) }
    var totalCarbs:    Int { [breakfast, snack1, lunch, snack2, dinner].compactMap { $0.carbs    }.reduce(0, +) }
    var totalFat:      Int { [breakfast, snack1, lunch, snack2, dinner].compactMap { $0.fat      }.reduce(0, +) }
}

// MARK: - UserProfile

class UserProfile: ObservableObject {
    @Published var weight: String = UserDefaults.standard.string(forKey: "weight") ?? "" {
        didSet { UserDefaults.standard.set(weight, forKey: "weight") }
    }
    @Published var isMetric: Bool = UserDefaults.standard.object(forKey: "isMetric") as? Bool ?? true {
        didSet { UserDefaults.standard.set(isMetric, forKey: "isMetric") }
    }
    @Published var height: String = UserDefaults.standard.string(forKey: "height") ?? "" {
        didSet { UserDefaults.standard.set(height, forKey: "height") }
    }
    @Published var heightIsMetric: Bool = UserDefaults.standard.object(forKey: "heightIsMetric") as? Bool ?? true {
        didSet { UserDefaults.standard.set(heightIsMetric, forKey: "heightIsMetric") }
    }
    @Published var age: String = UserDefaults.standard.string(forKey: "age") ?? "" {
        didSet { UserDefaults.standard.set(age, forKey: "age") }
    }
    @Published var gender: String = UserDefaults.standard.string(forKey: "gender") ?? "" {
        didSet { UserDefaults.standard.set(gender, forKey: "gender") }
    }
    @Published var exerciseLevel: String = UserDefaults.standard.string(forKey: "exerciseLevel") ?? "" {
        didSet { UserDefaults.standard.set(exerciseLevel, forKey: "exerciseLevel") }
    }
    @Published var goal: String = UserDefaults.standard.string(forKey: "goal") ?? "" {
        didSet { UserDefaults.standard.set(goal, forKey: "goal") }
    }
    @Published var focusProtein: Bool = UserDefaults.standard.object(forKey: "focusProtein") as? Bool ?? false {
        didSet { UserDefaults.standard.set(focusProtein, forKey: "focusProtein") }
    }

    @Published var calorieGoal: Int = 0
    @Published var proteinGoal: Int = 0
    @Published var carbsGoal: Int = 0
    @Published var fatGoal: Int = 0

    init() {
        // Trigger didSet on load
        _ = weight; _ = isMetric; _ = height; _ = heightIsMetric
        _ = age; _ = gender; _ = exerciseLevel; _ = goal; _ = focusProtein
    }

    func calculateMacros() {
        guard
            let w = Double(weight),
            let h = Double(height),
            let a = Double(age)
        else {
            calorieGoal = 0; proteinGoal = 0; carbsGoal = 0; fatGoal = 0
            return
        }

        // Convert to metric
        let weightKg = isMetric ? w : w * 0.453592
        let heightCm = heightIsMetric ? h : h * 2.54

        // BMR (Mifflin-St Jeor)
        let sFactor: Double = gender.lowercased() == "male" ? 5 :
                              gender.lowercased() == "female" ? -161 : 0
        let bmr = 10 * weightKg + 6.25 * heightCm - 5 * a + sFactor

        // Activity factor
        let factor: Double = {
            switch exerciseLevel {
            case "Light (1-2 days)":    return 1.375
            case "Moderate (3-4 days)": return 1.55
            case "Heavy (5-7 days)":    return 1.725
            default:                    return 1.2
            }
        }()

        var dailyCal = bmr * factor
        switch goal {
        case "Lose":  dailyCal -= 500
        case "Gain":  dailyCal += 500
        default:      break
        }
        calorieGoal = Int(dailyCal.rounded())

        let protPerKg = focusProtein ? 2.2 : 1.2
        proteinGoal = Int((protPerKg * weightKg).rounded())

        let remCal = dailyCal - Double(proteinGoal * 4)
        carbsGoal = Int((remCal * 0.4 / 4).rounded())
        fatGoal   = Int((remCal * 0.3 / 9).rounded())
    }
}

// MARK: - Persistence Keys

private let kRecipesKey     = "recipesKey"
private let kWeeklyPlanKey  = "weeklyPlanKey"
private let kSelectedDayKey = "selectedDayKey"

// MARK: - RecipeService

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
                // 20 default recipes
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

// MARK: - UserProfileService

class UserProfileService: ObservableObject {
    static let shared = UserProfileService()
    @Published var currentProfile = UserProfile()
    private init() {}
}

// MARK: - MealPlanService

class MealPlanService: ObservableObject {
    @Published var weeklyPlan: [MealPlanDay] = [] {
        didSet { savePlan() }
    }
    @Published var selectedDay: Int = 0 {
        didSet { saveSelectedDay() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: kWeeklyPlanKey),
           let plan = try? JSONDecoder().decode([MealPlanDay].self, from: data) {
            weeklyPlan = plan
        } else {
            regeneratePlan()
        }
        selectedDay = UserDefaults.standard.integer(forKey: kSelectedDayKey)
    }

    func regeneratePlan() {
        let recipes = RecipeService.shared.recipes
        let profile = UserProfileService.shared.currentProfile
        weeklyPlan = MealPlanner.generateWeeklyPlan(from: recipes, using: profile)
    }

    private func savePlan() {
        if let data = try? JSONEncoder().encode(weeklyPlan) {
            UserDefaults.standard.set(data, forKey: kWeeklyPlanKey)
        }
    }

    private func saveSelectedDay() {
        UserDefaults.standard.set(selectedDay, forKey: kSelectedDayKey)
    }

    func swapMeal(dayIndex: Int, slot: MealSlot, with recipe: Recipe) {
        guard weeklyPlan.indices.contains(dayIndex) else { return }
        weeklyPlan[dayIndex][slot] = recipe
    }

    enum MealSlot: CaseIterable, Identifiable {
        case breakfast, snack1, lunch, snack2, dinner
        var id: Self { self }
        var title: String {
            switch self {
            case .breakfast: return "Breakfast"
            case .snack1:    return "Snack 1"
            case .lunch:     return "Lunch"
            case .snack2:    return "Snack 2"
            case .dinner:    return "Dinner"
            }
        }
    }
}

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
}

// MARK: - VisionService

final class VisionService {
    static let shared = VisionService()
    private init() {}

    func analyze(
        uiImage: UIImage,
        description: String?,
        completion: @escaping (Result<(calories: Int, protein: Int, carbs: Int, fat: Int), Error>) -> Void
    ) {
        guard let data = uiImage.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "VisionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Image conversion failed"])))
            return
        }
        OpenAIService.shared.analyzeImageNutrition(imageData: data, description: description, completion: completion)
    }
}

// MARK: - MealPlanner Helper

struct MealPlanner {
    /// Build a 7-day plan by cycling through the recipe list 5 slots/day.
    static func generateWeeklyPlan(from recipes: [Recipe], using profile: UserProfile) -> [MealPlanDay] {
        guard recipes.count >= 5 else { return [] }
        let shuffled = recipes.shuffled()
        var plan: [MealPlanDay] = []
        for day in 0..<7 {
            // pick 5 recipes, wrapping via modulo
            let daily = (0..<5).map { offset in
                shuffled[(day * 5 + offset) % shuffled.count]
            }
            let pd = MealPlanDay(
                breakfast: daily[0],
                snack1:    daily[1],
                lunch:     daily[2],
                snack2:    daily[3],
                dinner:    daily[4]
            )
            plan.append(pd)
        }
        return plan
    }
}

// MARK: - UI Components

struct CardView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .cornerRadius(16)
    }
}

// MARK: - Views

struct RecipesView: View {
    @EnvironmentObject var recipeService: RecipeService
    @State private var showingEditRecipe = false
    @State private var recipeToEdit: Recipe? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(recipeService.recipes) { recipe in
                    HStack {
                        Text(recipe.name)
                            .font(.headline)
                            .padding(.vertical, 8)
                            .foregroundColor(Color.primary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        recipeToEdit = recipe
                        showingEditRecipe = true
                    }
                    .listRowBackground(Color.primaryBackground)
                }
                .onDelete { indexSet in
                    recipeService.recipes.remove(atOffsets: indexSet)
                }
            }
            .navigationTitle("Recipes")
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
            .background(Color.primaryBackground)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        recipeToEdit = nil
                        showingEditRecipe = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditRecipe, onDismiss: {
                recipeToEdit = nil
            }) {
                EditRecipeView(recipe: $recipeToEdit)
                    .environmentObject(recipeService)
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            // 1. Weekly Plan
            NavigationView {
                WeeklyPlanOverviewView()
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("Week")
            }

            // 2. Macros (Editable)
            NavigationView {
                MacroCalculatorView()
            }
            .tabItem {
                Image(systemName: "gauge")
                Text("Macros")
            }

            // 3. Recipes
            NavigationView {
                RecipesView()
            }
            .tabItem {
                Image(systemName: "book")
                Text("Recipes")
            }

            // 4. Shopping List
            NavigationView {
                ShoppingListView()
            }
            .tabItem {
                Image(systemName: "cart")
                Text("Shopping")
            }

            // 5. Settings
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gearshape")
                Text("Settings")
            }
        }
        .accentColor(.brandPurple)
        .background(Color.primaryBackground.ignoresSafeArea())
    }
}

struct HomeView: View {
    var body: some View {
        WeeklyPlanOverviewView()
            .environmentObject(MealPlanService())
    }
}

struct SettingsView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var mealService: MealPlanService
    @Environment(\.dismiss) private var dismiss

    private let genders = ["Male", "Female", "Other"]
    private let exerciseOptions = ["None", "Light (1-2 days)", "Moderate (3-4 days)", "Heavy (5-7 days)"]
    private let goalOptions = ["Lose", "Maintain", "Gain"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Info").foregroundColor(Color.primary)) {
                    HStack {
                        Text("Weight")
                        TextField("e.g. 70", text: $userProfile.weight)
                            .keyboardType(.decimalPad)
                            .submitLabel(.done)
                            .onSubmit {
                                UIApplication.shared.sendAction(
                                    #selector(UIResponder.resignFirstResponder),
                                    to: nil,
                                    from: nil,
                                    for: nil
                                )
                            }
                    }

                    Picker("Weight Unit", selection: $userProfile.isMetric) {
                        Text("kg").tag(true)
                        Text("lb").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    HStack {
                        Text("Height")
                        TextField("e.g. 170", text: $userProfile.height)
                            .keyboardType(.decimalPad)
                            .submitLabel(.done)
                            .onSubmit {
                                UIApplication.shared.sendAction(
                                    #selector(UIResponder.resignFirstResponder),
                                    to: nil,
                                    from: nil,
                                    for: nil
                                )
                            }
                    }

                    Picker("Height Unit", selection: $userProfile.heightIsMetric) {
                        Text("cm").tag(true)
                        Text("in").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    HStack {
                        Text("Age")
                        TextField("e.g. 30", text: $userProfile.age)
                            .keyboardType(.numberPad)
                            .submitLabel(.done)
                            .onSubmit {
                                UIApplication.shared.sendAction(
                                    #selector(UIResponder.resignFirstResponder),
                                    to: nil,
                                    from: nil,
                                    for: nil
                                )
                            }
                    }

                    Picker("Gender", selection: $userProfile.gender) {
                        ForEach(genders, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .listRowBackground(Color.cardBackground)
                .cornerRadius(8)

                Section(header: Text("Lifestyle").foregroundColor(Color.primary)) {
                    Picker("Exercise Level", selection: $userProfile.exerciseLevel) {
                        ForEach(exerciseOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Picker("Goal", selection: $userProfile.goal) {
                        ForEach(goalOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Toggle("Extra Protein Focus", isOn: $userProfile.focusProtein)
                }
                .listRowBackground(Color.cardBackground)
                .cornerRadius(8)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        userProfile.calculateMacros()
                        mealService.regeneratePlan()
                        dismiss()
                    }
                    .disabled(
                        userProfile.weight.isEmpty ||
                        userProfile.height.isEmpty ||
                        userProfile.age.isEmpty ||
                        userProfile.gender.isEmpty ||
                        userProfile.exerciseLevel.isEmpty ||
                        userProfile.goal.isEmpty
                    )
                }
            }
        }
    }
}

struct WeeklyPlanOverviewView: View {
    @EnvironmentObject var mealService: MealPlanService

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(0..<mealService.weeklyPlan.count, id: \.self) { idx in
                    NavigationLink(
                        destination: DayDetailView(dayIndex: idx)
                            .environmentObject(mealService)
                    ) {
                        DayCardView(dayIndex: idx, plan: mealService.weeklyPlan[idx])
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
        .background(Color.primaryBackground)
    }
}

struct DayCardView: View {
    let dayIndex: Int
    let plan: MealPlanDay

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text(Calendar.current.shortWeekdaySymbols[dayIndex % 7])
                    .font(.headline)
                    .foregroundColor(Color.primary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Protein: \(plan.totalProtein) g")
                        .font(.caption)
                        .foregroundColor(Color.primary)
                    Text("Fat: \(plan.totalFat) g")
                        .font(.caption)
                        .foregroundColor(Color.primary)
                    Text("Carbs: \(plan.totalCarbs) g")
                        .font(.caption)
                        .foregroundColor(Color.primary)
                    Text("Calories: \(plan.totalCalories) kcal")
                        .font(.caption)
                        .foregroundColor(Color.primary)
                }
            }
            .frame(width: 140)
        }
    }
}

struct DayDetailView: View {
    @EnvironmentObject var mealService: MealPlanService
    @EnvironmentObject var recipeService: RecipeService
    let dayIndex: Int

    @State private var showingPicker = false
    @State private var pickerSlot: MealPlanService.MealSlot?

    @State private var showingCamera = false
    @State private var cameraSlot: MealPlanService.MealSlot?

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                ForEach(MealPlanService.MealSlot.allCases, id: \.self) { slot in
                    CardView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(slot.title).font(.headline)
                            let recipe = mealService.weeklyPlan[dayIndex][slot]
                            Text(recipe.name).font(.subheadline)
                            HStack(spacing: 8) {
                                Text("\(recipe.protein ?? 0)P").font(.caption)
                                Text("\(recipe.fat ?? 0)F").font(.caption)
                                Text("\(recipe.carbs ?? 0)C").font(.caption)
                                Text("\(recipe.calories ?? 0)kcal").font(.caption)
                            }
                            HStack(spacing: 12) {
                                Button("Replace") {
                                    pickerSlot = slot
                                    showingPicker = true
                                }
                                Button("Remove") {
                                    let empty = Recipe(
                                        name: "None",
                                        ingredients: [],
                                        instructions: "",
                                        calories: 0, protein: 0, carbs: 0, fat: 0
                                    )
                                    mealService.swapMeal(dayIndex: dayIndex, slot: slot, with: empty)
                                }
                                Button {
                                    cameraSlot = slot
                                    showingCamera = true
                                } label: {
                                    Image(systemName: "camera")
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                        .padding()
                    }
                    .frame(height: 240)
                }
            }
            .padding()
        }
        .navigationTitle("Day \(dayIndex + 1)")
        .sheet(isPresented: $showingPicker) {
            if let slot = pickerSlot {
                RecipePickerView(
                    slot: slot,
                    dayIndex: dayIndex,
                    onSelect: { newRecipe in
                        mealService.swapMeal(dayIndex: dayIndex, slot: slot, with: newRecipe)
                        showingPicker = false
                        pickerSlot = nil
                    }
                )
                .environmentObject(recipeService)
            }
        }
        .sheet(isPresented: $showingCamera) {
            if let slot = cameraSlot {
                CameraNutritionView(
                    slot: slot,
                    dayIndex: dayIndex
                )
                .environmentObject(mealService)
            }
        }
    }
}

struct CameraNutritionView: View {
    let slot: MealPlanService.MealSlot
    let dayIndex: Int
    @EnvironmentObject var mealService: MealPlanService
    @Environment(\.dismiss) var dismiss

    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var descriptionText: String = ""
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Snap & Estimate \(slot.title)")
                .font(.headline)
                .foregroundColor(Color.primary)

            // Button to launch camera picker
            Button(action: {
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        DispatchQueue.main.async {
                            showingImagePicker = true
                        }
                    } else {
                        // Optionally show an alert
                    }
                }
            }) {
                HStack {
                    Image(systemName: "camera")
                    Text(selectedImage == nil ? "Take Photo" : "Retake Photo")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.brandPurple)
                .foregroundColor(.white)
                .cornerRadius(8)
            }

            // Show preview of selected image (if any)
            if let img = selectedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(8)
            }

            // TextField for description
            TextField("Add a description (optional)", text: $descriptionText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            // Analyze button
            Button(action: {
                guard let img = selectedImage,
                      let data = img.jpegData(compressionQuality: 0.8) else {
                    errorMessage = "Please take a photo first."
                    return
                }
                isAnalyzing = true
                OpenAIService.shared.analyzeImageNutrition(imageData: data, description: descriptionText) { result in
                    DispatchQueue.main.async {
                        isAnalyzing = false
                        switch result {
                        case .success(let info):
                            // Update the meal's macros
                            var updated = mealService.weeklyPlan[dayIndex][slot]
                            updated.calories = info.calories
                            updated.protein  = info.protein
                            updated.carbs    = info.carbs
                            updated.fat      = info.fat
                            mealService.swapMeal(dayIndex: dayIndex, slot: slot, with: updated)
                            dismiss()
                        case .failure(let err):
                            errorMessage = err.localizedDescription
                        }
                    }
                }
            }) {
                if isAnalyzing {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Analyze Nutrition")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(Color.brandPurple)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(selectedImage == nil || isAnalyzing)

            // Show error if any
            if let msg = errorMessage {
                Text(msg)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
        .background(Color.primaryBackground.ignoresSafeArea())
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
}

struct MacroCalculatorView: View {
    @EnvironmentObject var userProfile: UserProfile

    @State private var cals: String = ""
    @State private var prot: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""

    private func updateFields() {
        userProfile.calculateMacros()
        cals   = "\(userProfile.calorieGoal)"
        prot   = "\(userProfile.proteinGoal)"
        carbs  = "\(userProfile.carbsGoal)"
        fat    = "\(userProfile.fatGoal)"
    }

    private func progressColor(_ fraction: Double) -> Color {
        if fraction < 0.9 { return .yellow }
        else if fraction <= 1.1 { return .green }
        else { return .red }
    }

    var body: some View {
        Form {
            Section(header: Text("Macro Targets")) {
                HStack {
                    Text("Calories")
                    TextField("kcal", text: $cals)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Protein")
                    TextField("g", text: $prot)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Carbs")
                    TextField("g", text: $carbs)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Fat")
                    TextField("g", text: $fat)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                Button("Save Targets") {
                    if let kc = Int(cals),
                       let pr = Int(prot),
                       let cb = Int(carbs),
                       let ft = Int(fat) {
                        userProfile.calorieGoal = kc
                        userProfile.proteinGoal = pr
                        userProfile.carbsGoal   = cb
                        userProfile.fatGoal     = ft
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            updateFields()
        }
        .onChange(of: userProfile.weight) { _ in updateFields() }
        .onChange(of: userProfile.height) { _ in updateFields() }
        .onChange(of: userProfile.age) { _ in updateFields() }
        .onChange(of: userProfile.gender) { _ in updateFields() }
        .onChange(of: userProfile.exerciseLevel) { _ in updateFields() }
        .onChange(of: userProfile.goal) { _ in updateFields() }
        .onChange(of: userProfile.focusProtein) { _ in updateFields() }
        .navigationTitle("Macro Calculator")
    }
}

struct MacroSummaryView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var mealService: MealPlanService

    private func progressColor(_ fraction: Double) -> Color {
        if fraction < 0.9 { return .yellow }
        else if fraction <= 1.1 { return .green }
        else { return .red }
    }

    var body: some View {
        let day = mealService.weeklyPlan[mealService.selectedDay]
        Form {
            Section(header: Text("Daily Summary")) {
                VStack(alignment: .leading) {
                    Text("Calories: \(day.totalCalories) / \(userProfile.calorieGoal) kcal")
                        .font(.subheadline)
                    ProgressView(value: Double(day.totalCalories),
                                 total: Double(max(userProfile.calorieGoal, 1)))
                        .accentColor(progressColor(Double(day.totalCalories) / Double(max(userProfile.calorieGoal, 1))))
                }
                VStack(alignment: .leading) {
                    Text("Protein: \(day.totalProtein) / \(userProfile.proteinGoal) g")
                        .font(.subheadline)
                    ProgressView(value: Double(day.totalProtein),
                                 total: Double(max(userProfile.proteinGoal, 1)))
                        .accentColor(progressColor(Double(day.totalProtein) / Double(max(userProfile.proteinGoal, 1))))
                }
                VStack(alignment: .leading) {
                    Text("Carbs: \(day.totalCarbs) / \(userProfile.carbsGoal) g")
                        .font(.subheadline)
                    ProgressView(value: Double(day.totalCarbs),
                                 total: Double(max(userProfile.carbsGoal, 1)))
                        .accentColor(progressColor(Double(day.totalCarbs) / Double(max(userProfile.carbsGoal, 1))))
                }
                VStack(alignment: .leading) {
                    Text("Fat: \(day.totalFat) / \(userProfile.fatGoal) g")
                        .font(.subheadline)
                    ProgressView(value: Double(day.totalFat),
                                 total: Double(max(userProfile.fatGoal, 1)))
                        .accentColor(progressColor(Double(day.totalFat) / Double(max(userProfile.fatGoal, 1))))
                }
            }
        }
        .navigationTitle("Macros")
    }
}

struct RecipePickerView: View {
    @EnvironmentObject var recipeService: RecipeService
    @Environment(\.dismiss) var dismiss

    let slot: MealPlanService.MealSlot
    let dayIndex: Int
    let onSelect: (Recipe) -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(recipeService.recipes) { recipe in
                    Button(recipe.name) {
                        onSelect(recipe)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Pick Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}


// Helper struct for dynamic ingredient rows
struct IngredientEntry: Identifiable {
    let id = UUID()
    var name: String = ""
    var amount: String = ""
    var unit: String = ""
}

// ImagePicker for camera integration
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.subhead)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.brandPurple)
            .foregroundColor(.white)
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

// MARK: - Add Recipe View

struct AddRecipeView: View {
    @EnvironmentObject var recipeService: RecipeService
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var type: String = "Breakfast"
    @State private var ingredientEntries: [IngredientEntry] = [IngredientEntry()]
    @State private var instructions = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var calories: String? = nil
    @State private var protein: String? = nil
    @State private var carbs: String? = nil
    @State private var fat: String? = nil

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Recipe Info")) {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        Text("Breakfast").tag("Breakfast")
                        Text("Snack").tag("Snack")
                        Text("Lunch").tag("Lunch")
                        Text("Dinner").tag("Dinner")
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    VStack(alignment: .leading) {
                        Text("Ingredients")
                            .font(Font.subhead).foregroundColor(Color.textSecondary)
                        ForEach($ingredientEntries) { $entry in
                            HStack {
                                TextField("Name", text: $entry.name)
                                TextField("Amt", text: $entry.amount)
                                    .frame(width: 60)
                                    .keyboardType(.decimalPad)
                                TextField("Unit", text: $entry.unit)
                                    .frame(width: 60)
                            }
                        }
                        Button("Add Ingredient") {
                            ingredientEntries.append(IngredientEntry())
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }

                    TextEditor(text: $instructions)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.backgroundGray))
                }

                Section(header: Text("Macros (optional)")) {
                    HStack {
                        Text("Calories")
                        TextField("e.g. 300", text: Binding(
                            get: { calories ?? "" },
                            set: { calories = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.numberPad)
                    }
                    HStack {
                        Text("Protein (g)")
                        TextField("e.g. 20", text: Binding(
                            get: { protein ?? "" },
                            set: { protein = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.numberPad)
                    }
                    HStack {
                        Text("Carbs (g)")
                        TextField("e.g. 30", text: Binding(
                            get: { carbs ?? "" },
                            set: { carbs = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.numberPad)
                    }
                    HStack {
                        Text("Fat (g)")
                        TextField("e.g. 10", text: Binding(
                            get: { fat ?? "" },
                            set: { fat = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.numberPad)
                    }
                }

                Section {
                    Button("Take Photo") {
                        AVCaptureDevice.requestAccess(for: .video) { granted in
                            if granted {
                                DispatchQueue.main.async {
                                    showingImagePicker = true
                                }
                            } else {
                                // Optionally handle denial (e.g., show an alert)
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }

                Section {
                    Button("Save") {
                        // Build Recipe object
                        let ing = ingredientEntries
                            .filter { !$0.name.isEmpty }
                            .map { "\($0.amount) \($0.unit) \($0.name)" }
                        var newRecipe = Recipe(
                            name: name,
                            ingredients: ing,
                            instructions: instructions,
                            calories: calories.flatMap { Int($0) },
                            protein: protein.flatMap { Int($0) },
                            carbs: carbs.flatMap { Int($0) },
                            fat: fat.flatMap { Int($0) }
                        )

                        // If any macro is missing, request ChatGPT to fill
                        if newRecipe.calories == nil || newRecipe.protein == nil || newRecipe.carbs == nil || newRecipe.fat == nil {
                            let prompt = """
                            Fill in missing macros (calories, protein, carbs, fat) for the following recipe:
                            Name: \(newRecipe.name)
                            Ingredients: \(ing.joined(separator: ", "))
                            Instructions: \(newRecipe.instructions)
                            """
                            print("ChatGPT Request for macros:\n\(prompt)")
                            OpenAIService.shared.parseRecipe(fromText: prompt) { result in
                                switch result {
                                case .success(let parsed):
                                    print("ChatGPT Response for macros: calories=\(parsed.calories ?? 0), protein=\(parsed.protein ?? 0), carbs=\(parsed.carbs ?? 0), fat=\(parsed.fat ?? 0)")
                                    newRecipe.calories = parsed.calories
                                    newRecipe.protein = parsed.protein
                                    newRecipe.carbs = parsed.carbs
                                    newRecipe.fat = parsed.fat
                                    recipeService.recipes.append(newRecipe)
                                    dismiss()
                                case .failure(let err):
                                    print("ChatGPT Error: \(err.localizedDescription)")
                                    recipeService.recipes.append(newRecipe)
                                    dismiss()
                                }
                            }
                        } else {
                            recipeService.recipes.append(newRecipe)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .navigationTitle("Add Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingImagePicker, onDismiss: {
                if let img = selectedImage {
                    // Send image to ChatGPT for recipe parsing
                    if let data = img.jpegData(compressionQuality: 0.8) {
                        print("ChatGPT Request for image recipe parsing")
                        OpenAIService.shared.parseRecipeFromImage(imageData: data) { result in
                            switch result {
                            case .success(let info):
                                print("ChatGPT Parsed Recipe from Image: \(info)")
                                // Populate fields
                                DispatchQueue.main.async {
                                    name = info.name
                                    // Map ingredients into IngredientEntry rows, parsing amount/unit/name
                                    ingredientEntries = info.ingredients.map { raw in
                                        // Split into up to three parts: amount, unit, and name
                                        let parts = raw.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true).map { String($0) }
                                        if parts.count >= 3 {
                                            // amount = parts[0], unit = parts[1], name = parts[2]
                                            return IngredientEntry(name: parts[2], amount: parts[0], unit: parts[1])
                                        } else if parts.count == 2 {
                                            // amount = parts[0], unit = parts[1], name empty
                                            return IngredientEntry(name: "", amount: parts[0], unit: parts[1])
                                        } else {
                                            // fallback: put entire string in name
                                            return IngredientEntry(name: raw, amount: "", unit: "")
                                        }
                                    }
                                    instructions = info.instructions
                                    calories = "\(info.calories)"
                                    protein = "\(info.protein)"
                                    carbs = "\(info.carbs)"
                                    fat = "\(info.fat)"
                                }
                            case .failure(let err):
                                print("ChatGPT Parse Recipe Error: \(err.localizedDescription)")
                            }
                        }
                    }
                }
            }) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
}

// MARK: - Shopping List View

struct ShoppingListView: View {
    @EnvironmentObject var recipeService: RecipeService
    @State private var checkedItems: Set<String> = []
    @State private var showingShareSheet = false

    // simple aggregate of all ingredients in current week
    var allIngredients: [String] {
        recipeService.recipes
            .flatMap { $0.ingredients }
            .reduce(into: [:]) { counts, item in counts[item, default: 0] += 1 }
            .map { "\($0.key) x\($0.value)" }
    }

    // Separated list view to aid type-checking
    private var ingredientList: some View {
        List {
            ForEach(allIngredients.sorted(), id: \.self) { item in
                HStack {
                    Image(systemName: checkedItems.contains(item) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(checkedItems.contains(item) ? Color.brandPurple : Color.secondary)
                    Text(item)
                        .font(Font.body)
                        .foregroundColor(Color.primary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if checkedItems.contains(item) {
                        checkedItems.remove(item)
                    } else {
                        checkedItems.insert(item)
                    }
                }
            }
        }
    }

    var body: some View {
        NavigationView {
            ingredientList
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .background(Color.primaryBackground)
                .navigationTitle("Shopping List")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
                .sheet(isPresented: $showingShareSheet) {
                    let shareText = allIngredients.joined(separator: "\n")
                    ActivityView(activityItems: [shareText])
                }
        }
    }
}

@main
struct newFoodTrackerApp: App {
    @StateObject private var userProfile = UserProfile()
    @StateObject private var recipeService = RecipeService.shared
    @StateObject private var mealService = MealPlanService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userProfile)
                .environmentObject(mealService)
                .environmentObject(recipeService)
        }
    }
}

// MARK: - Edit Recipe View

struct EditRecipeView: View {
    @EnvironmentObject var recipeService: RecipeService
    @Environment(\.dismiss) private var dismiss

    @Binding var recipe: Recipe?

    // Local copy of fields
    @State private var name: String = ""
    @State private var type: String = "Breakfast"
    @State private var ingredientEntries: [IngredientEntry] = [IngredientEntry()]
    @State private var instructions: String = ""
    @State private var calories: String? = nil
    @State private var protein: String? = nil
    @State private var carbs: String? = nil
    @State private var fat: String? = nil
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?

    // Determine if this is an edit vs. new
    private var isNew: Bool { recipe == nil }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Recipe Info")) {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        Text("Breakfast").tag("Breakfast")
                        Text("Snack").tag("Snack")
                        Text("Lunch").tag("Lunch")
                        Text("Dinner").tag("Dinner")
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    VStack(alignment: .leading) {
                        Text("Ingredients")
                            .font(Font.subhead).foregroundColor(Color.textSecondary)
                        ForEach($ingredientEntries) { $entry in
                            HStack {
                                TextField("Name", text: $entry.name)
                                TextField("Amt", text: $entry.amount)
                                    .frame(width: 60)
                                    .keyboardType(.decimalPad)
                                TextField("Unit", text: $entry.unit)
                                    .frame(width: 60)
                            }
                        }
                        Button("Add Ingredient") {
                            ingredientEntries.append(IngredientEntry())
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }

                    TextEditor(text: $instructions)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.backgroundGray))
                }

                Section(header: Text("Macros (optional)")) {
                    HStack {
                        Text("Calories")
                        TextField("e.g. 300", text: Binding(
                            get: { calories ?? "" },
                            set: { calories = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.numberPad)
                    }
                    HStack {
                        Text("Protein (g)")
                        TextField("e.g. 20", text: Binding(
                            get: { protein ?? "" },
                            set: { protein = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.numberPad)
                    }
                    HStack {
                        Text("Carbs (g)")
                        TextField("e.g. 30", text: Binding(
                            get: { carbs ?? "" },
                            set: { carbs = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.numberPad)
                    }
                    HStack {
                        Text("Fat (g)")
                        TextField("e.g. 10", text: Binding(
                            get: { fat ?? "" },
                            set: { fat = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.numberPad)
                    }
                }

                Section {
                    Button("Take Photo") {
                        AVCaptureDevice.requestAccess(for: .video) { granted in
                            if granted {
                                // Reuse code from AddRecipeView to show image picker
                                NotificationCenter.default.post(name: NSNotification.Name("ShowEditImagePicker"), object: nil)
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }

                Section {
                    Button(isNew ? "Save" : "Update") {
                        let ing = ingredientEntries
                            .filter { !$0.name.isEmpty }
                            .map { "\($0.amount) \($0.unit) \($0.name)" }
                        let newRecipe = Recipe(
                            name: name,
                            ingredients: ing,
                            instructions: instructions,
                            calories: calories.flatMap { Int($0) },
                            protein: protein.flatMap { Int($0) },
                            carbs: carbs.flatMap { Int($0) },
                            fat: fat.flatMap { Int($0) }
                        )
                        if isNew {
                            recipeService.recipes.append(newRecipe)
                        } else if let old = recipe,
                                  let idx = recipeService.recipes.firstIndex(where: { $0.id == old.id }) {
                            recipeService.recipes[idx] = newRecipe
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .navigationTitle(isNew ? "Add Recipe" : "Edit Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let edit = recipe {
                    name = edit.name
                    type = "" // not used currently but could set if tracked
                    ingredientEntries = edit.ingredients.map { raw in
                        let parts = raw.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true).map { String($0) }
                        if parts.count >= 3 {
                            return IngredientEntry(name: parts[2], amount: parts[0], unit: parts[1])
                        } else if parts.count == 2 {
                            return IngredientEntry(name: "", amount: parts[0], unit: parts[1])
                        } else {
                            return IngredientEntry(name: raw, amount: "", unit: "")
                        }
                    }
                    instructions = edit.instructions
                    calories = edit.calories.map { "\($0)" }
                    protein = edit.protein.map { "\($0)" }
                    carbs = edit.carbs.map { "\($0)" }
                    fat = edit.fat.map { "\($0)" }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowEditImagePicker"))) { _ in
            showingImagePicker = true
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
                .onDisappear {
                    if let img = selectedImage,
                       let data = img.jpegData(compressionQuality: 0.8) {
                        OpenAIService.shared.parseRecipeFromImage(imageData: data) { result in
                            switch result {
                            case .success(let info):
                                DispatchQueue.main.async {
                                    name = info.name
                                    ingredientEntries = info.ingredients.map { raw in
                                        let parts = raw.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true).map { String($0) }
                                        if parts.count >= 3 {
                                            return IngredientEntry(name: parts[2], amount: parts[0], unit: parts[1])
                                        } else if parts.count == 2 {
                                            return IngredientEntry(name: "", amount: parts[0], unit: parts[1])
                                        } else {
                                            return IngredientEntry(name: raw, amount: "", unit: "")
                                        }
                                    }
                                    instructions = info.instructions
                                    calories = "\(info.calories)"
                                    protein = "\(info.protein)"
                                    carbs = "\(info.carbs)"
                                    fat = "\(info.fat)"
                                }
                            case .failure:
                                break
                            }
                        }
                    }
                }
        }
    }
}
