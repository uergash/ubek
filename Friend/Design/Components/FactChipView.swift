import SwiftUI

struct FactChipView: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkle")
                .font(.system(size: 10, weight: .semibold))
                .opacity(0.85)
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(Color.accentDeep)
        .padding(.horizontal, 13)
        .padding(.vertical, 7)
        .background(Capsule().fill(Color.accentSoft))
        .fixedSize(horizontal: true, vertical: false)
    }
}

#Preview {
    HStack(spacing: 8) {
        FactChipView(text: "Has a dog named Milo")
        FactChipView(text: "Loves coffee")
    }
    .padding()
    .background(Color.appBackground)
}
