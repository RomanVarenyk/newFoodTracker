import Foundation

class UserProfileService: ObservableObject {
    static let shared = UserProfileService()
    @Published var currentProfile = UserProfile()
    private init() {}
}
