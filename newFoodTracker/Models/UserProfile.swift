//
//  UserProfile.swift
//  newFoodTracker
//
//  Created by You on 2025-05-28.
//

import Foundation
import Combine

/// Holds all onboarding inputs plus computed macro goals.
class UserProfile: ObservableObject {
    // MARK: – Onboarding inputs

    /// User’s weight (entered as String so we can allow “70” or “”)
    @Published var weight: String = ""
    /// Is the `weight` field in kilograms? Otherwise pounds.
    @Published var isMetric: Bool = true

    /// User’s height (entered as String so we can allow “170” or “”)
    @Published var height: String = ""
    /// Is the `height` field in centimeters? Otherwise inches.
    @Published var heightIsMetric: Bool = true

    /// User’s age in years
    @Published var age: String = ""
    /// “Male”, “Female”, or free-form
    @Published var gender: String = ""

    /// “None”, “Light (1-2 days)”, “Moderate (3-4 days)”, “Heavy (5-7 days)”
    @Published var exerciseLevel: String = ""
    /// “Lose”, “Maintain”, “Gain”
    @Published var goal: String = ""
    /// If true, use higher protein target (2.2 g/kg)
    @Published var focusProtein: Bool = false

    // MARK: – Computed targets

    /// Calories/day target after BMR + activity + goal
    @Published private(set) var calorieGoal: Int = 0
    /// Protein (g/day)
    @Published private(set) var proteinGoal: Int = 0
    /// Carbs (g/day), estimated at 40% of remaining calories
    @Published private(set) var carbsGoal: Int = 0
    /// Fat (g/day), estimated at 30% of remaining calories
    @Published private(set) var fatGoal: Int = 0

    /// Call this whenever any input changes
    func calculateMacros() {
        guard
            let w = Double(weight),
            let h = Double(height),
            let a = Double(age)
        else {
            // if inputs are invalid, zero out
            calorieGoal = 0
            proteinGoal = 0
            carbsGoal = 0
            fatGoal = 0
            return
        }

        // 1) Convert to metric
        let weightKg = isMetric ? w : w * 0.453592
        let heightCm = heightIsMetric ? h : h * 2.54

        // 2) Basal Metabolic Rate (Mifflin–St Jeor)
        let sFactor: Double = gender.lowercased() == "male"
            ? 5
            : gender.lowercased() == "female"
                ? -161
                : 0
        let bmr = 10 * weightKg + 6.25 * heightCm - 5 * a + sFactor

        // 3) Activity factor
        let activityFactor: Double
        switch exerciseLevel {
            case "Light (1-2 days)":    activityFactor = 1.375
            case "Moderate (3-4 days)": activityFactor = 1.55
            case "Heavy (5-7 days)":    activityFactor = 1.725
            default:                    activityFactor = 1.2
        }

        // 4) Maintenance + goal adjustment
        var dailyCal = bmr * activityFactor
        switch goal {
            case "Lose":    dailyCal -= 500
            case "Gain":    dailyCal += 500
            default:        break
        }
        calorieGoal = Int(dailyCal.rounded())

        // 5) Protein (g/kg)
        let protPerKg = focusProtein ? 2.2 : 1.2
        proteinGoal = Int((protPerKg * weightKg).rounded())

        // 6) Carbs & fat (split of remaining calories)
        let remainingCal   = dailyCal - Double(proteinGoal * 4)
        let carbsCalTarget = remainingCal * 0.4
        let fatCalTarget   = remainingCal * 0.3
        carbsGoal = Int((carbsCalTarget / 4).rounded())   // 4 kcal per gram
        fatGoal   = Int((fatCalTarget   / 9).rounded())   // 9 kcal per gram
    }
}
