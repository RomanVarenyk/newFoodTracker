//
//  newFoodTrackerApp.swift
//  newFoodTracker
//
//  Created by You on 2025-05-28.
//

import SwiftUI

@main
struct newFoodTrackerApp: App {
    // MARK: - State Objects
    @StateObject private var viewRouter    = ViewRouter()
    @StateObject private var userProfile   = UserProfile()
    @StateObject private var recipeService = RecipeService()
    @StateObject private var mealService   = MealPlanService()

    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewRouter)
                .environmentObject(userProfile)
                .environmentObject(recipeService)
                .environmentObject(mealService)
        }
    }
}
