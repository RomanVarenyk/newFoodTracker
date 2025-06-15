struct MacroCalculatorView: View {
    @EnvironmentObject var userProfile: UserProfile

    @State private var cals: String = ""
    @State private var prot: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""

    private func updateFields() {
        userProfile.calculateMacros()
        cals   = "\(userProfile.calorieGoal)"
        prot   = "\(userProfile.proteinGoal)"
        carbs  = "\(userProfile.carbsGoal)"
        fat    = "\(userProfile.fatGoal)"
    }

    private func progressColor(_ fraction: Double) -> Color {
        if fraction < 0.9 { return .yellow }
        else if fraction <= 1.1 { return .green }
        else { return .red }
    }

    var body: some View {
        Form {
            Section(header: Text("Macro Targets")) {
                HStack {
                    Text("Calories")
                    TextField("kcal", text: $cals)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Protein")
                    TextField("g", text: $prot)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Carbs")
                    TextField("g", text: $carbs)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Fat")
                    TextField("g", text: $fat)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                Button("Save Targets") {
                    if let kc = Int(cals),
                       let pr = Int(prot),
                       let cb = Int(carbs),
                       let ft = Int(fat) {
                        userProfile.calorieGoal = kc
                        userProfile.proteinGoal = pr
                        userProfile.carbsGoal   = cb
                        userProfile.fatGoal     = ft
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            updateFields()
        }
        .onChange(of: userProfile.weight) { _ in updateFields() }
        .onChange(of: userProfile.height) { _ in updateFields() }
        .onChange(of: userProfile.age) { _ in updateFields() }
        .onChange(of: userProfile.gender) { _ in updateFields() }
        .onChange(of: userProfile.exerciseLevel) { _ in updateFields() }
        .onChange(of: userProfile.goal) { _ in updateFields() }
        .onChange(of: userProfile.focusProtein) { _ in updateFields() }
        .navigationTitle("Macro Calculator")
    }
}

struct MacroSummaryView: View {
    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var mealService: MealPlanService

    private func progressColor(_ fraction: Double) -> Color {
        if fraction < 0.9 { return .yellow }
        else if fraction <= 1.1 { return .green }
        else { return .red }
    }

    var body: some View {
        let day = mealService.weeklyPlan[mealService.selectedDay]
        Form {
            Section(header: Text("Daily Summary")) {
                VStack(alignment: .leading) {
                    Text("Calories: \(day.totalCalories) / \(userProfile.calorieGoal) kcal")
                        .font(.subheadline)
                    ProgressView(value: Double(day.totalCalories),
                                 total: Double(max(userProfile.calorieGoal, 1)))
                        .accentColor(progressColor(Double(day.totalCalories) / Double(max(userProfile.calorieGoal, 1))))
                }
                VStack(alignment: .leading) {
                    Text("Protein: \(day.totalProtein) / \(userProfile.proteinGoal) g")
                        .font(.subheadline)
                    ProgressView(value: Double(day.totalProtein),
                                 total: Double(max(userProfile.proteinGoal, 1)))
                        .accentColor(progressColor(Double(day.totalProtein) / Double(max(userProfile.proteinGoal, 1))))
                }
                VStack(alignment: .leading) {
                    Text("Carbs: \(day.totalCarbs) / \(userProfile.carbsGoal) g")
                        .font(.subheadline)
                    ProgressView(value: Double(day.totalCarbs),
                                 total: Double(max(userProfile.carbsGoal, 1)))
                        .accentColor(progressColor(Double(day.totalCarbs) / Double(max(userProfile.carbsGoal, 1))))
                }
                VStack(alignment: .leading) {
                    Text("Fat: \(day.totalFat) / \(userProfile.fatGoal) g")
                        .font(.subheadline)
                    ProgressView(value: Double(day.totalFat),
                                 total: Double(max(userProfile.fatGoal, 1)))
                        .accentColor(progressColor(Double(day.totalFat) / Double(max(userProfile.fatGoal, 1))))
                }
            }
        }
        .navigationTitle("Macros")
    }
}

