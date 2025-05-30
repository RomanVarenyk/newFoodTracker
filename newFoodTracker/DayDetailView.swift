//
//  DayDetailView.swift
//  newFoodTracker
//
//  Created by You on 2025-05-28.
//

import SwiftUI

struct DayDetailView: View {
    @EnvironmentObject var mealService: MealPlanService
    let dayIndex: Int

    @State private var showingRecipePicker = false
    @State private var pickerSlot: MealPlanService.MealSlot?

    @State private var showingCamera = false
    @State private var cameraSlot: MealPlanService.MealSlot?

    // Helper to get or set a meal
    private var plan: MealPlanDay {
        mealService.weeklyPlan[dayIndex]
    }

    private func recipe(for slot: MealPlanService.MealSlot) -> Recipe {
        plan[slot]
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(MealPlanService.MealSlot.allCases, id: \.self) { slot in
                    CardView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(slot.title)
                                .font(.headline)
                            Text(recipe(for: slot).name)
                                .font(.subheadline)
                            HStack(spacing: 8) {
                                Text("\(recipe(for: slot).protein ?? 0)P")
                                    .font(.caption)
                                Text("\(recipe(for: slot).fat ?? 0)F")
                                    .font(.caption)
                                Text("\(recipe(for: slot).carbs ?? 0)C")
                                    .font(.caption)
                                Text("\(recipe(for: slot).calories ?? 0)kcal")
                                    .font(.caption)
                            }
                            HStack(spacing: 12) {
                                Button("Replace") {
                                    pickerSlot = slot
                                    showingRecipePicker = true
                                }
                                Button("Remove") {
                                    // Replace with an empty recipe stub
                                    let empty = Recipe(name: "None", ingredients: [], instructions: "")
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
                    .frame(height: 180)
                }
            }
            .padding()
        }
        .navigationTitle("Day \(dayIndex + 1)")
        // Recipe picker sheet
        .sheet(isPresented: $showingRecipePicker) {
            if let slot = pickerSlot {
                RecipePickerView(
                    slot: slot,
                    dayIndex: dayIndex,
                    onSelect: { newRecipe in
                        mealService.swapMeal(dayIndex: dayIndex, slot: slot, with: newRecipe)
                        showingRecipePicker = false
                        pickerSlot = nil
                    }
                )
                .environmentObject(mealService)
            }
        }
        // Camera nutrition sheet
        .sheet(isPresented: $showingCamera) {
            if let slot = cameraSlot {
                CameraNutritionView(
                    slot: slot,
                    dayIndex: dayIndex,
                    eaten: .constant(false),
                    onUpdate: { cals, prot, carbs, fat in
                        var r = recipe(for: slot)
                        r.calories = cals
                        r.protein  = prot
                        r.carbs    = carbs
                        r.fat      = fat
                        mealService.swapMeal(dayIndex: dayIndex, slot: slot, with: r)
                        showingCamera = false
                        cameraSlot = nil
                    }
                )
            }
        }
    }
}

struct CameraNutritionView: View {
    let slot: MealPlanService.MealSlot
    let dayIndex: Int
    @Binding var eaten: Bool
    let onUpdate: (Int,Int,Int,Int) -> Void
    @Environment(\.presentationMode) var pm

    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Nutrition Information")) {
                    TextField("Calories", text: $calories)
                        .keyboardType(.numberPad)
                    TextField("Protein (g)", text: $protein)
                        .keyboardType(.numberPad)
                    TextField("Carbohydrates (g)", text: $carbs)
                        .keyboardType(.numberPad)
                    TextField("Fat (g)", text: $fat)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Camera Nutrition")
            .navigationBarItems(leading: Button("Cancel") {
                pm.wrappedValue.dismiss()
            }, trailing: Button("Save") {
                let cals = Int(calories) ?? 0
                let prot = Int(protein) ?? 0
                let carb = Int(carbs) ?? 0
                let f = Int(fat) ?? 0
                onUpdate(cals, prot, carb, f)
                eaten = true
                pm.wrappedValue.dismiss()
            })
        }
    }
}

struct DayDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DayDetailView(dayIndex: 0)
                .environmentObject(MealPlanService())
        }
    }
}
