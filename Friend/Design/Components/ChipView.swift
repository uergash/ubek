import SwiftUI

struct ChipView: View {
    let label: String
    var icon: String? = nil
    var isActive: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(isActive ? Color.appBackground : Color.ink)
            .padding(.horizontal, 13)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(isActive ? Color.ink : Color.chipBg)
            )
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
    }
}

#Preview {
    HStack(spacing: 8) {
        ChipView(label: "All", isActive: true)
        ChipView(label: "Family")
        ChipView(label: "Friends", icon: "person.2.fill")
    }
    .padding()
    .background(Color.appBackground)
}
