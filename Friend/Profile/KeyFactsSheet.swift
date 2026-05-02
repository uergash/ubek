import SwiftUI

@MainActor
struct KeyFactsSheet: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var factToEdit: KeyFact?
    @State private var addingNewFact = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Button { addingNewFact = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                            Text("New key fact")
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

                    if viewModel.keyFacts.isEmpty {
                        emptyState
                    } else {
                        CardView(padding: 0) {
                            VStack(spacing: 0) {
                                ForEach(Array(viewModel.keyFacts.enumerated()), id: \.element.id) { i, fact in
                                    row(fact)
                                    if i < viewModel.keyFacts.count - 1 {
                                        Divider().background(Color.hairline).padding(.leading, 40)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
            .background(Color.appBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.accent)
                }
            }
            .sheet(item: $factToEdit) { fact in
                AddKeyFactSheet(viewModel: viewModel, existing: fact)
            }
            .sheet(isPresented: $addingNewFact) {
                AddKeyFactSheet(viewModel: viewModel)
            }
        }
    }

    private var navTitle: String {
        viewModel.person.map { "\($0.firstName)'s key facts" } ?? "Key facts"
    }

    private func row(_ fact: KeyFact) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkle")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accent)
                .padding(.top, 4)
            Text(fact.text)
                .font(.system(size: 15))
                .foregroundStyle(Color.ink)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture { factToEdit = fact }
    }

    private var emptyState: some View {
        Text("No key facts yet. Add one above, or save a note and Bowline will pull facts out automatically.")
            .font(.system(size: 14))
            .foregroundStyle(Color.muted)
            .multilineTextAlignment(.center)
            .padding(30)
    }
}

// ─── Add / Edit key fact sheet ────────────────────────────────────────────
struct AddKeyFactSheet: View {
    @Bindable var viewModel: ProfileViewModel
    let existing: KeyFact?
    @Environment(\.dismiss) private var dismiss
    @State private var text: String

    init(viewModel: ProfileViewModel, existing: KeyFact? = nil) {
        self._viewModel = Bindable(viewModel)
        self.existing = existing
        _text = State(initialValue: existing?.text ?? "")
    }

    private var isEditing: Bool { existing != nil }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. Has a dog named Milo", text: $text, axis: .vertical)
                        .lineLimit(1...3)
                } header: {
                    Text("Fact")
                } footer: {
                    Text("Keep it short — facts read best in 6 words or fewer.")
                        .foregroundStyle(Color.muted)
                }

                if isEditing, let existing {
                    Section {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteKeyFact(existing)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete fact").font(.system(size: 15, weight: .semibold))
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit key fact" : "New key fact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if let existing {
                                await viewModel.editKeyFact(existing, text: trimmedText)
                            } else {
                                await viewModel.addKeyFact(text: trimmedText)
                            }
                            dismiss()
                        }
                    }
                    .disabled(trimmedText.isEmpty)
                }
            }
        }
    }
}
