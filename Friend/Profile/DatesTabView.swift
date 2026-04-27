import SwiftUI

@MainActor
struct DatesTabView: View {
    @Bindable var viewModel: ProfileViewModel
    var onAdd: () -> Void

    @State private var dateToEdit: ImportantDate?

    var body: some View {
        VStack(spacing: 14) {
            Button(action: onAdd) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Add a date")
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

            if viewModel.dates.isEmpty {
                Text("No dates yet. Tap above to add the first one.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.muted)
                    .multilineTextAlignment(.center)
                    .padding(30)
            } else {
                CardView(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.dates.enumerated()), id: \.element.id) { index, date in
                            row(date)
                            if index < viewModel.dates.count - 1 {
                                Divider().background(Color.hairline).padding(.leading, 70)
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $dateToEdit) { date in
            AddDateSheet(viewModel: viewModel, existing: date)
        }
    }

    private func row(_ date: ImportantDate) -> some View {
        HStack(spacing: 14) {
            // Tappable leading area — opens the edit sheet.
            Button {
                dateToEdit = date
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.accentSoft)
                            .frame(width: 38, height: 38)
                        Image(systemName: date.kind.iconName)
                            .font(.system(size: 17))
                            .foregroundStyle(Color.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(date.label)
                            .font(.system(size: 14.5, weight: .semibold))
                            .foregroundStyle(Color.ink)
                        Text(date.formattedDate)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.muted)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Toggle is its own gesture target so it doesn't conflict with row tap.
            Toggle("", isOn: Binding(
                get: { date.remind },
                set: { _ in
                    Task { await viewModel.toggleDateReminder(date) }
                }
            ))
            .labelsHidden()
            .tint(Color.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// ─── Add / Edit date sheet ─────────────────────────────────────────────────
struct AddDateSheet: View {
    @Bindable var viewModel: ProfileViewModel
    let existing: ImportantDate?
    @Environment(\.dismiss) private var dismiss

    @State private var kind: DateKind
    @State private var label: String
    @State private var date: Date

    init(viewModel: ProfileViewModel, existing: ImportantDate? = nil) {
        self._viewModel = Bindable(viewModel)
        self.existing = existing
        if let existing {
            _kind = State(initialValue: existing.kind)
            _label = State(initialValue: existing.label)
            // Reconstruct a Date for the picker — month/day in the current year.
            var components = DateComponents()
            components.year = Calendar.current.component(.year, from: Date())
            components.month = existing.dateMonth
            components.day = existing.dateDay
            _date = State(initialValue: Calendar.current.date(from: components) ?? Date())
        } else {
            _kind = State(initialValue: .birthday)
            _label = State(initialValue: "")
            _date = State(initialValue: Date())
        }
    }

    private var isEditing: Bool { existing != nil }

    private var trimmedLabel: String {
        label.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Kind", selection: $kind) {
                        ForEach(DateKind.allCases, id: \.self) { k in
                            Text(k.rawValue.capitalized).tag(k)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    TextField(placeholderForKind(kind), text: $label)
                } header: {
                    Text("Label")
                } footer: {
                    Text("Required.")
                        .foregroundStyle(trimmedLabel.isEmpty ? Color.healthRed : Color.muted)
                }
                Section("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }

                if isEditing, let existing {
                    Section {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteDate(existing)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete date").font(.system(size: 15, weight: .semibold))
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit date" : "Add a date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cal = Calendar.current
                        let m = cal.component(.month, from: date)
                        let d = cal.component(.day, from: date)
                        Task {
                            if let existing {
                                await viewModel.updateDate(existing, kind: kind, label: trimmedLabel, month: m, day: d)
                            } else {
                                await viewModel.addDate(kind: kind, label: trimmedLabel, month: m, day: d)
                            }
                            dismiss()
                        }
                    }
                    .disabled(trimmedLabel.isEmpty)
                }
            }
        }
        // Auto-suggest a label only on add for the canonical kinds — never
        // override an existing edit, and never auto-fill for `.custom`.
        .onChange(of: kind) { _, newKind in
            guard !isEditing else { return }
            if trimmedLabel.isEmpty
               || label == suggestedLabelForKind(.birthday)
               || label == suggestedLabelForKind(.anniversary) {
                label = suggestedLabelForKind(newKind)
            }
        }
        .onAppear {
            if !isEditing && trimmedLabel.isEmpty {
                label = suggestedLabelForKind(kind)
            }
        }
    }

    /// Suggested defaults — the user can always clear and type their own.
    /// `.custom` returns "" so the user must type a label.
    private func suggestedLabelForKind(_ k: DateKind) -> String {
        switch k {
        case .birthday: return "Birthday"
        case .anniversary: return "Anniversary"
        case .custom: return ""
        }
    }

    private func placeholderForKind(_ k: DateKind) -> String {
        switch k {
        case .birthday: return "Birthday"
        case .anniversary: return "Wedding anniversary"
        case .custom: return "Triathlon, work start, etc."
        }
    }
}
