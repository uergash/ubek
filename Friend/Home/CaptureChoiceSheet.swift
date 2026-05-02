import SwiftUI

enum CaptureChoice {
    case story, note
}

@MainActor
struct CaptureChoiceSheet: View {
    var onChoose: (CaptureChoice) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.hairline)
                .frame(width: 36, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 18)

            Text("What are you adding?")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.ink)
                .padding(.bottom, 18)

            VStack(spacing: 12) {
                choiceRow(
                    icon: "sparkles",
                    title: "New story",
                    subtitle: "Jot an anecdote about you \u{2014} for the next \u{201C}what\u{2019}s new?\u{201D}",
                    choice: .story
                )
                choiceRow(
                    icon: "person.text.rectangle",
                    title: "New note",
                    subtitle: "Log an interaction with someone — call, coffee, text, event.",
                    choice: .note
                )
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(Color.appBackground)
        .presentationDetents([.height(330)])
        .presentationDragIndicator(.hidden)
    }

    private func choiceRow(
        icon: String,
        title: String,
        subtitle: String,
        choice: CaptureChoice
    ) -> some View {
        Button {
            onChoose(choice)
            dismiss()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.accent))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.ink)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.muted)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.muted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.card))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.hairline, lineWidth: 1))
            .cardShadow()
        }
        .buttonStyle(.plain)
    }
}
