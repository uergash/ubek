import SwiftUI

@MainActor
struct OverviewTabView: View {
    @Bindable var viewModel: ProfileViewModel
    @State private var reportingSummary = false
    @State private var showingAllFacts = false

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            celebrationSection
            keyFactsSection
            comingUpSection
            summarySection
            latestNoteSection
        }
        .sheet(isPresented: $reportingSummary) {
            if let s = viewModel.summary {
                AIReportSheet(kind: .summary, content: s, personId: viewModel.person?.id)
            }
        }
        .sheet(isPresented: $showingAllFacts) {
            KeyFactsSheet(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var celebrationSection: some View {
        if let c = viewModel.celebration {
            ProfileCelebrationCard(celebration: c)
        }
    }

    private struct ProfileCelebrationCard: View {
        let celebration: OccasionCelebration
        @State private var isExpanded: Bool

        init(celebration: OccasionCelebration) {
            self.celebration = celebration
            let dismissed = AnnualSummaryStore.isDismissed(
                personId: celebration.person.id,
                year: Calendar.current.component(.year, from: Date()),
                kind: celebration.date.kind
            )
            _isExpanded = State(initialValue: !dismissed)
        }

        var body: some View {
            // onOpenPerson is a no-op here — we're already on this person's profile.
            OccasionTakeoverView(
                celebration: celebration,
                isExpanded: $isExpanded,
                onOpenPerson: { _ in },
                isCompact: true
            )
        }
    }

    @ViewBuilder
    private var keyFactsSection: some View {
        if !viewModel.keyFacts.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeaderView(
                    title: "Key facts",
                    action: viewModel.keyFacts.count > 6 ? "See all" : nil,
                    onActionTap: { showingAllFacts = true }
                )
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.keyFacts) { fact in
                            FactChipView(text: fact.text)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var comingUpSection: some View {
        if let upcoming = viewModel.nextUpcomingDate {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeaderView(title: "Coming up")
                CardView {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.accentSoft)
                                .frame(width: 50, height: 50)
                            Image(systemName: upcoming.kind.iconName)
                                .font(.system(size: 22))
                                .foregroundStyle(Color.accent)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(upcoming.label)
                                .font(.system(size: 11.5, weight: .semibold))
                                .tracking(0.69)
                                .textCase(.uppercase)
                                .foregroundStyle(Color.muted)
                            Text(upcoming.formattedDate)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.ink)
                        }
                        Spacer()
                        Text(daysLabel(upcoming.daysUntilNext))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.appBackground)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.ink))
                    }
                }
            }
        }
    }

    private func daysLabel(_ days: Int) -> String {
        if days == 0 { return "Today" }
        if days == 1 { return "in 1 day" }
        return "in \(days) days"
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeaderView(title: "Recent interactions")
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles").font(.system(size: 10, weight: .semibold))
                        Text("SUMMARY").font(.system(size: 10.5, weight: .semibold)).tracking(0.63)
                    }
                    .foregroundStyle(Color.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.accentSoft))

                    if viewModel.isSummarizing && viewModel.summary == nil {
                        HStack(spacing: 8) {
                            ProgressView().tint(Color.muted).scaleEffect(0.8)
                            Text("Reading recent notes…")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.muted)
                        }
                    } else {
                        Text(viewModel.summary ?? "Add a note to start building a picture.")
                            .font(.system(size: 14.5))
                            .foregroundStyle(Color.inkSoft)
                            .lineSpacing(3)
                            .contextMenu {
                                if viewModel.summary != nil {
                                    Button(role: .destructive) {
                                        reportingSummary = true
                                    } label: {
                                        Label("Report this output", systemImage: "flag")
                                    }
                                }
                            }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var latestNoteSection: some View {
        if let latest = viewModel.notes.first {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeaderView(title: "Latest", action: viewModel.notes.count > 1 ? "See all" : nil)
                NoteCardView(note: latest, facts: factsFromNote(latest))
            }
        }
    }

    private func factsFromNote(_ note: Note) -> [String] {
        viewModel.keyFacts
            .filter { $0.sourceNoteId == note.id }
            .map { $0.text }
    }
}
