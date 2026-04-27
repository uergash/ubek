import SwiftUI

@MainActor
struct NewGroupSheet: View {
    let people: [Person]
    var onCreate: (String, Set<UUID>) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var selected: Set<UUID> = []
    @State private var search: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                nameField
                Divider().background(Color.hairline)
                memberList
            }
            .background(Color.appBackground)
            .navigationTitle("New group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onCreate(trimmed, selected)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GROUP NAME")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.7)
                .foregroundStyle(Color.muted)
            TextField("e.g. Book club, Family", text: $name)
                .font(.system(size: 17))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.chipBg))
        }
        .padding(.horizontal, 22)
        .padding(.top, 16)
        .padding(.bottom, 14)
    }

    private var filtered: [Person] {
        if search.isEmpty { return people }
        return people.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    private var memberList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("MEMBERS \(selected.isEmpty ? "" : "· \(selected.count) selected")")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.7)
                    .foregroundStyle(Color.muted)
                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 6)

            List(filtered) { person in
                row(person)
                    .listRowBackground(Color.appBackground)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
        }
    }

    private func row(_ person: Person) -> some View {
        let isSelected = selected.contains(person.id)
        return Button {
            if isSelected { selected.remove(person.id) } else { selected.insert(person.id) }
        } label: {
            HStack(spacing: 12) {
                AvatarView(person: person, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(person.name).font(.system(size: 15, weight: .semibold))
                    Text(person.relation).font(.system(size: 12.5)).foregroundStyle(Color.muted)
                }
                Spacer()
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
