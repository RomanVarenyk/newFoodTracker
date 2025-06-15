//
//  RecipesView.swift
//  newFoodTracker
//
//  Created by Roman Bystriakov on 26/5/25.
//


import SwiftUI

struct RecipesView: View {
    @EnvironmentObject var recipeService: RecipeService

    var body: some View {
        NavigationView {
            List {
                ForEach(recipeService.recipes) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                        Text(recipe.name)
                    }
                }
            }
            .navigationTitle("Recipes")
        }
    }
}

struct RecipeDetailView: View {
    let recipe: Recipe

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(recipe.name)
                    .font(.title).bold()

                if let url = recipe.imageURL {
                    AsyncImage(url: url) { img in img.resizable().scaledToFit() }
                                      placeholder: { ProgressView() }
                }

                Text("Ingredients")
                    .font(.headline)
                ForEach(recipe.ingredients, id: \.self) {
                    Text("• \($0)")
                }

                Text("Instructions")
                    .font(.headline)
                Text(recipe.instructions)
            }
            .padding()
        }
    }
}
