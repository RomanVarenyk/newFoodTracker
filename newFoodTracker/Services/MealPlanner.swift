import Foundation

struct MealPlanner {
    /// Build a 7-day plan by cycling through the recipe list 5 slots/day.
    static func generateWeeklyPlan(from recipes: [Recipe], using profile: UserProfile) -> [MealPlanDay] {
        guard recipes.count >= 5 else { return [] }
        let shuffled = recipes.shuffled()
        var plan: [MealPlanDay] = []
        for day in 0..<7 {
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
