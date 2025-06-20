import Foundation
import SwiftUI

class UserProfile: ObservableObject {
    @Published var weight: String = UserDefaults.standard.string(forKey: "weight") ?? "" {
        didSet { UserDefaults.standard.set(weight, forKey: "weight") }
    }
    @Published var isMetric: Bool = UserDefaults.standard.object(forKey: "isMetric") as? Bool ?? true {
        didSet { UserDefaults.standard.set(isMetric, forKey: "isMetric") }
    }
    @Published var height: String = UserDefaults.standard.string(forKey: "height") ?? "" {
        didSet { UserDefaults.standard.set(height, forKey: "height") }
    }
    @Published var heightIsMetric: Bool = UserDefaults.standard.object(forKey: "heightIsMetric") as? Bool ?? true {
        didSet { UserDefaults.standard.set(heightIsMetric, forKey: "heightIsMetric") }
    }
    @Published var age: String = UserDefaults.standard.string(forKey: "age") ?? "" {
        didSet { UserDefaults.standard.set(age, forKey: "age") }
    }
    @Published var gender: String = UserDefaults.standard.string(forKey: "gender") ?? "" {
        didSet { UserDefaults.standard.set(gender, forKey: "gender") }
    }
    @Published var exerciseLevel: String = UserDefaults.standard.string(forKey: "exerciseLevel") ?? "" {
        didSet { UserDefaults.standard.set(exerciseLevel, forKey: "exerciseLevel") }
    }
    @Published var goal: String = UserDefaults.standard.string(forKey: "goal") ?? "" {
        didSet { UserDefaults.standard.set(goal, forKey: "goal") }
    }
    @Published var focusProtein: Bool = UserDefaults.standard.object(forKey: "focusProtein") as? Bool ?? false {
        didSet { UserDefaults.standard.set(focusProtein, forKey: "focusProtein") }
    }

    @Published var planLength: Int = UserDefaults.standard.object(forKey: "planLength") as? Int ?? 7 {
        didSet { UserDefaults.standard.set(planLength, forKey: "planLength") }
    }

    @Published var calorieGoal: Int = 0
    @Published var proteinGoal: Int = 0
    @Published var carbsGoal: Int = 0
    @Published var fatGoal: Int = 0

    init() {
        // Trigger didSet on load
        _ = weight; _ = isMetric; _ = height; _ = heightIsMetric
        _ = age; _ = gender; _ = exerciseLevel; _ = goal; _ = focusProtein
        _ = planLength
    }

    func calculateMacros() {
        guard
            let w = Double(weight),
            let h = Double(height),
            let a = Double(age)
        else {
            calorieGoal = 0; proteinGoal = 0; carbsGoal = 0; fatGoal = 0
            return
        }

        // Convert to metric
        let weightKg = isMetric ? w : w * 0.453592
        let heightCm = heightIsMetric ? h : h * 2.54

        // BMR (Mifflin-St Jeor)
        let sFactor: Double = gender.lowercased() == "male" ? 5 :
                              gender.lowercased() == "female" ? -161 : 0
        let bmr = 10 * weightKg + 6.25 * heightCm - 5 * a + sFactor

        // Activity factor
        let factor: Double = {
            switch exerciseLevel {
            case "Light (1-2 days)":    return 1.375
            case "Moderate (3-4 days)": return 1.55
            case "Heavy (5-7 days)":    return 1.725
            default:                    return 1.2
            }
        }()

        var dailyCal = bmr * factor
        switch goal {
        case "Lose":  dailyCal -= 500
        case "Gain":  dailyCal += 500
        default:      break
        }
        calorieGoal = Int(dailyCal.rounded())

        let protPerKg = focusProtein ? 2.2 : 1.2
        proteinGoal = Int((protPerKg * weightKg).rounded())

        let remCal = dailyCal - Double(proteinGoal * 4)
        carbsGoal = Int((remCal * 0.4 / 4).rounded())
        fatGoal   = Int((remCal * 0.3 / 9).rounded())
    }
}
