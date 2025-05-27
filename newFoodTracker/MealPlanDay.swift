import Foundation

struct MealPlanDay {
    var breakfast: Recipe
    var snack1: Recipe
    var lunch: Recipe
    var snack2: Recipe
    var dinner: Recipe
}

class MealPlanner {
    /// Pick 5 recipes a day, one for each slot, cycling through the list
    static func generateWeeklyPlan(
        from recipes: [Recipe],
        using profile: UserProfile
    ) -> [MealPlanDay] {
        guard recipes.count >= 5 else { return [] }
        let shuffled = recipes.shuffled()
        var plan: [MealPlanDay] = []

        for day in 0..<7 {
            let slice = Array(shuffled[
                (day*5)..<(day*5+5)
            ])
            plan.append(
                MealPlanDay(
                    breakfast: slice[0],
                    snack1:    slice[1],
                    lunch:     slice[2],
                    snack2:    slice[3],
                    dinner:    slice[4]
                )
            )
        }
        return plan
    }
}
