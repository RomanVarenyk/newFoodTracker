import SwiftUI

struct RecipesView: View {
    @EnvironmentObject var recipeService: RecipeService
    @State private var showingEditRecipe = false
    @State private var recipeToEdit: Recipe? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(recipeService.recipes) { recipe in
                    HStack {
                        Text(recipe.name)
                            .font(.headline)
                            .padding(.vertical, 8)
                            .foregroundColor(Color.primary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        recipeToEdit = recipe
                        showingEditRecipe = true
                    }
                    .listRowBackground(Color.primaryBackground)
                }
                .onDelete { indexSet in
                    recipeService.recipes.remove(atOffsets: indexSet)
                }
            }
            .navigationTitle("Recipes")
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
            .background(Color.primaryBackground)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        recipeToEdit = nil
                        showingEditRecipe = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditRecipe, onDismiss: {
                recipeToEdit = nil
            }) {
                EditRecipeView(recipe: $recipeToEdit)
                    .environmentObject(recipeService)
            }
        }
    }
}
