import SwiftUI

@MainActor
struct RemindersTabView: View {
    @Bindable var viewModel: ProfileViewModel
    var onAdd: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Button(action: onAdd) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("New reminder")
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

            if viewModel.reminders.isEmpty {
                Text("No reminders yet. Tap above to add one.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.muted)
                    .multilineTextAlignment(.center)
                    .padding(30)
            } else {
                if !viewModel.openReminders.isEmpty {
                    CardView(padding: 0) {
                        VStack(spacing: 0) {
                            ForEach(Array(viewModel.openReminders.enumerated()), id: \.element.id) { i, reminder in
                                row(reminder)
                                if i < viewModel.openReminders.count - 1 {
                                    Divider().background(Color.hairline).padding(.leading, 50)
                                }
                            }
                        }
                    }
                }

                if !viewModel.doneReminders.isEmpty {
                    SectionHeaderView(title: "Done (\(viewModel.doneReminders.count))")
                        .padding(.top, 6)
                    CardView(padding: 0) {
                        VStack(spacing: 0) {
                            ForEach(Array(viewModel.doneReminders.enumerated()), id: \.element.id) { i, reminder in
                                row(reminder)
                                if i < viewModel.doneReminders.count - 1 {
                                    Divider().background(Color.hairline).padding(.leading, 50)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func row(_ reminder: Reminder) -> some View {
        HStack(spacing: 14) {
            Button {
                Task { await viewModel.toggleReminderCompleted(reminder) }
            } label: {
                Image(systemName: reminder.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(reminder.completed ? Color.accent : Color.muted)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("reminder_check")
            .accessibilityLabel(reminder.completed ? "Reopen reminder" : "Mark reminder complete")

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(reminder.completed ? Color.muted : Color.ink)
                    .strikethrough(reminder.completed, color: Color.muted)
                Text(reminder.dueLabel)
                    .font(.system(size: 12.5))
                    .foregroundStyle(reminder.isOverdue ? Color.healthRed : Color.muted)
            }

            Spacer()

            Button {
                Task { await viewModel.deleteReminder(reminder) }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.muted)
                    .padding(8)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("reminder_delete")
            .accessibilityLabel("Delete reminder")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// ─── Add reminder sheet ────────────────────────────────────────────────────
struct AddReminderSheet: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var dueAt: Date

    init(viewModel: ProfileViewModel) {
        self._viewModel = Bindable(viewModel)
        // Default to tomorrow 9am
        let cal = Calendar.current
        var components = cal.dateComponents([.year, .month, .day], from: Date())
        components.day = (components.day ?? 1) + 1
        components.hour = 9
        components.minute = 0
        _dueAt = State(initialValue: cal.date(from: components) ?? Date().addingTimeInterval(24 * 3600))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder") {
                    TextField("e.g. Send Alex the book recommendation", text: $title, axis: .vertical)
                        .lineLimit(1...3)
                }
                Section("Due") {
                    DatePicker("When", selection: $dueAt)
                }
            }
            .navigationTitle("New reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.addReminder(title: title, dueAt: dueAt)
                            dismiss()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
