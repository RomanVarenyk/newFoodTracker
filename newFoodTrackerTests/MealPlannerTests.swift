import Testing
@testable import newFoodTracker

struct MealPlannerTests {
    @Test func generateWeeklyPlanCreatesSevenDays() throws {
        let recipe = Recipe(name: "Test", ingredients: [], instructions: "", calories: 100, protein: 10, carbs: 10, fat: 5)
        let recipes = Array(repeating: recipe, count: 6)
        let profile = UserProfile()
        let plan = MealPlanner.generateWeeklyPlan(from: recipes, using: profile)
        #expect(plan.count == 7)
        #expect(plan.allSatisfy { $0.breakfast.name == "Test" })
    }

    @Test func focusProteinSortsByProtein() throws {
        let low = Recipe(name: "Low", ingredients: [], instructions: "", calories: 100, protein: 5, carbs: 0, fat: 0)
        let high = Recipe(name: "High", ingredients: [], instructions: "", calories: 100, protein: 25, carbs: 0, fat: 0)
        let profile = UserProfile()
        profile.focusProtein = true
        let plan = MealPlanner.generateWeeklyPlan(from: [low, high, low, high, low, high], using: profile)
        #expect(plan.first?.breakfast.name == "High")
    }
}
