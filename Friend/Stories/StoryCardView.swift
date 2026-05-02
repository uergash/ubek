import SwiftUI

@MainActor
struct StoryCardView: View {
    let story: Story

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dateLabel)
                .font(.system(size: 11.5, weight: .semibold))
                .tracking(0.7)
                .foregroundStyle(Color.muted)
            Text(story.body)
                .font(.system(size: 15))
                .foregroundStyle(Color.ink)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.card))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.hairline, lineWidth: 1))
        .cardShadow()
    }

    private var dateLabel: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: story.createdAt, relativeTo: Date()).uppercased()
    }
}
