struct AddRecipeView: View {
    @EnvironmentObject var recipeService: RecipeService
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var type: String = "Breakfast"
    @State private var ingredientEntries: [IngredientEntry] = [IngredientEntry()]
    @State private var instructions = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var calories: String? = nil
    @State private var protein: String? = nil
    @State private var carbs: String? = nil
    @State private var fat: String? = nil

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
                                DispatchQueue.main.async {
                                    showingImagePicker = true
                                }
                            } else {
                                // Optionally handle denial (e.g., show an alert)
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }

                Section {
                    Button("Save") {
                        // Build Recipe object
                        let ing = ingredientEntries
                            .filter { !$0.name.isEmpty }
                            .map { "\($0.amount) \($0.unit) \($0.name)" }
                        var newRecipe = Recipe(
                            name: name,
                            ingredients: ing,
                            instructions: instructions,
                            calories: calories.flatMap { Int($0) },
                            protein: protein.flatMap { Int($0) },
                            carbs: carbs.flatMap { Int($0) },
                            fat: fat.flatMap { Int($0) }
                        )

                        // If any macro is missing, request ChatGPT to fill
                        if newRecipe.calories == nil || newRecipe.protein == nil || newRecipe.carbs == nil || newRecipe.fat == nil {
                            let prompt = """
                            Fill in missing macros (calories, protein, carbs, fat) for the following recipe:
                            Name: \(newRecipe.name)
                            Ingredients: \(ing.joined(separator: ", "))
                            Instructions: \(newRecipe.instructions)
                            """
                            print("ChatGPT Request for macros:\n\(prompt)")
                            Task {
                                do {
                                    let parsed = try await OpenAIService.shared.parseRecipe(fromText: prompt)
                                    print("ChatGPT Response for macros: calories=\(parsed.calories ?? 0), protein=\(parsed.protein ?? 0), carbs=\(parsed.carbs ?? 0), fat=\(parsed.fat ?? 0)")
                                    newRecipe.calories = parsed.calories
                                    newRecipe.protein = parsed.protein
                                    newRecipe.carbs = parsed.carbs
                                    newRecipe.fat = parsed.fat
                                    recipeService.recipes.append(newRecipe)
                                    dismiss()
                                } catch {
                                    print("ChatGPT Error: \(error.localizedDescription)")
                                    recipeService.recipes.append(newRecipe)
                                    dismiss()
                                }
                            }
                        } else {
                            recipeService.recipes.append(newRecipe)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .navigationTitle("Add Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingImagePicker, onDismiss: {
                if let img = selectedImage {
                    // Send image to ChatGPT for recipe parsing
                    if let data = img.jpegData(compressionQuality: 0.8) {
                        print("ChatGPT Request for image recipe parsing")
                        Task {
                            do {
                                let info = try await OpenAIService.shared.parseRecipeFromImage(imageData: data)
                                print("ChatGPT Parsed Recipe from Image: \(info)")
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
                            } catch {
                                print("ChatGPT Parse Recipe Error: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
}

