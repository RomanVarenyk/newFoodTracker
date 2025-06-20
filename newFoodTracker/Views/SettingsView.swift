struct SettingsView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var mealService: MealPlanService
    @Environment(\.dismiss) private var dismiss

    private let genders = ["Male", "Female", "Other"]
    private let exerciseOptions = ["None", "Light (1-2 days)", "Moderate (3-4 days)", "Heavy (5-7 days)"]
    private let goalOptions = ["Lose", "Maintain", "Gain"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Info").foregroundColor(Color.primary)) {
                    HStack {
                        Text("Weight")
                        TextField("e.g. 70", text: $userProfile.weight)
                            .keyboardType(.decimalPad)
                            .submitLabel(.done)
                            .onSubmit {
                                UIApplication.shared.sendAction(
                                    #selector(UIResponder.resignFirstResponder),
                                    to: nil,
                                    from: nil,
                                    for: nil
                                )
                            }
                    }

                    Picker("Weight Unit", selection: $userProfile.isMetric) {
                        Text("kg").tag(true)
                        Text("lb").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    HStack {
                        Text("Height")
                        TextField("e.g. 170", text: $userProfile.height)
                            .keyboardType(.decimalPad)
                            .submitLabel(.done)
                            .onSubmit {
                                UIApplication.shared.sendAction(
                                    #selector(UIResponder.resignFirstResponder),
                                    to: nil,
                                    from: nil,
                                    for: nil
                                )
                            }
                    }

                    Picker("Height Unit", selection: $userProfile.heightIsMetric) {
                        Text("cm").tag(true)
                        Text("in").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    HStack {
                        Text("Age")
                        TextField("e.g. 30", text: $userProfile.age)
                            .keyboardType(.numberPad)
                            .submitLabel(.done)
                            .onSubmit {
                                UIApplication.shared.sendAction(
                                    #selector(UIResponder.resignFirstResponder),
                                    to: nil,
                                    from: nil,
                                    for: nil
                                )
                            }
                    }

                    Picker("Gender", selection: $userProfile.gender) {
                        ForEach(genders, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .listRowBackground(Color.cardBackground)
                .cornerRadius(8)

                Section(header: Text("Lifestyle").foregroundColor(Color.primary)) {
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
                .listRowBackground(Color.cardBackground)
                .cornerRadius(8)

                Section(header: Text("Meal Plan").foregroundColor(Color.primary)) {
                    Stepper(value: $userProfile.planLength, in: 3...14) {
                        Text("Plan Length: \(userProfile.planLength) days")
                    }
                }
                .listRowBackground(Color.cardBackground)
                .cornerRadius(8)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        userProfile.calculateMacros()
                        mealService.regeneratePlan()
                        dismiss()
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

