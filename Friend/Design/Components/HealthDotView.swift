import SwiftUI

struct HealthDotView: View {
    let state: HealthState
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
    }

    private var color: Color {
        switch state {
        case .green:  return .healthGreen
        case .yellow: return .healthYellow
        case .red:    return .healthRed
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        HealthDotView(state: .green)
        HealthDotView(state: .yellow)
        HealthDotView(state: .red)
    }
    .padding()
}
