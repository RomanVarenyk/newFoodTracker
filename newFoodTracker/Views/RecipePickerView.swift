struct RecipePickerView: View {
    @EnvironmentObject var recipeService: RecipeService
    @Environment(\.dismiss) var dismiss

    let slot: MealPlanService.MealSlot
    let dayIndex: Int
    let onSelect: (Recipe) -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(recipeService.recipes) { recipe in
                    Button(recipe.name) {
                        onSelect(recipe)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Pick Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}



// MARK: - Add Recipe View

