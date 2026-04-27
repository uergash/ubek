import SwiftUI

enum AllPeopleFilter: Hashable {
    case all
    case relation(String)
    case group(FriendGroup)

    var label: String {
        switch self {
        case .all: return "All"
        case .relation(let r): return r == "Friend" ? "Friends" : r
        case .group(let g): return g.name
        }
    }
}

extension AllPeopleFilter: Equatable {
    static func == (lhs: AllPeopleFilter, rhs: AllPeopleFilter) -> Bool {
        switch (lhs, rhs) {
        case (.all, .all): return true
        case (.relation(let a), .relation(let b)): return a == b
        case (.group(let a), .group(let b)): return a.id == b.id
        default: return false
        }
    }
}

@MainActor
@Observable
final class AllPeopleViewModel {
    var people: [Person] = []
    var profile: UserProfile?
    var groups: [FriendGroup] = []
    var groupMembership: [UUID: Set<UUID>] = [:]
    var query: String = ""
    var activeFilter: AllPeopleFilter = .all
    var isLoading = false

    var availableFilters: [AllPeopleFilter] {
        var f: [AllPeopleFilter] = [.all, .relation("Family"), .relation("Friend")]
        f.append(contentsOf: groups.map { .group($0) })
        return f
    }

    var visiblePeople: [Person] {
        let filtered: [Person]
        switch activeFilter {
        case .all:
            filtered = people
        case .relation(let r):
            filtered = people.filter { $0.relation == r }
        case .group(let g):
            let members = groupMembership[g.id] ?? []
            filtered = people.filter { members.contains($0.id) }
        }
        let searched = query.isEmpty
            ? filtered
            : filtered.filter { $0.name.localizedCaseInsensitiveContains(query) }
        let defaultFreq = profile?.defaultContactFrequencyDays ?? 21
        return searched.sorted { a, b in
            let ha = a.healthState(profileDefault: defaultFreq).sortKey
            let hb = b.healthState(profileDefault: defaultFreq).sortKey
            if ha != hb { return ha < hb }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        guard await SupabaseService.shared.resolveCurrentUserId() != nil else { return }

        do { people = try await SupabaseService.shared.fetchPeople() }
        catch is CancellationError {} catch {}

        do { profile = try await SupabaseService.shared.fetchProfile() }
        catch is CancellationError {} catch {}

        do { groups = try await SupabaseService.shared.fetchGroups() }
        catch is CancellationError {} catch {}

        var map: [UUID: Set<UUID>] = [:]
        for g in groups {
            if let members = try? await SupabaseService.shared.fetchGroupMembers(groupId: g.id) {
                map[g.id] = Set(members.map { $0.personId })
            }
        }
        groupMembership = map
    }
}

@MainActor
struct AllPeopleView: View {
    @State private var viewModel = AllPeopleViewModel()
    @Environment(\.dismiss) private var dismiss
    var initialFilter: AllPeopleFilter? = nil
    var onOpenPerson: (Person) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                searchField
                filterChips
                peopleList
            }
            .padding(.top, 14)
            .background(Color.appBackground)
            .navigationTitle("All people")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await viewModel.load()
                if let f = initialFilter { viewModel.activeFilter = f }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.muted)
            TextField("Search by name", text: Binding(
                get: { viewModel.query },
                set: { viewModel.query = $0 }
            ))
            .font(.system(size: 15))
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            if !viewModel.query.isEmpty {
                Button { viewModel.query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Color.muted)
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.chipBg))
        .padding(.horizontal, 22)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(viewModel.availableFilters.enumerated()), id: \.offset) { _, filter in
                    ChipView(
                        label: filter.label,
                        isActive: viewModel.activeFilter == filter
                    ) { viewModel.activeFilter = filter }
                }
            }
            .padding(.horizontal, 22)
        }
    }

    private var peopleList: some View {
        let defaultFreq = viewModel.profile?.defaultContactFrequencyDays ?? 21
        let people = viewModel.visiblePeople
        return ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(people.enumerated()), id: \.element.id) { i, person in
                    PersonRowView(
                        person: person,
                        healthState: person.healthState(profileDefault: defaultFreq)
                    ) { onOpenPerson(person) }
                    if i < people.count - 1 {
                        Divider().background(Color.hairline).padding(.leading, 70)
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.card))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.hairline, lineWidth: 1))
            .cardShadow()
            .padding(.horizontal, 22)
            .padding(.bottom, 30)
        }
    }
}
