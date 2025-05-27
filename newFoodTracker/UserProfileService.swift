//
//  UserProfileService.swift
//  newFoodTracker
//

import Foundation
import Combine

/// A singleton that holds the user’s profile for the rest of the app to read/write.
class UserProfileService: ObservableObject {
    static let shared = UserProfileService()
    
    /// The profile the rest of your app reads from / writes to
    @Published var currentProfile = UserProfile()
    
    private init() { }
}
