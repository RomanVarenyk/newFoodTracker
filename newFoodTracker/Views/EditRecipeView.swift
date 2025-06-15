// MARK: - Edit Recipe View

struct EditRecipeView: View {
    @EnvironmentObject var recipeService: RecipeService
    @Environment(\.dismiss) private var dismiss

    @Binding var recipe: Recipe?

    // Local copy of fields
    @State private var name: String = ""
    @State private var type: String = "Breakfast"
    @State private var ingredientEntries: [IngredientEntry] = [IngredientEntry()]
    @State private var instructions: String = ""
    @State private var calories: String? = nil
    @State private var protein: String? = nil
    @State private var carbs: String? = nil
    @State private var fat: String? = nil
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?

    // Determine if this is an edit vs. new
    private var isNew: Bool { recipe == nil }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Recipe Info")) {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        Text("Breakfast").tag("Breakfast")
                        Text("Snack").tag("Snack")
                        Text("Lunch").tag("Lunch")
                        Text("Dinner").tag("Dinner")
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    VStack(alignment: .leading) {
                        Text("Ingredients")
                            .font(Font.subhead).foregroundColor(Color.textSecondary)
                        ForEach($ingredientEntries) { $entry in
                            HStack {
                                TextField("Name", text: $entry.name)
                                TextField("Amt", text: $entry.amount)
                                    .frame(width: 60)
                                    .keyboardType(.decimalPad)
                                TextField("Unit", text: $entry.unit)
                                    .frame(width: 60)
                            }
                        }
                        Button("Add Ingredient") {
                            ingredientEntries.append(IngredientEntry())
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }

                    TextEditor(text: $instructions)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.backgroundGray))
                }

                Section(header: Text("Macros (optional)")) {
                    HStack {
                        Text("Calories")
                        TextField("e.g. 300", text: Binding(
                            get: { calories ?? "" },
                            set: { calories = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.numberPad)
                    }
                    HStack {
                        Text("Protein (g)")
                        TextField("e.g. 20", text: Binding(
                            get: { protein ?? "" },
                            set: { protein = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.numberPad)
                    }
                    HStack {
                        Text("Carbs (g)")
                        TextField("e.g. 30", text: Binding(
                            get: { carbs ?? "" },
                            set: { carbs = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.numberPad)
                    }
                    HStack {
                        Text("Fat (g)")
                        TextField("e.g. 10", text: Binding(
                            get: { fat ?? "" },
                            set: { fat = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.numberPad)
                    }
                }

                Section {
                    Button("Take Photo") {
                        AVCaptureDevice.requestAccess(for: .video) { granted in
                            if granted {
                                // Reuse code from AddRecipeView to show image picker
                                NotificationCenter.default.post(name: NSNotification.Name("ShowEditImagePicker"), object: nil)
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }

                Section {
                    Button(isNew ? "Save" : "Update") {
                        let ing = ingredientEntries
                            .filter { !$0.name.isEmpty }
                            .map { "\($0.amount) \($0.unit) \($0.name)" }
                        let newRecipe = Recipe(
                            name: name,
                            ingredients: ing,
                            instructions: instructions,
                            calories: calories.flatMap { Int($0) },
                            protein: protein.flatMap { Int($0) },
                            carbs: carbs.flatMap { Int($0) },
                            fat: fat.flatMap { Int($0) }
                        )
                        if isNew {
                            recipeService.recipes.append(newRecipe)
                        } else if let old = recipe,
                                  let idx = recipeService.recipes.firstIndex(where: { $0.id == old.id }) {
                            recipeService.recipes[idx] = newRecipe
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .navigationTitle(isNew ? "Add Recipe" : "Edit Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let edit = recipe {
                    name = edit.name
                    type = "" // not used currently but could set if tracked
                    ingredientEntries = edit.ingredients.map { raw in
                        let parts = raw.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true).map { String($0) }
                        if parts.count >= 3 {
                            return IngredientEntry(name: parts[2], amount: parts[0], unit: parts[1])
                        } else if parts.count == 2 {
                            return IngredientEntry(name: "", amount: parts[0], unit: parts[1])
                        } else {
                            return IngredientEntry(name: raw, amount: "", unit: "")
                        }
                    }
                    instructions = edit.instructions
                    calories = edit.calories.map { "\($0)" }
                    protein = edit.protein.map { "\($0)" }
                    carbs = edit.carbs.map { "\($0)" }
                    fat = edit.fat.map { "\($0)" }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowEditImagePicker"))) { _ in
            showingImagePicker = true
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
                .onDisappear {
                    if let img = selectedImage,
                       let data = img.jpegData(compressionQuality: 0.8) {
                        OpenAIService.shared.parseRecipeFromImage(imageData: data) { result in
                            switch result {
                            case .success(let info):
                                DispatchQueue.main.async {
                                    name = info.name
                                    ingredientEntries = info.ingredients.map { raw in
                                        let parts = raw.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true).map { String($0) }
                                        if parts.count >= 3 {
                                            return IngredientEntry(name: parts[2], amount: parts[0], unit: parts[1])
                                        } else if parts.count == 2 {
                                            return IngredientEntry(name: "", amount: parts[0], unit: parts[1])
                                        } else {
                                            return IngredientEntry(name: raw, amount: "", unit: "")
                                        }
                                    }
                                    instructions = info.instructions
                                    calories = "\(info.calories)"
                                    protein = "\(info.protein)"
                                    carbs = "\(info.carbs)"
                                    fat = "\(info.fat)"
                                }
                            case .failure:
                                break
                            }
                        }
                    }
                }
        }
    }
}
