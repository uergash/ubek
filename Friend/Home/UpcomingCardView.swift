import SwiftUI

struct UpcomingCardView: View {
    let person: Person
    let date: ImportantDate
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    AvatarView(person: person, size: 40)
                    Spacer()
                    Text(daysBadge)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.accentDeep)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.accentSoft))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(person.firstName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.ink)
                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: date.kind.iconName)
                            .font(.system(size: 11))
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(date.label)
                                .font(.system(size: 12.5, weight: .medium))
                                .lineLimit(1)
                            Text(date.formattedDate)
                                .font(.system(size: 12.5))
                        }
                    }
                    .foregroundStyle(Color.muted)
                }
            }
            .padding(14)
            .frame(width: 158, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.hairline, lineWidth: 1)
            )
            .cardShadow()
        }
        .buttonStyle(.plain)
    }

    private var daysBadge: String {
        switch date.daysUntilNext {
        case 0: return "Today"
        case 1: return "1d"
        default: return "\(date.daysUntilNext)d"
        }
    }
}
