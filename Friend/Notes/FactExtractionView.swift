import SwiftUI

@MainActor
struct FactExtractionView: View {
    @Bindable var viewModel: AddNoteViewModel
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            content
            footer
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.candidateFacts.isEmpty
            && viewModel.candidateFollowups.isEmpty
            && viewModel.candidateGifts.isEmpty {
            VStack(spacing: 14) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.accent)
                Text("Note saved")
                    .font(.system(size: 17, weight: .semibold))
                Text("No new key facts, follow-ups, or gift ideas to add this time.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !viewModel.candidateFacts.isEmpty {
                        factsSection
                    }
                    if !viewModel.candidateFollowups.isEmpty {
                        followupsSection
                    }
                    if !viewModel.candidateGifts.isEmpty {
                        giftsSection
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 24)
                .padding(.bottom, 16)
            }
        }
    }

    // ─── Facts ─────────────────────────────────────────────────────────────
    private var factsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(
                icon: "sparkles",
                title: "\(viewModel.candidateFacts.count) NEW \(viewModel.candidateFacts.count == 1 ? "FACT" : "FACTS")"
            )
            Text(factsCopy)
                .font(.system(size: 14.5))
                .foregroundStyle(Color.inkSoft)
                .lineSpacing(2)
                .padding(.bottom, 14)

            VStack(spacing: 10) {
                ForEach(viewModel.candidateFacts) { fact in
                    factRow(fact)
                }
            }
        }
    }

    private func factRow(_ fact: AddNoteViewModel.CandidateFact) -> some View {
        Button {
            viewModel.toggleFact(fact.id)
        } label: {
            HStack(spacing: 10) {
                checkbox(isOn: fact.keep)
                Text(fact.text)
                    .font(.system(size: 14.5, weight: .medium))
                    .foregroundStyle(fact.keep ? Color.ink : Color.muted)
                    .strikethrough(!fact.keep, color: Color.muted)
                Spacer()
                Text(fact.keep ? "Keep" : "Skipped")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.muted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.card))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.hairline, lineWidth: 1))
            .cardShadow()
        }
        .buttonStyle(.plain)
    }

    // ─── Follow-ups ────────────────────────────────────────────────────────
    private var followupsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(
                icon: "bell.badge",
                title: "\(viewModel.candidateFollowups.count) FOLLOW-\(viewModel.candidateFollowups.count == 1 ? "UP" : "UPS")"
            )
            Text("Reminders to nudge you back at the right time.")
                .font(.system(size: 14.5))
                .foregroundStyle(Color.inkSoft)
                .lineSpacing(2)
                .padding(.bottom, 14)

            VStack(spacing: 10) {
                ForEach(viewModel.candidateFollowups) { f in
                    followupRow(f)
                }
            }
        }
    }

    private func followupRow(_ f: AddNoteViewModel.CandidateFollowup) -> some View {
        Button {
            viewModel.toggleFollowup(f.id)
        } label: {
            HStack(spacing: 10) {
                checkbox(isOn: f.keep)
                VStack(alignment: .leading, spacing: 2) {
                    Text(f.title)
                        .font(.system(size: 14.5, weight: .medium))
                        .foregroundStyle(f.keep ? Color.ink : Color.muted)
                        .strikethrough(!f.keep, color: Color.muted)
                        .multilineTextAlignment(.leading)
                    Text(dueLabel(for: f.dueAt))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.muted)
                }
                Spacer()
                Text(f.keep ? "Keep" : "Skipped")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.muted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.card))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.hairline, lineWidth: 1))
            .cardShadow()
        }
        .buttonStyle(.plain)
    }

    private func dueLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return "Due \(formatter.string(from: date))"
    }

    // ─── Gift ideas ────────────────────────────────────────────────────────
    private var giftsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(
                icon: "gift",
                title: "\(viewModel.candidateGifts.count) GIFT \(viewModel.candidateGifts.count == 1 ? "IDEA" : "IDEAS")"
            )
            Text("Tap to confirm and add to \(viewModel.person.firstName)'s wishlist.")
                .font(.system(size: 14.5))
                .foregroundStyle(Color.inkSoft)
                .lineSpacing(2)
                .padding(.bottom, 14)

            VStack(spacing: 10) {
                ForEach(viewModel.candidateGifts) { g in
                    giftRow(g)
                }
            }
        }
    }

    private func giftRow(_ g: AddNoteViewModel.CandidateGift) -> some View {
        Button {
            viewModel.toggleGift(g.id)
        } label: {
            HStack(spacing: 10) {
                checkbox(isOn: g.keep)
                VStack(alignment: .leading, spacing: 2) {
                    Text(g.name)
                        .font(.system(size: 14.5, weight: .medium))
                        .foregroundStyle(g.keep ? Color.ink : Color.muted)
                        .strikethrough(!g.keep, color: Color.muted)
                        .multilineTextAlignment(.leading)
                    if !g.note.isEmpty {
                        Text(g.note)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.muted)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer()
                Text(g.keep ? "Keep" : "Skipped")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.muted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.card))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.hairline, lineWidth: 1))
            .cardShadow()
        }
        .buttonStyle(.plain)
    }

    // ─── Shared ────────────────────────────────────────────────────────────
    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11, weight: .semibold))
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.88)
        }
        .foregroundStyle(Color.accent)
        .padding(.bottom, 8)
    }

    private func checkbox(isOn: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isOn ? Color.accent : Color.hairline)
                .frame(width: 22, height: 22)
            if isOn {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    private var factsCopy: String {
        if viewModel.isMultiPerson {
            return "Tap to confirm and add to \(viewModel.person.firstName)'s profile. The note itself was logged for everyone."
        }
        return "Tap to confirm and add to \(viewModel.person.firstName)'s profile."
    }

    private var footer: some View {
        let anyKept = viewModel.candidateFacts.contains(where: \.keep)
            || viewModel.candidateFollowups.contains(where: \.keep)
            || viewModel.candidateGifts.contains(where: \.keep)
        return Button(anyKept ? "Save note" : "Done", action: onDone)
            .buttonStyle(AccentPrimaryLargeButton())
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
    }
}
