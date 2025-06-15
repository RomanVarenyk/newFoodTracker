//
//  ContentView.swift
//  newFoodTracker
//
//  Created by Roman Bystriakov on 26/5/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @State private var showingSettings = false

    @EnvironmentObject var userProfile: UserProfile
    @EnvironmentObject var mealService: MealPlanService

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color("BackgroundStart"), Color("BackgroundEnd")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Always show HomeView; settings sheet appears on first launch
                HomeView()
            }
            .navigationBarItems(trailing:
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape")
                }
            )
        }
        .onAppear {
            if !hasLaunchedBefore {
                showingSettings = true
            }
        }
        .sheet(isPresented: $showingSettings, onDismiss: {
            hasLaunchedBefore = true
        }) {
            SettingsView()
                .environmentObject(userProfile)
                .environmentObject(mealService)
        }
    }
}
