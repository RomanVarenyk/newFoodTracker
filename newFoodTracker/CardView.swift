import SwiftUI

/// A reusable gradient card style for recipe & plan cards.
struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color("CardStart"), Color("CardEnd")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
            content
                .padding()
        }
    }
}
