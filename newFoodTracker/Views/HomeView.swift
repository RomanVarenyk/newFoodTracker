// HomeView.swift

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var recipeService: RecipeService
    @EnvironmentObject var mealService: MealPlanService

    /// Compute the current weekly plan
    private var weeklyPlan: [MealPlanDay] {
        mealService.weeklyPlan
    }

    /// Compute the shopping list from the plan
    private var shoppingList: [String: Int] {
        ShoppingListGenerator.generate(from: weeklyPlan)
    }

    var body: some View {
        TabView {
            // 1: Weekly Meal Plan (tap a meal to swap)
            MealPlanView()
                .tabItem {
                    Label("Plan", systemImage: "calendar")
                }

            // 2: All Recipes
            RecipesView()
                .tabItem {
                    Label("Recipes", systemImage: "book")
                }

            // 3: Shopping List (enhanced)
            ShoppingListEnhancedView(list: shoppingList)
                .tabItem {
                    Label("List", systemImage: "cart")
                }

            // 4: Macro Summary for today
            MacroSummaryView()
                .tabItem {
                    Label("Macros", systemImage: "chart.bar")
                }

            // 5: Add New Recipe
            AddRecipeView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle")
                }
        }
    }
}
