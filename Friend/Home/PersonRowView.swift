import SwiftUI

struct PersonRowView: View {
    let person: Person
    let healthState: HealthState
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AvatarView(person: person, size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text(person.name)
                        .font(.system(size: 15.5, weight: .semibold))
                        .foregroundStyle(Color.ink)
                    Text(subtitle)
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color.muted)
                }
                Spacer(minLength: 0)
                HealthDotView(state: healthState)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var subtitle: String {
        if person.lastInteractionAt == nil {
            return "\(person.relation) · No notes yet"
        }
        return "\(person.relation) · \(lastInteractionLabel(person.daysSinceLastInteraction()))"
    }
}

func lastInteractionLabel(_ days: Int?) -> String {
    guard let days else { return "No interactions yet" }
    if days <= 0 { return "Today" }
    if days == 1 { return "Yesterday" }
    if days < 7 { return "\(days) days ago" }
    if days < 14 { return "1 week ago" }
    if days < 28 { return "\(days / 7) weeks ago" }
    if days < 60 { return "1 month ago" }
    return "\(days / 30) months ago"
}
