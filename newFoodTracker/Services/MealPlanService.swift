import Foundation

private let kWeeklyPlanKey  = "weeklyPlanKey"
private let kSelectedDayKey = "selectedDayKey"

class MealPlanService: ObservableObject {
    @Published var weeklyPlan: [MealPlanDay] = [] {
        didSet { savePlan() }
    }
    @Published var selectedDay: Int = 0 {
        didSet { saveSelectedDay() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: kWeeklyPlanKey),
           let plan = try? JSONDecoder().decode([MealPlanDay].self, from: data) {
            weeklyPlan = plan
        } else {
            regeneratePlan()
        }
        selectedDay = UserDefaults.standard.integer(forKey: kSelectedDayKey)
    }

    func regeneratePlan() {
        let recipes = RecipeService.shared.recipes
        let profile = UserProfileService.shared.currentProfile
        weeklyPlan = MealPlanner.generateWeeklyPlan(from: recipes, using: profile)
    }

    private func savePlan() {
        if let data = try? JSONEncoder().encode(weeklyPlan) {
            UserDefaults.standard.set(data, forKey: kWeeklyPlanKey)
        }
    }

    private func saveSelectedDay() {
        UserDefaults.standard.set(selectedDay, forKey: kSelectedDayKey)
    }

    func swapMeal(dayIndex: Int, slot: MealSlot, with recipe: Recipe) {
        guard weeklyPlan.indices.contains(dayIndex) else { return }
        weeklyPlan[dayIndex][slot] = recipe
    }

    enum MealSlot: CaseIterable, Identifiable {
        case breakfast, snack1, lunch, snack2, dinner
        var id: Self { self }
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
