import SwiftUI

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.subhead)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.brandPurple)
            .foregroundColor(.white)
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
