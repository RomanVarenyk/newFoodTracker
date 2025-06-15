//
//  MacroCalculatorView.swift
//  newFoodTracker
//
//  Created by Roman Bystriakov on 27/5/25.
//

// MacroCalculatorView.swift

import SwiftUI

struct MacroCalculatorView: View {
    @EnvironmentObject var profile: UserProfile
    @State private var proteinPct: Double = 0.25
    @State private var carbPct: Double    = 0.50
    @State private var fatPct: Double     = 0.25

    // Example consumed (you’ll wire this up to actual tracking)
    @State private var consumedCals: Double   = 0
    @State private var consumedProtein: Double = 0
    @State private var consumedCarbs: Double   = 0
    @State private var consumedFat: Double     = 0

    var bmr: Double {
        let w = profile.isMetric
            ? Double(profile.weight) ?? 0
            : (Double(profile.weight) ?? 0) * 0.453592
        let h = profile.heightIsMetric
            ? Double(profile.height) ?? 0
            : (Double(profile.height) ?? 0) * 2.54
        let a = Double(profile.age) ?? 0

        if profile.gender.lowercased() == "male" {
            return 10*w + 6.25*h - 5*a + 5
        } else {
            return 10*w + 6.25*h - 5*a - 161
        }
    }

    var tdee: Double {
        let factors = [
            "None": 1.2,
            "Light (1-2 days)": 1.375,
            "Moderate (3-4)": 1.55,
            "Heavy (5-7)": 1.725
        ]
        let mult = factors[profile.exerciseLevel] ?? 1.2
        return bmr * mult
    }

    var calorieGoal: Double {
        switch profile.goal.lowercased() {
        case "lose":     return tdee - 500
        case "gain":     return tdee + 500
        default:         return tdee
        }
    }

    var proteinGoal: Double { calorieGoal * proteinPct / 4 }
    var carbGoal:    Double { calorieGoal * carbPct    / 4 }
    var fatGoal:     Double { calorieGoal * fatPct     / 9 }

    private func progressColor(_ fraction: Double) -> Color {
        if fraction < 0.9 { return .yellow }
        else if fraction <= 1.1 { return .green }
        else { return .red }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Daily Macro Goals")
                    .font(.title2).bold()

                Group {
                    HStack { Text("Calories"); Spacer()
                            Text("\(Int(consumedCals)) / \(Int(calorieGoal)) kcal") }
                    ProgressView(value: consumedCals, total: calorieGoal)
                        .accentColor(progressColor(consumedCals / calorieGoal))
                }

                Group {
                    HStack { Text("Protein"); Spacer()
                            Text("\(Int(consumedProtein)) / \(Int(proteinGoal)) g") }
                    ProgressView(value: consumedProtein, total: proteinGoal)
                        .accentColor(progressColor(consumedProtein / proteinGoal))
                }
                Group {
                    HStack { Text("Carbs"); Spacer()
                            Text("\(Int(consumedCarbs)) / \(Int(carbGoal)) g") }
                    ProgressView(value: consumedCarbs, total: carbGoal)
                        .accentColor(progressColor(consumedCarbs / carbGoal))
                }
                Group {
                    HStack { Text("Fat"); Spacer()
                            Text("\(Int(consumedFat)) / \(Int(fatGoal)) g") }
                    ProgressView(value: consumedFat, total: fatGoal)
                        .accentColor(progressColor(consumedFat / fatGoal))
                }

                Divider().padding(.vertical)

                Text("Set Macro Ratios")
                    .font(.headline)

                VStack {
                    RatioSlider(label: "Protein %", value: $proteinPct, color: .orange)
                    RatioSlider(label: "Carbs %",    value: $carbPct,    color: .blue)
                    RatioSlider(label: "Fat %",      value: $fatPct,      color: .green)
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct RatioSlider: View {
    let label: String
    @Binding var value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(label): \(Int(value*100))%")
            Slider(value: $value, in: 0...1)
                .accentColor(color)
        }
    }
}
