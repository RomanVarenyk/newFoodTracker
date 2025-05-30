//
//  MealPlanService.swift
//  newFoodTracker
//
//  Created by You on 2025-05-28.
//

import Foundation
import Combine

// MARK: – Turn your existing RecipeService into a singleton

extension RecipeService {
    static let shared = RecipeService()
}

// MARK: – MealPlanService

/// Manages your 7-day plan and which day is selected.
class MealPlanService: ObservableObject {
    /// Your generated plan of 7 `MealPlanDay`s
    @Published var weeklyPlan: [MealPlanDay] = []
    /// Which day the user has tapped/selected (0…6)
    @Published var selectedDay: Int = 0

    init() {
        // Kick off with an initial plan
        regeneratePlan()
    }

    /// Call anytime you want to re-generate a fresh weekly plan
    func regeneratePlan() {
        // Grab your “master” lists from the shared services:
        let recipes: [Recipe]    = RecipeService.shared.recipes
        let profile: UserProfile = UserProfileService.shared.currentProfile

        weeklyPlan = MealPlanner.generateWeeklyPlan(
            from: recipes,
            using: profile
        )
    }

    /// Swap out a recipe for a given slot on a given day
    func swapMeal(dayIndex: Int, slot: MealSlot, with recipe: Recipe) {
        guard weeklyPlan.indices.contains(dayIndex) else { return }
        var day = weeklyPlan[dayIndex]
        switch slot {
        case .breakfast: day.breakfast = recipe
        case .snack1:    day.snack1    = recipe
        case .lunch:     day.lunch     = recipe
        case .snack2:    day.snack2    = recipe
        case .dinner:    day.dinner    = recipe
        }
        weeklyPlan[dayIndex] = day
    }

    /// The five meal slots per day
    enum MealSlot: CaseIterable, Identifiable {
        case breakfast, snack1, lunch, snack2, dinner

        var id: Self { self }

        /// A human-readable title for each slot
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
