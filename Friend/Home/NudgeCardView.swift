import SwiftUI
import UIKit

struct NudgeCardView: View {
    let nudge: HomeViewModel.Nudge
    var onTap: () -> Void
    @Environment(\.openURL) private var openURL
    @State private var reporting = false
    @State private var didCopy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                AvatarView(person: nudge.person, size: 42)
                Text(nudge.person.firstName)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(Color.ink)
                Spacer(minLength: 0)
            }

            suggestedStartLabel

            Text(nudge.suggestion)
                .font(.system(size: 14))
                .foregroundStyle(Color.inkSoft)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                Spacer()
                copyButton
                if let url = smsURL(for: nudge.person, body: nudge.suggestion) {
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

    /// "Send text" button anchored to the bottom-right of the card.
    private func sendTextButton(url: URL) -> some View {
        Button("Send text") { openURL(url) }
            .buttonStyle(AccentSecondaryButton())
    }

    /// Copies the drafted message to the clipboard. Briefly flips the label
    /// to "Copied" so the action feels acknowledged.
    private var copyButton: some View {
        Button(didCopy ? "Copied" : "Copy") {
            UIPasteboard.general.string = nudge.suggestion
            didCopy = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { didCopy = false }
        }
        .buttonStyle(AccentTertiaryButton())
        .animation(.easeInOut(duration: 0.15), value: didCopy)
    }

    private var suggestedStartLabel: some View {
        HStack(spacing: 5) {
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .semibold))
            Text("SUGGESTED START")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.6)
        }
        .foregroundStyle(Color.accent)
    }

    /// `sms:` URL with recipient + pre-filled body — opens Messages with the
    /// drafted text ready to send. Returns nil when the person has no phone.
    /// iOS expects `sms:NUMBER&body=...` (ampersand, not query separator).
    private func smsURL(for person: Person, body: String) -> URL? {
        guard let raw = person.phone, !raw.isEmpty else { return nil }
        let allowed = CharacterSet(charactersIn: "+0123456789")
        let cleaned = raw.unicodeScalars.filter { allowed.contains($0) }.map(String.init).joined()
        guard !cleaned.isEmpty else { return nil }
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "sms:\(cleaned)&body=\(encodedBody)")
    }
}
