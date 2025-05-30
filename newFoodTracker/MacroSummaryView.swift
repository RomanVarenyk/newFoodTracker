//
//  MacroSummaryView.swift
//  newFoodTracker
//
//  Created by Roman Bystriakov on 26/5/25.
//


import SwiftUI

struct MacroSummaryView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var mealService: MealPlanService

    /// Returns yellow if <90%, green if 90–110%, red if >110%
    private func progressColor(fraction: Double) -> Color {
        if fraction < 0.9 { return .yellow }
        else if fraction <= 1.1 { return .green }
        else { return .red }
    }

    /// Show summary for a single day (e.g. today = index 0)
    var dayIndex = 0

    var body: some View {
        let day = mealService.weeklyPlan.indices.contains(dayIndex)
            ? mealService.weeklyPlan[dayIndex]
            : nil

        VStack(spacing: 16) {
            Text("Daily Summary")
                .font(.headline)

            // Calories
            let consumedCals = totalCalories(for: day)
            let goalCals     = userProfile.calorieGoal
            VStack(alignment: .leading) {
                Text("Calories")
                    .font(.subheadline)
                HStack {
                    Text("\(consumedCals) / \(goalCals) kcal")
                        .font(.caption)
                    Spacer()
                }
                ProgressView(value: Double(consumedCals), total: Double(goalCals))
                    .accentColor(progressColor(fraction: Double(consumedCals) / Double(max(goalCals,1))))
            }

            // Protein
            let consumedProt = totalProtein(for: day)
            let goalProt     = userProfile.proteinGoal
            VStack(alignment: .leading) {
                Text("Protein")
                    .font(.subheadline)
                HStack {
                    Text("\(consumedProt) / \(goalProt) g")
                        .font(.caption)
                    Spacer()
                }
                ProgressView(value: Double(consumedProt), total: Double(goalProt))
                    .accentColor(progressColor(fraction: Double(consumedProt) / Double(max(goalProt,1))))
            }

            // Carbs
            let consumedCarbs = totalCarbs(for: day)
            let goalCarbs     = userProfile.carbsGoal
            VStack(alignment: .leading) {
                Text("Carbs")
                    .font(.subheadline)
                HStack {
                    Text("\(consumedCarbs) / \(goalCarbs) g")
                        .font(.caption)
                    Spacer()
                }
                ProgressView(value: Double(consumedCarbs), total: Double(goalCarbs))
                    .accentColor(progressColor(fraction: Double(consumedCarbs) / Double(max(goalCarbs,1))))
            }

            // Fat
            let consumedFat = totalFat(for: day)
            let goalFat     = userProfile.fatGoal
            VStack(alignment: .leading) {
                Text("Fat")
                    .font(.subheadline)
                HStack {
                    Text("\(consumedFat) / \(goalFat) g")
                        .font(.caption)
                    Spacer()
                }
                ProgressView(value: Double(consumedFat), total: Double(goalFat))
                    .accentColor(progressColor(fraction: Double(consumedFat) / Double(max(goalFat,1))))
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

    private func totalCarbs(for day: MealPlanDay?) -> Int {
        guard let d = day else { return 0 }
        return [d.breakfast, d.snack1, d.lunch, d.snack2, d.dinner]
            .compactMap(\.carbs).reduce(0, +)
    }

    private func totalFat(for day: MealPlanDay?) -> Int {
        guard let d = day else { return 0 }
        return [d.breakfast, d.snack1, d.lunch, d.snack2, d.dinner]
            .compactMap(\.fat).reduce(0, +)
    }
}
