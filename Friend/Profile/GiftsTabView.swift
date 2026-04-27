import SwiftUI

@MainActor
struct GiftsTabView: View {
    @Bindable var viewModel: ProfileViewModel
    var onAdd: () -> Void

    @State private var giftToMarkGiven: Gift?

    var body: some View {
        VStack(spacing: 14) {
            Button(action: onAdd) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("New gift idea")
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

            if viewModel.gifts.isEmpty {
                Text("No gifts yet. Tap above to capture your first.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.muted)
                    .multilineTextAlignment(.center)
                    .padding(30)
            } else {
                if !viewModel.wishlistGifts.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        SectionHeaderView(title: "Wishlist")
                        VStack(spacing: 10) {
                            ForEach(viewModel.wishlistGifts) { gift in
                                wishlistRow(gift)
                            }
                        }
                    }
                }

                if !viewModel.giftedGifts.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        SectionHeaderView(title: "Gifted (\(viewModel.giftedGifts.count))")
                        VStack(spacing: 10) {
                            ForEach(viewModel.giftedGifts) { gift in
                                giftedRow(gift)
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $giftToMarkGiven) { gift in
            MarkGiftGivenSheet(gift: gift, viewModel: viewModel)
        }
    }

    private func wishlistRow(_ gift: Gift) -> some View {
        CardView {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.accentSoft)
                        .frame(width: 38, height: 38)
                    Image(systemName: "gift")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.accent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(gift.name).font(.system(size: 14.5, weight: .semibold))
                    if let n = gift.note {
                        Text(n)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.muted)
                            .lineSpacing(2)
                    }
                    Button("Mark as given →") { giftToMarkGiven = gift }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.accent)
                        .padding(.top, 4)
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("gift_mark_given")
                        .accessibilityLabel("Mark as given")
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func giftedRow(_ gift: Gift) -> some View {
        CardView {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.cardSoft)
                        .frame(width: 38, height: 38)
                    Text("🎁").font(.system(size: 18))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(gift.name).font(.system(size: 14, weight: .semibold))
                    Text(giftedSubtitle(gift)).font(.system(size: 12.5)).foregroundStyle(Color.muted)
                }
                Spacer()
                if let r = gift.reaction {
                    Text(r.label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(reactionColor(r))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(reactionBg(r)))
                }
            }
        }
    }

    private func giftedSubtitle(_ gift: Gift) -> String {
        let occ = gift.occasion ?? ""
        let date: String
        if let d = gift.givenDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            date = formatter.string(from: d)
        } else { date = "" }
        return [occ, date].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private func reactionColor(_ r: GiftReaction) -> Color {
        switch r {
        case .loved: return Color(red: 0.18, green: 0.48, blue: 0.30)
        case .neutral: return Color.inkSoft
        case .disliked: return Color.healthRed
        }
    }

    private func reactionBg(_ r: GiftReaction) -> Color {
        switch r {
        case .loved: return Color(red: 0.86, green: 0.95, blue: 0.86)
        case .neutral: return Color.chipBg
        case .disliked: return Color.accentSoft
        }
    }
}

// ─── Add gift sheet ────────────────────────────────────────────────────────
struct AddGiftSheet: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Gift idea") {
                    TextField("e.g. Linea Mini espresso machine", text: $name)
                    TextField("Why? (optional)", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add a gift idea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await viewModel.addGift(name: name, note: note.isEmpty ? nil : note)
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// ─── Mark as given sheet ──────────────────────────────────────────────────
struct MarkGiftGivenSheet: View {
    let gift: Gift
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var occasion = ""
    @State private var reaction: GiftReaction = .loved

    var body: some View {
        NavigationStack {
            Form {
                Section("Occasion") {
                    TextField("e.g. Birthday 2026", text: $occasion)
                }
                Section("How did they like it?") {
                    Picker("Reaction", selection: $reaction) {
                        ForEach(GiftReaction.allCases, id: \.self) { r in
                            Text(r.label).tag(r)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(gift.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.markGiftAsGiven(gift, occasion: occasion, reaction: reaction)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
