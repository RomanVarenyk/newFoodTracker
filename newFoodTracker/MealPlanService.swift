import Foundation

/// Holds and mutates the weekly meal plan.
class MealPlanService: ObservableObject {
    @Published var weeklyPlan: [MealPlanDay] = []
    private let allRecipes: [Recipe]
    private let profile: UserProfile

    init(recipes: [Recipe], profile: UserProfile) {
        self.allRecipes = recipes
        self.profile = profile
        generate()
    }

    /// (Re-)generate the plan
    func generate() {
        weeklyPlan = MealPlanner.generateWeeklyPlan(
            from: allRecipes,
            using: profile
        )
    }

    /// Swap out a single meal slot on a given day
    func swapMeal(
        dayIndex: Int,
        slot: MealSlot,
        with recipe: Recipe
    ) {
        guard dayIndex >= 0, dayIndex < weeklyPlan.count else { return }
        switch slot {
        case .breakfast: weeklyPlan[dayIndex].breakfast = recipe
        case .snack1:    weeklyPlan[dayIndex].snack1    = recipe
        case .lunch:     weeklyPlan[dayIndex].lunch     = recipe
        case .snack2:    weeklyPlan[dayIndex].snack2    = recipe
        case .dinner:    weeklyPlan[dayIndex].dinner    = recipe
        }
    }

    enum MealSlot: String, CaseIterable {
        case breakfast, snack1, lunch, snack2, dinner

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
