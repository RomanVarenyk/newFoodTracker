//
//  SettingsView.swift
//  newFoodTracker
//
//  Created by You on 2025-05-28.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var mealService: MealPlanService
    @Environment(\.dismiss) private var dismiss

    // Picker options
    private let genders = ["Other", "Male", "Female"]
    private let exerciseLevels = [
        "None",
        "Light (1-2 days)",
        "Moderate (3-4 days)",
        "Heavy (5-7 days)"
    ]
    private let goalOptions = ["Lose", "Maintain", "Gain"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Weight & Height")) {
                    HStack {
                        TextField("Weight", text: $userProfile.weight)
                            .keyboardType(.decimalPad)
                        Toggle("kg", isOn: $userProfile.isMetric)
                    }
                    HStack {
                        TextField("Height", text: $userProfile.height)
                            .keyboardType(.decimalPad)
                        Toggle("cm", isOn: $userProfile.heightIsMetric)
                    }
                }

                Section(header: Text("Age & Gender")) {
                    TextField("Age", text: $userProfile.age)
                        .keyboardType(.numberPad)
                    Picker("Gender", selection: $userProfile.gender) {
                        ForEach(genders, id: \.self) { Text($0) }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Activity & Goal")) {
                    Picker("Exercise Level", selection: $userProfile.exerciseLevel) {
                        ForEach(exerciseLevels, id: \.self) { Text($0) }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Picker("Goal", selection: $userProfile.goal) {
                        ForEach(goalOptions, id: \.self) { Text($0) }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Toggle("Extra Protein Focus", isOn: $userProfile.focusProtein)
                }

                Section {
                    Button("Save") {
                        // 1) compute macros
                        userProfile.calculateMacros()
                        // 2) regenerate plan
                        mealService.regeneratePlan()
                        // 3) dismiss settings
                        dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(
                        userProfile.weight.isEmpty ||
                        userProfile.height.isEmpty ||
                        userProfile.age.isEmpty ||
                        userProfile.gender.isEmpty ||
                        userProfile.exerciseLevel.isEmpty ||
                        userProfile.goal.isEmpty
                    )
                }
            }
            .navigationTitle("Setup Your Profile")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(UserProfile())
            .environmentObject(MealPlanService())
    }
}