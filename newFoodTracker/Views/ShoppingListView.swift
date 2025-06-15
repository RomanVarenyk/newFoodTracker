struct ShoppingListView: View {
    @EnvironmentObject var recipeService: RecipeService
    @State private var checkedItems: Set<String> = []
    @State private var showingShareSheet = false

    // simple aggregate of all ingredients in current week
    var allIngredients: [String] {
        recipeService.recipes
            .flatMap { $0.ingredients }
            .reduce(into: [:]) { counts, item in counts[item, default: 0] += 1 }
            .map { "\($0.key) x\($0.value)" }
    }

    // Separated list view to aid type-checking
    private var ingredientList: some View {
        List {
            ForEach(allIngredients.sorted(), id: \.self) { item in
                HStack {
                    Image(systemName: checkedItems.contains(item) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(checkedItems.contains(item) ? Color.brandPurple : Color.secondary)
                    Text(item)
                        .font(Font.body)
                        .foregroundColor(Color.primary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if checkedItems.contains(item) {
                        checkedItems.remove(item)
                    } else {
                        checkedItems.insert(item)
                    }
                }
            }
        }
    }

    var body: some View {
        NavigationView {
            ingredientList
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .background(Color.primaryBackground)
                .navigationTitle("Shopping List")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
                .sheet(isPresented: $showingShareSheet) {
                    let shareText = allIngredients.joined(separator: "\n")
                    ActivityView(activityItems: [shareText])
                }
        }
    }
}
