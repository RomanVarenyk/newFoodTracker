// SettingsView.swift
// newFoodTracker
//
// Presents the user’s personal & lifestyle settings on first launch (and from Settings later).

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var mealService: MealPlanService
    @Environment(\.presentationMode) private var presentationMode

    // Picker options
    private let genderOptions = ["Male", "Female", "Other"]
    private let exerciseOptions = [
        "None",
        "Light (1-2 days)",
        "Moderate (3-4 days)",
        "Heavy (5-7 days)"
    ]
    private let goalOptions = ["Lose", "Maintain", "Gain"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Info")) {
                    HStack {
                        Text("Weight")
                        TextField("e.g. 70", text: $userProfile.weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Picker("", selection: $userProfile.isMetric) {
                            Text("kg").tag(true)
                            Text("lbs").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 120)
                    }

                    HStack {
                        Text("Height")
                        TextField("e.g. 170", text: $userProfile.height)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Picker("", selection: $userProfile.heightIsMetric) {
                            Text("cm").tag(true)
                            Text("in").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 120)
                    }

                    HStack {
                        Text("Age")
                        TextField("30", text: $userProfile.age)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    Picker("Gender", selection: $userProfile.gender) {
                        ForEach(genderOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                Section(header: Text("Lifestyle")) {
                    Picker("Exercise Level", selection: $userProfile.exerciseLevel) {
                        ForEach(exerciseOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Picker("Goal", selection: $userProfile.goal) {
                        ForEach(goalOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Toggle("Extra Protein Focus", isOn: $userProfile.focusProtein)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        // 1) Recalculate macros
                        userProfile.calculateMacros()
                        // 2) Rebuild the meal plan
                        mealService.regeneratePlan()
                        // 3) Dismiss
                        presentationMode.wrappedValue.dismiss()
                    }
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
        }
    }
}
