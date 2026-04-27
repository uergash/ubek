import SwiftUI

@MainActor
struct PeopleView: View {
    @State private var viewModel = PeopleViewModel()
    @State private var showingAllPeople = false
    @State private var allPeopleFilter: AllPeopleFilter?
    @State private var showingNewGroup = false
    @State private var showingNewPerson = false
    @State private var showingImportContacts = false
    var onOpenPerson: (Person) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if !viewModel.hasLoaded {
                    loading
                } else {
                    header
                    searchPill
                    if viewModel.people.isEmpty {
                        emptyState
                    } else {
                        spotlightSection
                        nudgesStripSection
                        recentlyEngagedSection
                        topContactsSection
                        groupsSection
                        seeAllButton
                    }
                }
            }
            .padding(.top, 14)
            .padding(.bottom, 140)
        }
        .scrollIndicators(.hidden)
        .task { await viewModel.loadIfNeeded() }
        .refreshable { await viewModel.load() }
        .onReceive(NotificationCenter.default.publisher(for: .friendNoteSaved)) { notif in
            guard let pid = AppEvents.personId(from: notif) else { return }
            Task { await viewModel.invalidateSpotlightIfMatches(personId: pid) }
        }
        .sheet(isPresented: $showingAllPeople) {
            AllPeopleView(initialFilter: allPeopleFilter) { person in
                showingAllPeople = false
                onOpenPerson(person)
            }
        }
        .sheet(isPresented: $showingNewGroup) {
            NewGroupSheet(people: viewModel.people) { name, members in
                Task { await viewModel.createGroup(name: name, memberIds: members) }
            }
        }
        .sheet(isPresented: $showingNewPerson) {
            NewPersonSheet(
                profileDefaultFrequency: viewModel.profile?.defaultContactFrequencyDays ?? 21
            ) { created in
                Task {
                    // Refresh so they show up in Top contacts / list immediately.
                    await viewModel.load()
                    onOpenPerson(created)
                }
            }
        }
        .sheet(isPresented: $showingImportContacts) {
            ImportContactsView(isOnboarding: false) {
                showingImportContacts = false
                Task { await viewModel.load() }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("People")
                .font(.system(size: 30, weight: .bold))
                .tracking(-0.6)
            Spacer()
            Button { showingNewPerson = true } label: {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.accent)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.card))
                    .overlay(Circle().stroke(Color.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("people_add")
            .accessibilityLabel("Add person")
        }
        .padding(.horizontal, 22)
    }

    private var searchPill: some View {
        Button {
            allPeopleFilter = nil
            showingAllPeople = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.muted)
                Text("Search all people")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.muted)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.chipBg))
            .padding(.horizontal, 22)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var topContactsSection: some View {
        if !viewModel.topContacts.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeaderView(title: "Top contacts")
                    .padding(.horizontal, 22)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.topContacts, id: \.person.id) { item in
                            topContactCard(item.person)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 4)
                }
            }
        }
    }

    private func topContactCard(_ person: Person) -> some View {
        Button { onOpenPerson(person) } label: {
            VStack(alignment: .leading, spacing: 10) {
                AvatarView(person: person, size: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(person.firstName)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(Color.ink)
                        .lineLimit(1)
                    Text(person.relation)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.muted)
                }
            }
            .padding(14)
            .frame(width: 130, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.card))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.hairline, lineWidth: 1))
            .cardShadow()
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var spotlightSection: some View {
        if let spotlight = viewModel.spotlight {
            SpotlightCardView(spotlight: spotlight, onOpenPerson: onOpenPerson)
        }
    }

    @ViewBuilder
    private var groupsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeaderView(
                title: "Groups",
                action: viewModel.groups.isEmpty ? nil : "New"
            ) {
                showingNewGroup = true
            }
            .padding(.horizontal, 22)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.groups) { group in
                        groupCard(group)
                    }
                    newGroupCard
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 4)
            }
        }
    }

    private func groupCard(_ group: FriendGroup) -> some View {
        Button {
            allPeopleFilter = .group(group)
            showingAllPeople = true
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.accentSoft)
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.accentDeep)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(Color.ink)
                        .lineLimit(1)
                    Text("\(viewModel.groupMemberCounts[group.id] ?? 0) members")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.muted)
                }
            }
            .padding(14)
            .frame(width: 150, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.card))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.hairline, lineWidth: 1))
            .cardShadow()
        }
        .buttonStyle(.plain)
    }

    private var newGroupCard: some View {
        Button { showingNewGroup = true } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                        .frame(width: 44, height: 44)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("New group")
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(Color.accent)
                    Text("Organize people")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.muted)
                }
            }
            .padding(14)
            .frame(width: 150, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [5]))
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var recentlyEngagedSection: some View {
        if !viewModel.recentInteractions.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeaderView(title: "Recently engaged")
                CardView(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.recentInteractions.enumerated()), id: \.element.note.id) { i, item in
                            RecentlyEngagedRowView(person: item.person, note: item.note) {
                                onOpenPerson(item.person)
                            }
                            if i < viewModel.recentInteractions.count - 1 {
                                Divider().background(Color.hairline).padding(.leading, 60)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 22)
        }
    }

    @ViewBuilder
    private var nudgesStripSection: some View {
        if !viewModel.suggestions.isEmpty {
            NudgesStripView(
                suggestions: viewModel.suggestions,
                onOpenPerson: onOpenPerson,
                onDismiss: { id in viewModel.dismissSuggestion(id) }
            )
        }
    }

    private var seeAllButton: some View {
        Button {
            allPeopleFilter = nil
            showingAllPeople = true
        } label: {
            HStack {
                Text("See all people")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.accent)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.card))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.hairline, lineWidth: 1))
            .cardShadow()
            .padding(.horizontal, 22)
        }
        .buttonStyle(.plain)
    }

    private var loading: some View {
        BreathingCirclesView(caption: "Gathering your circle…")
            .padding(.top, 60)
    }

    private var emptyState: some View {
        NoPeopleEmptyView(
            onImportFromContacts: { showingImportContacts = true },
            onAddManually: { showingNewPerson = true }
        )
    }
}

