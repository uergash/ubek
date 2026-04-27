import SwiftUI

/// Paged carousel of reach-out nudges. One full card visible at a time;
/// swipe horizontally or tap a page dot to navigate. Eliminates the
/// navigation/content disconnect of the previous pill+card design — each
/// card *is* the unit.
@MainActor
struct NudgesStripView: View {
    let suggestions: [PeopleViewModel.Suggestion]
    var onOpenPerson: (Person) -> Void
    var onDismiss: (UUID) -> Void

    @Environment(\.openURL) private var openURL
    @State private var currentIndex: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeaderView(
                title: "Nudges",
                action: "\(suggestions.count) new"
            )

            // Native paging behaviour (swipe + accessibility), default dots
            // hidden so we can render brand-coloured ones below.
            TabView(selection: $currentIndex) {
                ForEach(Array(suggestions.enumerated()), id: \.element.id) { idx, s in
                    card(s)
                        .padding(.bottom, 4) // breathing room above page dots
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 210)
            .animation(.easeInOut(duration: 0.2), value: currentIndex)

            if suggestions.count > 1 {
                pageDots
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 22)
        .onChange(of: suggestions.map(\.id)) { _, _ in
            // Keep currentIndex valid after a dismiss removes a card.
            currentIndex = min(currentIndex, max(0, suggestions.count - 1))
        }
    }

    // ─── Page dots ─────────────────────────────────────────────────────────
    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<suggestions.count, id: \.self) { idx in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentIndex = idx
                    }
                } label: {
                    Circle()
                        .fill(idx == currentIndex ? Color.accent : Color.muted.opacity(0.3))
                        .frame(width: idx == currentIndex ? 8 : 6,
                               height: idx == currentIndex ? 8 : 6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // ─── Card ──────────────────────────────────────────────────────────────
    private func card(_ s: PeopleViewModel.Suggestion) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    AvatarView(person: s.person, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(s.person.firstName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.ink)
                        Text(daysSubtitle(s.person))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.muted)
                    }
                    Spacer()
                    Button {
                        // Dismiss; .onChange clamps currentIndex if needed.
                        onDismiss(s.person.id)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.muted)
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                }

                Text(s.suggestion)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.inkSoft)
                    .lineSpacing(2)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let url = smsURL(for: s.person) {
                    HStack {
                        Spacer()
                        Button { openURL(url) } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Send text")
                            }
                        }
                        .buttonStyle(AccentSecondaryButton())
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onOpenPerson(s.person) }
    }

    private func daysSubtitle(_ p: Person) -> String {
        guard let d = p.daysSinceLastInteraction() else { return "No interactions logged yet" }
        return d == 1 ? "1 day since last interaction" : "\(d) days since last interaction"
    }

    /// `sms:` URL with the recipient's phone — opens Messages with a draft.
    /// Returns nil when the person has no phone on file.
    private func smsURL(for person: Person) -> URL? {
        guard let raw = person.phone, !raw.isEmpty else { return nil }
        let allowed = CharacterSet(charactersIn: "+0123456789")
        let cleaned = raw.unicodeScalars.filter { allowed.contains($0) }.map(String.init).joined()
        guard !cleaned.isEmpty else { return nil }
        return URL(string: "sms:\(cleaned)")
    }
}
