import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var recipeService: RecipeService

    // regenerate each time userProfile or recipes change
    private var weeklyPlan: [MealPlanDay] {
        MealPlanner.generateWeeklyPlan(
          from: recipeService.recipes,
          using: userProfile
        )
    }

    private var shoppingList: [String: Int] {
        ShoppingListGenerator.generate(from: weeklyPlan)
    }

    var body: some View {
        TabView {
            MealPlanView(weeklyPlan: weeklyPlan)
                .tabItem { Label("Plan", systemImage: "calendar") }

            RecipesView()
                .tabItem { Label("Recipes", systemImage: "book") }

            ShoppingListView(list: shoppingList)
                .tabItem { Label("List", systemImage: "cart") }

            AddRecipeView()
                .tabItem { Label("Add", systemImage: "plus.circle") }
        }
    }
}
