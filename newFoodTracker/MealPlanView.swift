import SwiftUI

struct MealPlanView: View {
    let weeklyPlan: [MealPlanDay]

    var body: some View {
        NavigationView {
            List {
                ForEach(0..<weeklyPlan.count, id: \.self) { idx in
                    let day = weeklyPlan[idx]
                    Section(header: Text("Day \(idx + 1)")) {
                        MealRow(slot: "Breakfast", recipe: day.breakfast)
                        MealRow(slot: "Snack 1",   recipe: day.snack1)
                        MealRow(slot: "Lunch",     recipe: day.lunch)
                        MealRow(slot: "Snack 2",   recipe: day.snack2)
                        MealRow(slot: "Dinner",    recipe: day.dinner)
                    }
                }
            }
            .navigationTitle("Weekly Plan")
        }
    }
}

private struct MealRow: View {
    let slot: String
    let recipe: Recipe

    var body: some View {
        HStack {
            Text(slot).bold()
            Spacer()
            Text(recipe.name)
        }
    }
}
