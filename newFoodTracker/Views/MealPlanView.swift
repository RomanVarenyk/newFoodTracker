// MealPlanView.swift

import SwiftUI

// MARK: – Helper: subscript MealPlanDay by slot
private extension MealPlanDay {
    /// Allows `mealPlanDay[slot]` to return the correct Recipe.
    subscript(slot: MealPlanService.MealSlot) -> Recipe {
        switch slot {
        case .breakfast: return breakfast
        case .snack1:    return snack1
        case .lunch:     return lunch
        case .snack2:    return snack2
        case .dinner:    return dinner
        }
    }
}

struct MealPlanView: View {
    @EnvironmentObject var mealService: MealPlanService

    /// Controls presentation of the settings menu
    @State private var showSettings = false

    /// Which day & slot are being edited?
    @State private var editingDay: Int?
    @State private var editingSlot: MealPlanService.MealSlot?

    var body: some View {
        NavigationView {
            List {
                // 1) Iterate days by index
                ForEach(0..<mealService.weeklyPlan.count, id: \.self) { dayIndex in
                    Section(header: Text("Day \(dayIndex + 1)")) {
                        // 2) Iterate all slots
                        ForEach(MealPlanService.MealSlot.allCases) { slot in
                            MealSlotRow(
                                day: dayIndex,
                                slot: slot,
                                editingDay: $editingDay,
                                editingSlot: $editingSlot
                            )
                            .environmentObject(mealService)
                        }
                    }
                }
            }
            .navigationTitle("Weekly Plan")
            // Settings button in the navigation bar
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            // Present SettingsView when tapped
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(mealService)
            }
            // 3) Sheet for swapping when a slot is tapped
            .sheet(item: $editingSlot) { slot in
                if let dayIndex = editingDay {
                    RecipePickerView(
                        slot: slot,
                        dayIndex: dayIndex,
                        onSelect: { newRecipe in
                            mealService.swapMeal(dayIndex: dayIndex, slot: slot, with: newRecipe)
                            editingDay = nil
                            editingSlot = nil
                        }
                    )
                    .environmentObject(mealService)
                }
            }
        }
    }
}

/// A single tappable row for one slot on a given day.
struct MealSlotRow: View {
    @EnvironmentObject var mealService: MealPlanService

    let day: Int
    let slot: MealPlanService.MealSlot
    @Binding var editingDay: Int?
    @Binding var editingSlot: MealPlanService.MealSlot?

    var body: some View {
        // Subscript MealPlanDay by slot to get the Recipe
        let recipe = mealService.weeklyPlan[day][slot]

        HStack {
            Text(slot.title).bold()
            Spacer()
            Text(recipe.name)
                .foregroundColor(.orange)
        }
        .contentShape(Rectangle()) // so the whole row is tappable
        .onTapGesture {
            editingDay = day
            editingSlot = slot
        }
    }
}
