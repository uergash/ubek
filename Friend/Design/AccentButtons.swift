import SwiftUI

/// Three-tier button hierarchy used across the app.
///
/// - **Primary** — terracotta-filled, white text. Reserve for true CTAs
///   (e.g. the FAB).
/// - **Secondary** — cream-filled, terracotta outline + text. The default
///   for inline actions like "Send text" so the brand color is present
///   without dominating the layout.
/// - **Tertiary** — terracotta text, no background. For lower-emphasis
///   actions like "Open profile".

struct AccentPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13.5, weight: .semibold))
            .foregroundStyle(Color.appBackground)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(Color.accent))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

struct AccentSecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13.5, weight: .semibold))
            .foregroundStyle(Color.accent)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(Color.appBackground))
            .overlay(Capsule().stroke(Color.accent, lineWidth: 1.5))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

struct AccentTertiaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13.5, weight: .semibold))
            .foregroundStyle(Color.accent)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}

/// Full-width "large" variants — the empty state, onboarding flows, and
/// account-level destructive actions. Same hierarchy semantics as the inline
/// tier above, just sized to dominate their container.
struct AccentPrimaryLargeButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.appBackground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.accent)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

struct AccentSecondaryLargeButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.accent, lineWidth: 1.5)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
