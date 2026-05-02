import SwiftUI

@MainActor
struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var showingImportContacts = false
    @State private var showingNewPerson = false
    var onOpenPerson: (Person) -> Void
    /// Called when a "Reminders" row is tapped — caller deep-links to the
    /// person's Reminders tab so the user lands where the action lives.
    var onOpenReminder: (Person) -> Void = { _ in }
    var onAddNote: (Person?) -> Void
    var onOpenSettings: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if !viewModel.hasLoaded {
                    loadingState
                } else {
                    greeting
                    if viewModel.people.isEmpty {
                        emptyState
                    } else {
                        celebrationsSection
                        memoriesSection
                        upcomingSection
                        dueRemindersSection
                        nudgesSection
                    }
                }
            }
            .padding(.top, 14)
            .padding(.bottom, 140)
        }
        .scrollIndicators(.hidden)
        .task { await viewModel.loadIfNeeded() }
        .refreshable { await viewModel.load() }
        .onReceive(NotificationCenter.default.publisher(for: .friendNoteSaved)) { _ in
            // Refresh when any note is saved so Recently engaged stays fresh.
            Task { await viewModel.load() }
        }
        .sheet(isPresented: $showingImportContacts) {
            ImportContactsView(isOnboarding: false) {
                showingImportContacts = false
                Task { await viewModel.load() }
            }
        }
        .sheet(isPresented: $showingNewPerson) {
            NewPersonSheet(
                profileDefaultFrequency: viewModel.profile?.defaultContactFrequencyDays ?? 21
            ) { created in
                Task {
                    await viewModel.load()
                    onOpenPerson(created)
                }
            }
        }
    }

    // ─── Greeting ──────────────────────────────────────────────────────────
    private var greeting: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(todayLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.muted)
                Text("\(timeGreeting),\n\(displayName).")
                    .font(.system(size: 30, weight: .bold))
                    .tracking(-0.6)
                    .foregroundStyle(Color.ink)
            }
            Spacer(minLength: 8)
            Button(action: onOpenSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.accent)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.card))
                    .overlay(Circle().stroke(Color.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home_settings")
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 22)
    }

    private var todayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Hi"
        }
    }

    private var displayName: String {
        viewModel.profile?.name.split(separator: " ").first.map(String.init) ?? "there"
    }

    // ─── Celebrations (birthday/anniversary takeover) ──────────────────────
    @ViewBuilder
    private var celebrationsSection: some View {
        if !viewModel.celebrations.isEmpty {
            VStack(spacing: 14) {
                ForEach(viewModel.celebrations) { c in
                    CelebrationCard(
                        celebration: c,
                        onOpenPerson: onOpenPerson
                    )
                }
            }
            .padding(.horizontal, 22)
        }
    }

    // ─── Upcoming ──────────────────────────────────────────────────────────
    @ViewBuilder
    private var upcomingSection: some View {
        if !viewModel.upcomingDates.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeaderView(title: "Upcoming")
                    .padding(.horizontal, 22)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(viewModel.upcomingDates.enumerated()), id: \.offset) { _, item in
                            UpcomingCardView(person: item.person, date: item.date) {
                                onOpenPerson(item.person)
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 4)
                }
            }
        }
    }

    // ─── Due reminders ─────────────────────────────────────────────────────
    @ViewBuilder
    private var dueRemindersSection: some View {
        if !viewModel.dueReminders.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeaderView(title: "Reminders")
                CardView(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.dueReminders.enumerated()), id: \.element.reminder.id) { i, item in
                            dueReminderRow(item.person, item.reminder)
                            if i < viewModel.dueReminders.count - 1 {
                                Divider().background(Color.hairline).padding(.leading, 50)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 22)
        }
    }

    private func dueReminderRow(_ person: Person, _ reminder: Reminder) -> some View {
        Button {
            onOpenReminder(person)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(reminder.isOverdue ? Color.healthRed.opacity(0.15) : Color.accentSoft)
                        .frame(width: 36, height: 36)
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(reminder.isOverdue ? Color.healthRed : Color.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(reminder.title).font(.system(size: 14.5, weight: .semibold))
                    Text("\(person.name) · \(reminder.dueLabel)")
                        .font(.system(size: 12.5))
                        .foregroundStyle(reminder.isOverdue ? Color.healthRed : Color.muted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Color.muted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // ─── Nudges ────────────────────────────────────────────────────────────
    @ViewBuilder
    private var nudgesSection: some View {
        if !viewModel.nudges.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeaderView(
                    title: "Nudges",
                    action: "\(viewModel.nudges.count) new"
                )
                ForEach(viewModel.nudges) { n in
                    NudgeCardView(nudge: n) { onOpenPerson(n.person) }
                }
            }
            .padding(.horizontal, 22)
        }
    }

    // ─── On this day (memories) ────────────────────────────────────────────
    @ViewBuilder
    private var memoriesSection: some View {
        if !viewModel.memories.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeaderView(title: "On this day")
                VStack(spacing: 10) {
                    ForEach(viewModel.memories) { m in
                        memoryCard(m)
                    }
                }
            }
            .padding(.horizontal, 22)
        }
    }

    private func memoryCard(_ m: HomeViewModel.Memory) -> some View {
        Button {
            onOpenPerson(m.person)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                AvatarView(person: m.person, size: 36)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.accent)
                        Text(yearsAgoLabel(m.yearsAgo))
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(0.5)
                            .textCase(.uppercase)
                            .foregroundStyle(Color.accent)
                    }
                    Text(m.person.firstName)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(Color.ink)
                    Text(m.note.body)
                        .font(.system(size: 13.5))
                        .foregroundStyle(Color.inkSoft)
                        .lineLimit(3)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.card))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.hairline, lineWidth: 1))
            .cardShadow()
        }
        .buttonStyle(.plain)
    }

    private func yearsAgoLabel(_ years: Int) -> String {
        years == 1 ? "1 year ago today" : "\(years) years ago today"
    }


    // ─── Empty / loading ───────────────────────────────────────────────────
    private var emptyState: some View {
        NoPeopleEmptyView(
            onImportFromContacts: { showingImportContacts = true },
            onAddManually: { showingNewPerson = true }
        )
    }

    private struct CelebrationCard: View {
        let celebration: OccasionCelebration
        var onOpenPerson: (Person) -> Void
        @State private var isExpanded: Bool

        init(celebration: OccasionCelebration, onOpenPerson: @escaping (Person) -> Void) {
            self.celebration = celebration
            self.onOpenPerson = onOpenPerson
            let dismissed = AnnualSummaryStore.isDismissed(
                personId: celebration.person.id,
                year: Calendar.current.component(.year, from: Date()),
                kind: celebration.date.kind
            )
            _isExpanded = State(initialValue: !dismissed)
        }

        var body: some View {
            OccasionTakeoverView(
                celebration: celebration,
                isExpanded: $isExpanded,
                onOpenPerson: onOpenPerson
            )
        }
    }

    private var loadingState: some View {
        BreathingCirclesView(caption: "Catching up with your people…")
            .padding(.top, 60)
    }
}
