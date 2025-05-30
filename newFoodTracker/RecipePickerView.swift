//
//  RecipePickerView.swift
//  newFoodTracker
//
//  Created by Roman Bystriakov on 26/5/25.
//


import SwiftUI

/// Presents all recipes for the user to pick one.
struct RecipePickerView: View {
    @EnvironmentObject var recipeService: RecipeService
    let slot: MealPlanService.MealSlot
    let dayIndex: Int
    let onSelect: (Recipe) -> Void

    var body: some View {
        NavigationView {
            List(recipeService.recipes) { recipe in
                Button {
                    onSelect(recipe)
                } label: {
                    HStack {
                        Text(recipe.name)
                        Spacer()
                        if let cal = recipe.calories {
                            Text("\(cal) cal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Choose \(slot.title)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onSelect(recipeService.recipes[0]) // dummy; sheet will dismiss
                    }
                }
            }
        }
    }
}
