//
//  ShoppingListGenerator.swift
//  newFoodTracker
//
//  Created by Roman Bystriakov on 26/5/25.
//


import Foundation

class ShoppingListGenerator {
    /// Count each ingredient across a week
    static func generate(
        from weeklyPlan: [MealPlanDay]
    ) -> [String: Int] {
        var counts: [String: Int] = [:]
        for day in weeklyPlan {
            [ day.breakfast, day.snack1, day.lunch, day.snack2, day.dinner ]
                .forEach { recipe in
                    for ingr in recipe.ingredients {
                        counts[ingr, default: 0] += 1
                    }
                }
        }
        return counts
    }
}
