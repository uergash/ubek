import SwiftUI

/// Birthday / anniversary celebration card. Two states:
/// - **Expanded**: full takeover card with retrospective summary + stats + CTAs.
/// - **Collapsed**: thin one-line strip ("It's Alex's birthday — tap to expand")
///   when the user dismissed it but we still want to surface the day.
@MainActor
struct OccasionTakeoverView: View {
    let celebration: OccasionCelebration
    /// `true` shows the full card; `false` shows the collapsed strip.
    @Binding var isExpanded: Bool
    var onOpenPerson: (Person) -> Void
    /// Compact mode — used inside a profile's Overview tab where the
    /// surrounding view is already about that person. Slightly tighter
    /// padding and smaller fonts.
    var isCompact: Bool = false

    @Environment(\.openURL) private var openURL

    var body: some View {
        if isExpanded {
            expandedCard
        } else {
            collapsedStrip
        }
    }

    // ─── Expanded card ─────────────────────────────────────────────────────
    private var expandedCard: some View {
        VStack(alignment: .leading, spacing: isCompact ? 14 : 18) {
            HStack(alignment: .center, spacing: 8) {
                occasionBadge
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded = false
                        AnnualSummaryStore.setDismissed(true,
                            personId: celebration.person.id,
                            year: Calendar.current.component(.year, from: Date()),
                            kind: celebration.date.kind)
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.muted)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                AvatarView(person: celebration.person, size: isCompact ? 52 : 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text(celebration.headline)
                        .font(.system(size: isCompact ? 19 : 22, weight: .bold))
                        .tracking(-0.4)
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.leading)
                    Text(occasionSubtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.muted)
                }
                Spacer(minLength: 0)
            }

            Text(celebration.summary)
                .font(.system(size: isCompact ? 14.5 : 15.5))
                .foregroundStyle(Color.ink)
                .lineSpacing(4)

            statsRow
                .padding(.top, 2)

            if let url = smsURL(for: celebration.person) {
                HStack {
                    Spacer()
                    Button { openURL(url) } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text(ctaLabel)
                        }
                    }
                    .buttonStyle(AccentSecondaryButton())
                }
            }
        }
        .padding(isCompact ? 18 : 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.accentSoft, Color.card],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.accent.opacity(0.18), lineWidth: 1)
        )
        .cardShadow()
        // In compact mode the card lives inside the profile already, so opening
        // the profile would be a no-op — leave the card non-tappable there.
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isCompact else { return }
            onOpenPerson(celebration.person)
        }
    }

    // ─── Collapsed strip ───────────────────────────────────────────────────
    private var collapsedStrip: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded = true
                AnnualSummaryStore.setDismissed(false,
                    personId: celebration.person.id,
                    year: Calendar.current.component(.year, from: Date()),
                    kind: celebration.date.kind)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: occasionIcon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accent)
                Text(collapsedCopy)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Color.ink)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.muted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.accentSoft)
            )
        }
        .buttonStyle(.plain)
    }

    // ─── Pieces ────────────────────────────────────────────────────────────
    private var occasionBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: occasionIcon)
                .font(.system(size: 12, weight: .semibold))
            Text(occasionTag)
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.6)
                .textCase(.uppercase)
        }
        .foregroundStyle(Color.accent)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.accent.opacity(0.12)))
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statChip(value: celebration.stats.noteCount, label: celebration.stats.noteCount == 1 ? "note" : "notes")
            divider
            statChip(value: celebration.stats.giftCount, label: celebration.stats.giftCount == 1 ? "gift" : "gifts")
            divider
            statChip(value: celebration.stats.factCount, label: celebration.stats.factCount == 1 ? "fact" : "facts")
            Spacer(minLength: 0)
        }
    }

    private func statChip(value: Int, label: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(value)")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.ink)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color.muted)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.hairline)
            .frame(width: 1, height: 16)
    }

    private var occasionIcon: String {
        switch celebration.date.kind {
        case .birthday: return "birthday.cake.fill"
        case .anniversary: return "heart.fill"
        case .custom: return "star.fill"
        }
    }

    private var occasionTag: String {
        switch celebration.date.kind {
        case .birthday: return "Birthday today"
        case .anniversary: return "Anniversary today"
        case .custom: return "Today"
        }
    }

    private var occasionSubtitle: String {
        let label = celebration.date.kind.rawValue.capitalized
        return "\(celebration.person.name)'s \(label.lowercased())"
    }

    private var collapsedCopy: String {
        switch celebration.date.kind {
        case .birthday: return "It's \(celebration.person.firstName)'s birthday today"
        case .anniversary: return "\(celebration.person.firstName)'s anniversary today"
        case .custom: return celebration.date.label
        }
    }

    private var ctaLabel: String {
        celebration.date.kind == .birthday ? "Send birthday text" : "Send text"
    }

    private func smsURL(for person: Person) -> URL? {
        guard let raw = person.phone, !raw.isEmpty else { return nil }
        let allowed = CharacterSet(charactersIn: "+0123456789")
        let cleaned = raw.unicodeScalars.filter { allowed.contains($0) }.map(String.init).joined()
        guard !cleaned.isEmpty else { return nil }
        return URL(string: "sms:\(cleaned)")
    }
}
