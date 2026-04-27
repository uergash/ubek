import SwiftUI

// Color palette — sRGB approximations of the OKLCH values from the Claude Design files.
// Warm/terracotta aesthetic: cream app background, white cards (with a
// hairline border for crisp edges), warm accent.
extension Color {
    // Surfaces
    static let appBackground   = Color(red: 0.984, green: 0.973, blue: 0.953) // oklch(0.985 0.008 75)
    static let card            = Color.white
    static let cardSoft        = Color(red: 0.957, green: 0.945, blue: 0.922) // oklch(0.97 0.012 75)

    // Text
    static let ink             = Color(red: 0.184, green: 0.169, blue: 0.149) // oklch(0.22 0.012 60)
    static let inkSoft         = Color(red: 0.302, green: 0.282, blue: 0.259) // oklch(0.36 0.012 60)
    static let muted           = Color(red: 0.486, green: 0.467, blue: 0.443) // oklch(0.55 0.012 60)

    // Lines & chips
    static let hairline        = Color(red: 0.910, green: 0.894, blue: 0.875) // oklch(0.92 0.01 70)
    static let chipBg          = Color(red: 0.929, green: 0.914, blue: 0.882) // oklch(0.94 0.012 70)

    // Accent (warm terracotta)
    static let accent          = Color(red: 0.847, green: 0.471, blue: 0.337) // oklch(0.66 0.13 40)
    static let accentDeep      = Color(red: 0.580, green: 0.247, blue: 0.145) // oklch(0.46 0.11 38)
    static let accentSoft      = Color(red: 0.957, green: 0.886, blue: 0.812) // oklch(0.94 0.04 50)
    static let accentTint      = Color(red: 0.973, green: 0.929, blue: 0.886) // oklch(0.96 0.025 50)

    // Health indicator
    static let healthGreen     = Color(red: 0.341, green: 0.722, blue: 0.478) // oklch(0.7 0.13 145)
    static let healthYellow    = Color(red: 0.851, green: 0.694, blue: 0.306) // oklch(0.8 0.14 85)
    static let healthRed       = Color(red: 0.831, green: 0.353, blue: 0.212) // oklch(0.62 0.18 28)

    /// Returns a soft → deeper gradient for an avatar based on hue (0-360).
    /// Mirrors the `linear-gradient(135deg, oklch(0.86 0.07 H) → oklch(0.74 0.11 H+30))` from the design.
    static func avatarColors(hue: Int) -> (Color, Color) {
        let h1 = Double(hue % 360) / 360.0
        let h2 = Double((hue + 30) % 360) / 360.0
        return (
            Color(hue: h1, saturation: 0.30, brightness: 0.92),
            Color(hue: h2, saturation: 0.45, brightness: 0.78)
        )
    }
}

// Shadow used on cards throughout the app.
struct CardShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(0.025), radius: 1, x: 0, y: 1)
            .shadow(color: Color.black.opacity(0.035), radius: 22, x: 0, y: 6)
    }
}

extension View {
    func cardShadow() -> some View { modifier(CardShadow()) }
}

// Section-header styling shared across screens.
extension Text {
    func sectionLabel() -> some View {
        self
            .font(.system(size: 13, weight: .semibold))
            .tracking(0.78) // ~0.06em at 13pt
            .foregroundStyle(Color.muted)
            .textCase(.uppercase)
    }
}
