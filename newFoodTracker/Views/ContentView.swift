import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // 1. Weekly Plan
            NavigationView {
                WeeklyPlanOverviewView()
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("Week")
            }

            // 2. Macros (Editable)
            NavigationView {
                MacroCalculatorView()
            }
            .tabItem {
                Image(systemName: "gauge")
                Text("Macros")
            }

            // 3. Recipes
            NavigationView {
                RecipesView()
            }
            .tabItem {
                Image(systemName: "book")
                Text("Recipes")
            }

            // 4. Shopping List
            NavigationView {
                ShoppingListView()
            }
            .tabItem {
                Image(systemName: "cart")
                Text("Shopping")
            }

            // 5. Settings
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gearshape")
                Text("Settings")
            }
        }
        .accentColor(.brandPurple)
        .background(Color.primaryBackground.ignoresSafeArea())
    }
}
