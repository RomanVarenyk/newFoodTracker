// WeeklyPlanOverviewView.swift

import SwiftUI

struct WeeklyPlanOverviewView: View {
    @EnvironmentObject var mealService: MealPlanService

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(mealService.weeklyPlan.indices, id: \.self) { idx in
                    let dayPlan = mealService.weeklyPlan[idx]
                    DayCardView(dayIndex: idx, plan: dayPlan)
                        .onTapGesture {
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

    // pick the breakfast image (if you add images later)
    var image: Image {
        // placeholder for now
        Image(systemName: "photo")
    }

    var macros: (cals: Int, prot: Int, carbs: Int, fat: Int) {
        let arr = [plan.breakfast, plan.snack1, plan.lunch, plan.snack2, plan.dinner]
        let cals = arr.compactMap(\.calories).reduce(0, +)
        let prot = arr.compactMap(\.protein).reduce(0, +)
        let carbs = arr.compactMap(\.carbs).reduce(0, +)
        let fat  = arr.compactMap(\.fat).reduce(0, +)
        return (cals, prot, carbs, fat)
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text(Calendar.current.shortWeekdaySymbols[dayIndex % 7])
                    .font(.headline)
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 80)
                    .clipped()
                    .cornerRadius(8)
                HStack {
                    Text("\(macros.cals) kcal").font(.caption)
                    Spacer()
                    Text("\(macros.prot)P/\(macros.carbs)C/\(macros.fat)F")
                        .font(.caption2)
                }
            }
            .frame(width: 140)
        }
    }
}
