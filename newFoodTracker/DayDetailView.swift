// DayDetailView.swift

import SwiftUI

struct DayDetailView: View {
    @EnvironmentObject var mealService: MealPlanService
    let dayIndex: Int

    // eaten map: slot → Bool
    @State private var eaten: [MealPlanService.MealSlot: Bool] = [:]
    @State private var showingCamera = false
    @State private var cameraSlot: MealPlanService.MealSlot?

    var plan: MealPlanDay { mealService.weeklyPlan[dayIndex] }

    var body: some View {
        List {
            ForEach(MealPlanService.MealSlot.allCases) { slot in
                let recipe = plan[slot]
                HStack {
                    VStack(alignment: .leading) {
                        Text(slot.title).bold()
                        Text(recipe.name).font(.subheadline)
                        HStack(spacing: 8) {
                            Text("\(recipe.calories ?? 0) kcal").font(.caption)
                            Text("\(recipe.protein ?? 0)P").font(.caption)
                        }
                    }
                    Spacer()
                    Button {
                        cameraSlot = slot
                        showingCamera = true
                    } label: {
                        Image(systemName: "camera")
                    }
                    .padding(.trailing)

                    Button(action: {
                        eaten[slot]?.toggle()
                    }) {
                        Image(systemName:
                            (eaten[slot] ?? false)
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                        .foregroundColor(.green)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Day \(dayIndex+1) Details")
        .sheet(isPresented: $showingCamera) {
            if let slot = cameraSlot {
                CameraNutritionView(slot: slot,
                                    dayIndex: dayIndex,
                                    eaten: $eaten[slot],
                                    onUpdate: { cals, prot, carbs, fat in
                    // override recipe macros, etc.
                })
            }
        }
    }
}

/// Replace this stub with your camera / image‐to‐macros implementation.
struct CameraNutritionView: View {
    let slot: MealPlanService.MealSlot
    let dayIndex: Int
    @Binding var eaten: Bool?
    let onUpdate: (Int,Int,Int,Int) -> Void

    @Environment(\.presentationMode) var pm

    var body: some View {
        VStack(spacing: 16) {
            Text("Snap & Estimate \(slot.title)")
                .font(.headline)
            Button("Take Photo") {
                // present your camera and call VisionService.shared.analyze → onUpdate
            }
            Button("Done") { pm.wrappedValue.dismiss() }
        }
        .padding()
    }
}
