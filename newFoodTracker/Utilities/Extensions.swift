import SwiftUI
import UIKit

// MARK: - UIImage Resize Helper
extension UIImage {
    /// Resize this image to the specified max dimension (keeping aspect ratio) and then JPEG-compress.
    func resizedJPEGData(maxDimension: CGFloat = 256, compressionQuality: CGFloat = 0.6) -> Data? {
        let aspectRatio = size.width / size.height
        let targetSize: CGSize
        if aspectRatio > 1 {
            targetSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            targetSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        draw(in: CGRect(origin: .zero, size: targetSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage?.jpegData(compressionQuality: compressionQuality)
    }
}

// MARK: - Theme Extensions
extension Color {
    static let brandPurple     = Color(red: 128/255, green: 87/255, blue: 231/255)
    static let backgroundGray  = Color(UIColor.systemGray5)
    static let cardBackground  = Color(UIColor.secondarySystemBackground)
    static let textPrimary     = Color.black.opacity(0.85)
    static let textSecondary   = Color.gray
    static let primaryBackground = Color(UIColor.systemBackground)
}

extension Font {
    static let heading = Font.system(size: 20, weight: .semibold)
    static let subhead = Font.system(size: 16, weight: .medium)
    static let body    = Font.system(size: 14, weight: .regular)
}

// Helper for SwiftUI share sheet
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
