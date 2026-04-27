import SwiftUI

struct RecentlyEngagedRowView: View {
    let person: Person
    let note: Note
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AvatarView(person: person, size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(person.name)
                            .font(.system(size: 14.5, weight: .semibold))
                            .foregroundStyle(Color.ink)
                        Image(systemName: note.interactionType.iconName)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.muted)
                        Text(note.interactionType.rawValue)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.muted)
                    }
                    Text(relativeTimeLabel(for: note.createdAt))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.muted)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.muted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func relativeTimeLabel(for date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return lastInteractionLabel(days)
    }
}
