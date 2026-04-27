import SwiftUI

/// "Person of the day" card on the People page. Warm, celebratory framing —
/// distinct from the urgency-driven Nudges strip below it.
@MainActor
struct SpotlightCardView: View {
    let spotlight: PeopleViewModel.Spotlight
    var onOpenPerson: (Person) -> Void

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeaderView(title: "Today's spotlight")
                .padding(.horizontal, 22)

            CardView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        AvatarView(person: spotlight.person, size: 56)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(spotlight.person.name)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Color.ink)
                            Text(subtitle)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.muted)
                        }
                        Spacer(minLength: 0)
                    }

                    Text(spotlight.highlight)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.ink)
                        .lineSpacing(4)
                        .padding(.vertical, 4)

                    if let url = smsURL(for: spotlight.person) {
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
            .padding(.horizontal, 22)
            .contentShape(Rectangle())
            .onTapGesture { onOpenPerson(spotlight.person) }
        }
    }

    /// "Friend · last connected yesterday" / "Friend · no interactions yet".
    private var subtitle: String {
        if spotlight.person.daysSinceLastInteraction() == nil {
            return "\(spotlight.person.relation) · no interactions yet"
        }
        let lastLabel = lastInteractionLabel(spotlight.person.daysSinceLastInteraction())
        return "\(spotlight.person.relation) · last connected \(lastLabel.lowercased())"
    }

    private func smsURL(for person: Person) -> URL? {
        guard let raw = person.phone, !raw.isEmpty else { return nil }
        let allowed = CharacterSet(charactersIn: "+0123456789")
        let cleaned = raw.unicodeScalars.filter { allowed.contains($0) }.map(String.init).joined()
        guard !cleaned.isEmpty else { return nil }
        return URL(string: "sms:\(cleaned)")
    }
}
