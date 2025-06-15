import SwiftUI

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
