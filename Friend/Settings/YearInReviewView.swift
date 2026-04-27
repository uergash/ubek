import SwiftUI

@MainActor
struct YearInReviewView: View {
    let year: Int
    var onOpenPerson: (Person) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var review: YearReviewService.YearReview?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if let r = review {
                        hero(r)
                        statsRow(r)
                        reflection(r)
                        topPeople(r)
                    } else if isLoading {
                        ProgressView()
                            .tint(Color.muted)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)
                .padding(.bottom, 60)
            }
            .scrollIndicators(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Your year")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .task { await load() }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        review = await YearReviewService.shared.loadReview(for: year)
    }

    // ─── Sections ──────────────────────────────────────────────────────────
    private func hero(_ r: YearReviewService.YearReview) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(r.year))
                .font(.system(size: 13, weight: .semibold))
                .tracking(0.7)
                .textCase(.uppercase)
                .foregroundStyle(Color.accent)
            Text(r.headline)
                .font(.system(size: 32, weight: .bold))
                .tracking(-0.6)
                .lineSpacing(2)
                .foregroundStyle(Color.ink)
        }
    }

    private func statsRow(_ r: YearReviewService.YearReview) -> some View {
        HStack(spacing: 12) {
            statTile(value: "\(r.totalNotes)", label: r.totalNotes == 1 ? "note" : "notes")
            statTile(value: "\(r.totalGifts)", label: r.totalGifts == 1 ? "gift" : "gifts")
            statTile(value: "\(r.topPeople.count)", label: r.topPeople.count == 1 ? "person" : "people")
        }
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.ink)
            Text(label)
                .font(.system(size: 12.5))
                .foregroundStyle(Color.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.card))
        .cardShadow()
    }

    private func reflection(_ r: YearReviewService.YearReview) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles").font(.system(size: 11, weight: .semibold))
                    Text("REFLECTION").font(.system(size: 10.5, weight: .semibold)).tracking(0.63)
                }
                .foregroundStyle(Color.accent)
                Text(r.reflection)
                    .font(.system(size: 15.5))
                    .foregroundStyle(Color.ink)
                    .lineSpacing(4)
            }
        }
    }

    @ViewBuilder
    private func topPeople(_ r: YearReviewService.YearReview) -> some View {
        if !r.topPeople.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeaderView(title: "Top people")
                CardView(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(r.topPeople.enumerated()), id: \.element.id) { index, tp in
                            personRow(tp, rank: index + 1)
                            if index < r.topPeople.count - 1 {
                                Divider().background(Color.hairline).padding(.leading, 60)
                            }
                        }
                    }
                }
            }
        }
    }

    private func personRow(_ tp: YearReviewService.YearReview.TopPerson, rank: Int) -> some View {
        Button {
            dismiss()
            // Defer slightly so the sheet has time to dismiss before we navigate.
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 250_000_000)
                onOpenPerson(tp.person)
            }
        } label: {
            HStack(spacing: 12) {
                Text("\(rank)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.muted)
                    .frame(width: 24, alignment: .leading)
                AvatarView(person: tp.person, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(tp.person.name)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(Color.ink)
                    Text("\(tp.noteCount) \(tp.noteCount == 1 ? "note" : "notes")")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12)).foregroundStyle(Color.muted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
