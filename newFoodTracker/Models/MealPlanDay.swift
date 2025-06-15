// MealPlanner.swift

import Foundation
struct MealPlanDay: Identifiable {
    let id = UUID()

    // make mutable so subscript setter can work
    var breakfast: Recipe
    var snack1:    Recipe
    var lunch:     Recipe
    var snack2:    Recipe
    var dinner:    Recipe
}

class MealPlanner {
    /// Builds a 7-day plan of 5 slots each by cycling through a shuffled list.
    static func generateWeeklyPlan(
        from recipes: [Recipe],
        using profile: UserProfile
    ) -> [MealPlanDay] {
        // Need at least 5 recipes
        guard recipes.count >= 5 else { return [] }

        let shuffled = recipes.shuffled()
        var plan: [MealPlanDay] = []

        for day in 0..<7 {
            // Compute a “base” that wraps around
            let base = (day * 5) % shuffled.count
            
            // Pull out 5 recipes, wrapping if needed
            let dailyRecipes: [Recipe] = (0..<5).map { offset in
                shuffled[(base + offset) % shuffled.count]
            }

            plan.append(
                MealPlanDay(
                    breakfast: dailyRecipes[0],
                    snack1:    dailyRecipes[1],
                    lunch:     dailyRecipes[2],
                    snack2:    dailyRecipes[3],
                    dinner:    dailyRecipes[4]
                )
            )
        }

        return plan
    }
}

// MARK: - allow indexing a MealPlanDay by slot
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
}
