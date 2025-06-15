struct WeeklyPlanOverviewView: View {
    @EnvironmentObject var mealService: MealPlanService

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(0..<mealService.weeklyPlan.count, id: \.self) { idx in
                    NavigationLink(
                        destination: DayDetailView(dayIndex: idx)
                            .environmentObject(mealService)
                    ) {
                        DayCardView(dayIndex: idx, plan: mealService.weeklyPlan[idx])
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
        .background(Color.primaryBackground)
    }
}

struct DayCardView: View {
    let dayIndex: Int
    let plan: MealPlanDay

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text(Calendar.current.shortWeekdaySymbols[dayIndex % 7])
                    .font(.headline)
                    .foregroundColor(Color.primary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Protein: \(plan.totalProtein) g")
                        .font(.caption)
                        .foregroundColor(Color.primary)
                    Text("Fat: \(plan.totalFat) g")
                        .font(.caption)
                        .foregroundColor(Color.primary)
                    Text("Carbs: \(plan.totalCarbs) g")
                        .font(.caption)
                        .foregroundColor(Color.primary)
                    Text("Calories: \(plan.totalCalories) kcal")
                        .font(.caption)
                        .foregroundColor(Color.primary)
                }
            }
            .frame(width: 140)
        }
    }
}

struct DayDetailView: View {
    @EnvironmentObject var mealService: MealPlanService
    @EnvironmentObject var recipeService: RecipeService
    let dayIndex: Int

    @State private var showingPicker = false
    @State private var pickerSlot: MealPlanService.MealSlot?

    @State private var showingCamera = false
    @State private var cameraSlot: MealPlanService.MealSlot?

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                ForEach(MealPlanService.MealSlot.allCases, id: \.self) { slot in
                    CardView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(slot.title).font(.headline)
                            let recipe = mealService.weeklyPlan[dayIndex][slot]
                            Text(recipe.name).font(.subheadline)
                            HStack(spacing: 8) {
                                Text("\(recipe.protein ?? 0)P").font(.caption)
                                Text("\(recipe.fat ?? 0)F").font(.caption)
                                Text("\(recipe.carbs ?? 0)C").font(.caption)
                                Text("\(recipe.calories ?? 0)kcal").font(.caption)
                            }
                            HStack(spacing: 12) {
                                Button("Replace") {
                                    pickerSlot = slot
                                    showingPicker = true
                                }
                                Button("Remove") {
                                    let empty = Recipe(
                                        name: "None",
                                        ingredients: [],
                                        instructions: "",
                                        calories: 0, protein: 0, carbs: 0, fat: 0
                                    )
                                    mealService.swapMeal(dayIndex: dayIndex, slot: slot, with: empty)
                                }
                                Button {
                                    cameraSlot = slot
                                    showingCamera = true
                                } label: {
                                    Image(systemName: "camera")
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                        .padding()
                    }
                    .frame(height: 240)
                }
            }
            .padding()
        }
        .navigationTitle("Day \(dayIndex + 1)")
        .sheet(isPresented: $showingPicker) {
            if let slot = pickerSlot {
                RecipePickerView(
                    slot: slot,
                    dayIndex: dayIndex,
                    onSelect: { newRecipe in
                        mealService.swapMeal(dayIndex: dayIndex, slot: slot, with: newRecipe)
                        showingPicker = false
                        pickerSlot = nil
                    }
                )
                .environmentObject(recipeService)
            }
        }
        .sheet(isPresented: $showingCamera) {
            if let slot = cameraSlot {
                CameraNutritionView(
                    slot: slot,
                    dayIndex: dayIndex
                )
                .environmentObject(mealService)
            }
        }
    }
}

struct CameraNutritionView: View {
    let slot: MealPlanService.MealSlot
    let dayIndex: Int
    @EnvironmentObject var mealService: MealPlanService
    @Environment(\.dismiss) var dismiss

    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var descriptionText: String = ""
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Snap & Estimate \(slot.title)")
                .font(.headline)
                .foregroundColor(Color.primary)

            // Button to launch camera picker
            Button(action: {
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        DispatchQueue.main.async {
                            showingImagePicker = true
                        }
                    } else {
                        // Optionally show an alert
                    }
                }
            }) {
                HStack {
                    Image(systemName: "camera")
                    Text(selectedImage == nil ? "Take Photo" : "Retake Photo")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.brandPurple)
                .foregroundColor(.white)
                .cornerRadius(8)
            }

            // Show preview of selected image (if any)
            if let img = selectedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(8)
            }

            // TextField for description
            TextField("Add a description (optional)", text: $descriptionText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            // Analyze button
            Button(action: {
                guard let img = selectedImage,
                      let data = img.jpegData(compressionQuality: 0.8) else {
                    errorMessage = "Please take a photo first."
                    return
                }
                isAnalyzing = true
                OpenAIService.shared.analyzeImageNutrition(imageData: data, description: descriptionText) { result in
                    DispatchQueue.main.async {
                        isAnalyzing = false
                        switch result {
                        case .success(let info):
                            // Update the meal's macros
                            var updated = mealService.weeklyPlan[dayIndex][slot]
                            updated.calories = info.calories
                            updated.protein  = info.protein
                            updated.carbs    = info.carbs
                            updated.fat      = info.fat
                            mealService.swapMeal(dayIndex: dayIndex, slot: slot, with: updated)
                            dismiss()
                        case .failure(let err):
                            errorMessage = err.localizedDescription
                        }
                    }
                }
            }) {
                if isAnalyzing {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Analyze Nutrition")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(Color.brandPurple)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(selectedImage == nil || isAnalyzing)

            // Show error if any
            if let msg = errorMessage {
                Text(msg)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
        .background(Color.primaryBackground.ignoresSafeArea())
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
}

