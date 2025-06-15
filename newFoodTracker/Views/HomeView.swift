import SwiftUI

struct HomeView: View {
    var body: some View {
        WeeklyPlanOverviewView()
            .environmentObject(MealPlanService())
    }
}
