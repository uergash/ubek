import SwiftUI

enum MainTab: String, CaseIterable, Hashable {
    case home, stories, people, settings
}

/// Bottom tab bar with a centered accent FAB for the new-note action.
/// Mirrors the design's `TabBar` primitive.
struct MainTabBar: View {
    @Binding var active: MainTab
    /// Fires on every tab tap, including taps on the already-active tab — the
    /// caller uses this to pop to root.
    var onSelect: (MainTab) -> Void = { _ in }
    var onAdd: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.home, icon: "house", label: "Home")
            tabButton(.people, icon: "person.2", label: "People")
            addButton
            tabButton(.stories, icon: "sparkles", label: "Stories")
            tabButton(.settings, icon: "gearshape", label: "Settings")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(
            Color.appBackground
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.hairline)
                        .frame(height: 0.5)
                }
        )
    }

    private func tabButton(_ tab: MainTab, icon: String, label: String) -> some View {
        let isActive = active == tab
        return Button {
            active = tab
            onSelect(tab)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: isActive ? .semibold : .regular))
                Text(label)
                    .font(.system(size: 10.5, weight: .medium))
            }
            .foregroundStyle(isActive ? Color.accent : Color.accent.opacity(0.4))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tab_\(tab.rawValue)")
    }

    private var addButton: some View {
        Button(action: onAdd) {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(Circle().fill(Color.accent))
                .shadow(color: Color.accent.opacity(0.4), radius: 16, x: 0, y: 4)
                .offset(y: -22)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("plus")
        .accessibilityLabel("New note")
    }
}

private struct MainTabBarPreview: View {
    @State private var tab: MainTab = .home
    var body: some View {
        VStack {
            Spacer()
            MainTabBar(active: $tab, onAdd: {})
        }
        .background(Color.appBackground)
    }
}

#Preview { MainTabBarPreview() }
