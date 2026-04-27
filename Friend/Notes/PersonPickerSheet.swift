import SwiftUI

@MainActor
struct PersonPickerSheet: View {
    /// Called with one or more selected people. The caller decides whether to
    /// open the single-person or multi-person note flow based on count.
    var onSelect: ([Person]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var people: [Person] = []
    @State private var search: String = ""
    @State private var isLoading = true
    @State private var selectedIds: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filtered.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .background(Color.appBackground)
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Next") { confirmSelection() }
                        .font(.system(size: 15, weight: .semibold))
                        .disabled(selectedIds.isEmpty)
                }
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
            .task { await load() }
        }
    }

    private var filtered: [Person] {
        if search.isEmpty { return people }
        return people.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    private var list: some View {
        List(filtered) { person in
            row(person)
                .listRowBackground(Color.appBackground)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func row(_ person: Person) -> some View {
        let isSelected = selectedIds.contains(person.id)
        return Button {
            handleTap(person)
        } label: {
            HStack(spacing: 12) {
                AvatarView(person: person, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(person.name).font(.system(size: 15, weight: .semibold))
                    Text(person.relation).font(.system(size: 12.5)).foregroundStyle(Color.muted)
                }
                Spacer()
                checkbox(isSelected: isSelected)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func checkbox(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(isSelected ? Color.accent : Color.hairline, lineWidth: 1.5)
                .frame(width: 22, height: 22)
            if isSelected {
                Circle().fill(Color.accent).frame(width: 22, height: 22)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    private var navTitle: String {
        switch selectedIds.count {
        case 0: return "New note for"
        case 1: return "New note for 1"
        default: return "New note for \(selectedIds.count)"
        }
    }

    private func handleTap(_ person: Person) {
        if selectedIds.contains(person.id) {
            selectedIds.remove(person.id)
        } else {
            selectedIds.insert(person.id)
        }
    }

    private func confirmSelection() {
        let chosen = people.filter { selectedIds.contains($0.id) }
        guard !chosen.isEmpty else { return }
        dismiss()
        // Defer slightly so the sheet has time to dismiss before the new one opens.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            onSelect(chosen)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Color.muted)
            Text("No people yet")
                .font(.system(size: 16, weight: .semibold))
            Text("Add people from your contacts in Settings first.")
                .font(.system(size: 14))
                .foregroundStyle(Color.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        people = (try? await SupabaseService.shared.fetchPeople()) ?? []
    }
}
