import SwiftUI

/// Loading indicator used on Home and People while their data assembles.
/// Three avatar-tinted dots orbit a shared center — evokes "people coming
/// together" without leaning on a generic spinner. Driven by TimelineView
/// so the animation runs continuously without state churn.
struct BreathingCirclesView: View {
    let caption: String

    /// Warm hues that read as a small group of "people" against the cream background.
    private let hues: [Int] = [20, 50, 350]
    private let orbitRadius: CGFloat = 20
    private let dotSize: CGFloat = 14
    /// Seconds per full revolution. Slow enough to feel calm, fast enough
    /// that the loader doesn't read as stalled.
    private let period: Double = 1.6

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let baseAngle = (t / period) * 2 * .pi
            VStack(spacing: 24) {
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        // Evenly space the three dots 120° apart on the orbit.
                        let angle = baseAngle + Double(i) * (2 * .pi / 3)
                        Circle()
                            .fill(gradient(for: i))
                            .frame(width: dotSize, height: dotSize)
                            .offset(
                                x: CGFloat(cos(angle)) * orbitRadius,
                                y: CGFloat(sin(angle)) * orbitRadius
                            )
                            .shadow(color: Color.accent.opacity(0.18), radius: 6)
                    }
                }
                .frame(width: orbitRadius * 2 + dotSize, height: orbitRadius * 2 + dotSize)
                Text(caption)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(Color.muted)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, minHeight: 360)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(caption)
    }

    private func gradient(for index: Int) -> LinearGradient {
        let (a, b) = Color.avatarColors(hue: hues[index])
        return LinearGradient(
            colors: [a, b],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    BreathingCirclesView(caption: "Catching up with your people…")
        .background(Color.appBackground)
}
