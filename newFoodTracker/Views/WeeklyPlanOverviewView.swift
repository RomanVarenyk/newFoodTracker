// WeeklyPlanOverviewView.swift
// newFoodTracker

import SwiftUI

struct WeeklyPlanOverviewView: View {
    @EnvironmentObject var mealService: MealPlanService

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Wrap the integer range in an Array so SwiftUI
                // picks the Data-based ForEach initializer.
                ForEach(Array(0..<mealService.weeklyPlan.count), id: \.self) { idx in
                    DayCardView(dayIndex: idx,
                                plan: mealService.weeklyPlan[idx])
                        .onTapGesture {
                            // Directly assign to the @Published var
                            mealService.selectedDay = idx
                        }
                }
            }
            .padding()
        }
    }
}


struct DayCardView: View {
    let dayIndex: Int
    let plan: MealPlanDay

    /// Sums up this day’s macros across all five slots.
    private var macros: (cals: Int, prot: Int, carbs: Int, fat: Int) {
        let meals = [
            plan.breakfast,
            plan.snack1,
            plan.lunch,
            plan.snack2,
            plan.dinner
        ]
        return (
            meals.reduce(0) { $0 + ($1.calories ?? 0) },
            meals.reduce(0) { $0 + ($1.protein  ?? 0) },
            meals.reduce(0) { $0 + ($1.carbs    ?? 0) },
            meals.reduce(0) { $0 + ($1.fat      ?? 0) }
        )
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                // Day of the week
                Text(Calendar.current.shortWeekdaySymbols[dayIndex % 7])
                    .font(.headline)

                // Macro summary: Protein - Fat - Carbs - Calories
                HStack(spacing: 12) {
                    Text("\(macros.prot)P")
                    Text("\(macros.fat)F")
                    Text("\(macros.carbs)C")
                    Text("\(macros.cals)kcal")
                }
                .font(.caption)
            }
            .frame(width: 140)
        }
    }
}
