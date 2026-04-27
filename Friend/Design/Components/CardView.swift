import SwiftUI

/// White rounded card with the app's standard shadow.
/// Pass `padded: false` to manage padding internally (e.g. list rows).
struct CardView<Content: View>: View {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 20
    @ViewBuilder var content: Content

    init(padding: CGFloat = 16, cornerRadius: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.hairline, lineWidth: 1)
            )
            .cardShadow()
    }
}

#Preview {
    VStack(spacing: 14) {
        CardView {
            Text("A simple card")
                .font(.system(size: 15))
        }
        CardView(padding: 0) {
            VStack(spacing: 0) {
                Text("Row 1").padding()
                Divider()
                Text("Row 2").padding()
            }
        }
    }
    .padding()
    .background(Color.appBackground)
}
