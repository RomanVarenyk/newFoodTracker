import Foundation

struct MealPlanner {
    /// Build a plan by cycling through the recipe list `days` times (5 slots/day).
    static func generatePlan(days: Int, from recipes: [Recipe], using profile: UserProfile) -> [MealPlanDay] {
        guard recipes.count >= 5, days > 0 else { return [] }
        var sorted = recipes
        if profile.focusProtein {
            sorted.sort { ($0.protein ?? 0) > ($1.protein ?? 0) }
        } else {
            sorted.shuffle()
        }
        var plan: [MealPlanDay] = []
        for day in 0..<days {
            let daily = (0..<5).map { offset in
                sorted[(day * 5 + offset) % sorted.count]
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

    static func generateWeeklyPlan(from recipes: [Recipe], using profile: UserProfile) -> [MealPlanDay] {
        generatePlan(days: 7, from: recipes, using: profile)
    }
}
