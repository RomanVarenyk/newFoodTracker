import SwiftUI

class ViewRouter: ObservableObject {
    enum Route {
        case onboarding, home
    }
    @Published var currentRoute: Route = .onboarding
}
