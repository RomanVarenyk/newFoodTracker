//
//  VisionService.swift
//  newFoodTracker
//
//  Created by Roman Bystriakov on 2025-05-26.
//

import Foundation
import UIKit

/// A singleton wrapper around `OpenAIService` to perform image-based nutrition estimates.
final class VisionService {
    static let shared = VisionService()
    private init() {}

    /// Take a `UIImage`, compress it to JPEG, then forward to `OpenAIService.analyzeImageNutrition`.
    func analyze(
        uiImage: UIImage,
        description: String?,
        completion: @escaping (Result<(calories: Int, protein: Int, carbs: Int, fat: Int), Error>) -> Void
    ) {
        guard let data = uiImage.jpegData(compressionQuality: 0.8) else {
            let err = NSError(
                domain: "VisionService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"]
            )
            completion(.failure(err))
            return
        }

        OpenAIService.shared.analyzeImageNutrition(
            imageData: data,
            description: description,
            completion: completion
        )
    }
}
