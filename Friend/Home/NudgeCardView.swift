import SwiftUI

struct NudgeCardView: View {
    let nudge: HomeViewModel.Nudge
    var onTap: () -> Void
    @Environment(\.openURL) private var openURL
    @State private var reporting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                AvatarView(person: nudge.person, size: 42)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(nudge.person.firstName)
                            .font(.system(size: 14.5, weight: .semibold))
                            .foregroundStyle(Color.ink)
                        suggestedBadge
                    }
                    Text(nudge.suggestion)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.inkSoft)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }

            if let url = smsURL(for: nudge.person) {
                HStack {
                    Spacer()
                    sendTextButton(url: url)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.hairline, lineWidth: 1)
        )
        .cardShadow()
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .contextMenu {
            Button(role: .destructive) {
                reporting = true
            } label: {
                Label("Report this output", systemImage: "flag")
            }
        }
        .sheet(isPresented: $reporting) {
            AIReportSheet(
                kind: .nudge,
                content: nudge.suggestion,
                personId: nudge.person.id
            )
        }
    }

    /// Compact icon + label "Send text" button anchored to the bottom-right of the card.
    private func sendTextButton(url: URL) -> some View {
        Button { openURL(url) } label: {
            HStack(spacing: 6) {
                Image(systemName: "message.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("Send text")
            }
        }
        .buttonStyle(AccentSecondaryButton())
    }

    private var suggestedBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "sparkles")
                .font(.system(size: 9, weight: .semibold))
            Text("SUGGESTED")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.4)
        }
        .foregroundStyle(Color.accent)
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(Capsule().fill(Color.accentSoft))
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
