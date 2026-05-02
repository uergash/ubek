import SwiftUI

@MainActor
struct NotesTabView: View {
    @Bindable var viewModel: ProfileViewModel
    var onAddNote: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Button(action: onAddNote) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("New note for \(viewModel.person?.firstName ?? "this person")")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Color.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                )
            }
            .buttonStyle(.plain)

            if viewModel.notes.isEmpty {
                Text("No notes yet. Tap above to capture your first.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.muted)
                    .multilineTextAlignment(.center)
                    .padding(30)
            } else {
                ForEach(viewModel.notes) { note in
                    NoteCardView(
                        note: note,
                        facts: factsFromNote(note),
                        coAttendees: viewModel.coAttendeesByNoteId[note.id] ?? []
                    )
                }
            }
        }
    }

    private func factsFromNote(_ note: Note) -> [String] {
        viewModel.keyFacts
            .filter { $0.sourceNoteId == note.id }
            .map { $0.text }
    }
}

struct NoteCardView: View {
    let note: Note
    let facts: [String]
    var coAttendees: [Person] = []

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle().fill(Color.accentSoft).frame(width: 26, height: 26)
                        Image(systemName: note.interactionType.iconName)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.accentDeep)
                    }
                    Text(note.interactionType.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                    Text("· \(formattedDate)")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color.muted)
                }
                if !coAttendees.isEmpty {
                    coAttendeesRow
                }
                Text(note.body)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.inkSoft)
                    .lineSpacing(3)
                if !facts.isEmpty {
                    FlowLayout(spacing: 6, lineSpacing: 6) {
                        ForEach(facts, id: \.self) { f in
                            FactChipView(text: f)
                        }
                    }
                }
            }
        }
    }

    private var coAttendeesRow: some View {
        HStack(spacing: 6) {
            HStack(spacing: -6) {
                ForEach(Array(coAttendees.prefix(3).enumerated()), id: \.element.id) { _, person in
                    AvatarView(person: person, size: 20)
                        .overlay(Circle().stroke(Color.card, lineWidth: 1.5))
                }
            }
            Text("With \(coAttendees.map(\.firstName).joined(separator: ", "))")
                .font(.system(size: 12))
                .foregroundStyle(Color.muted)
                .lineLimit(1)
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: note.createdAt)
    }
}

/// Simple wrapping flow layout — wraps chips onto multiple rows.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        // Cap each child's width at the row width so chips with long text
        // truncate (or wrap, depending on the chip) instead of overflowing.
        let childProposal = ProposedViewSize(width: maxWidth, height: nil)
        var rows: [[CGSize]] = [[]]
        var currentWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for sv in subviews {
            let size = sv.sizeThatFits(childProposal)
            let needed = (rows[rows.count - 1].isEmpty ? 0 : spacing) + size.width
            if currentWidth + needed > maxWidth, !rows[rows.count - 1].isEmpty {
                totalHeight += rowHeight + lineSpacing
                rows.append([size])
                currentWidth = size.width
                rowHeight = size.height
            } else {
                rows[rows.count - 1].append(size)
                currentWidth += needed
                rowHeight = max(rowHeight, size.height)
            }
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        let maxX = bounds.maxX
        let childProposal = ProposedViewSize(width: bounds.width, height: nil)

        for sv in subviews {
            let size = sv.sizeThatFits(childProposal)
            if x + size.width > maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            sv.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
