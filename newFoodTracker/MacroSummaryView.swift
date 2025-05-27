import SwiftUI

struct MacroSummaryView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var mealService: MealPlanService

    /// Show summary for a single day (e.g. today = index 0)
    var dayIndex = 0

    var body: some View {
        let day = mealService.weeklyPlan.indices.contains(dayIndex)
            ? mealService.weeklyPlan[dayIndex]
            : nil

        VStack(spacing: 8) {
            Text("Daily Summary")
                .font(.headline)

            HStack {
                summaryItem(
                    title: "Goal",
                    value: "\(userProfile.calorieGoal) kcal"
                )
                summaryItem(
                    title: "Planned",
                    value: "\(totalCalories(for: day)) kcal"
                )
            }
            HStack {
                summaryItem(
                    title: "Protein Goal",
                    value: "\(userProfile.proteinGoal) g"
                )
                summaryItem(
                    title: "Planned",
                    value: "\(totalProtein(for: day)) g"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.2))
        )
        .padding()
    }

    @ViewBuilder
    private func summaryItem(title: String, value: String) -> some View {
        VStack {
            Text(title).font(.subheadline)
            Text(value).bold()
        }
        .frame(maxWidth: .infinity)
    }

    private func totalCalories(for day: MealPlanDay?) -> Int {
        guard let d = day else { return 0 }
        return [d.breakfast, d.snack1, d.lunch, d.snack2, d.dinner]
            .compactMap(\.calories).reduce(0, +)
    }

    private func totalProtein(for day: MealPlanDay?) -> Int {
        guard let d = day else { return 0 }
        return [d.breakfast, d.snack1, d.lunch, d.snack2, d.dinner]
            .compactMap(\.protein).reduce(0, +)
    }
}
