import Foundation
import SwiftUI

/// Wraps the existing OpenAIService to analyze images for nutrition.
class VisionService {
    static let shared = VisionService()

    /// Calls OpenAIService.analyzeImageNutrition under the hood.
    func analyze(
        uiImage: UIImage,
        description: String?,
        completion: @escaping (Result<(calories: Int, protein: Int, carbs: Int, fat: Int), Error>) -> Void
    ) {
        guard let data = uiImage.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(
                domain: "VisionService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Image conversion failed"]
            )))
            return
        }
        OpenAIService.shared.analyzeImageNutrition(
            imageData: data,
            description: description,
            completion: completion
        )
    }
}
