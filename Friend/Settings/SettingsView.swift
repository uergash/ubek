import SwiftUI

@MainActor
struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(AuthViewModel.self) private var auth

    /// Called when the user taps a person row inside Year-in-Review.
    /// The host (MainTabView) dismisses the settings sheet and pushes onto navPath.
    var onOpenPerson: (Person) -> Void = { _ in }

    @State private var showingFrequencySheet = false
    @State private var showingImportContacts = false
    @State private var showingQuietHoursSheet = false
    @State private var showingYearReview = false
    @State private var showingDeleteConfirm = false
    @State private var showingDeleteFinal = false
    @State private var deleteError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Settings")
                    .font(.system(size: 28, weight: .bold))
                    .tracking(-0.56)
                    .padding(.top, 12)

                userCard

                section(title: "Reach-out cadence") {
                    settingRow(
                        icon: "calendar",
                        label: "Default frequency",
                        detail: "\(viewModel.profile?.defaultContactFrequencyDays ?? 21) days"
                    ) { showingFrequencySheet = true }
                    settingRow(
                        icon: "moon.fill",
                        label: "Quiet hours",
                        detail: quietHoursLabel
                    ) { showingQuietHoursSheet = true }
                }

                section(title: "Data") {
                    settingRow(icon: "person.2.fill", label: "Import contacts",
                               detail: "\(viewModel.peopleCount) people") {
                        showingImportContacts = true
                    }
                    toggleRow(
                        icon: "mic.fill",
                        label: "Voice transcription",
                        accessibilityId: "settings_voice_toggle",
                        isOn: Binding(
                            get: { viewModel.profile?.voiceEnabled ?? true },
                            set: { newValue in
                                Task { await viewModel.updateVoiceEnabled(newValue) }
                            }
                        )
                    )
                    toggleRow(
                        icon: "sparkles",
                        label: "AI features",
                        accessibilityId: "settings_ai_toggle",
                        isOn: Binding(
                            get: { viewModel.profile?.aiFeaturesEnabled ?? true },
                            set: { newValue in
                                Task { await viewModel.updateAIEnabled(newValue) }
                            }
                        )
                    )
                }

                section(title: "Reflection") {
                    settingRow(
                        icon: "calendar.badge.clock",
                        label: "Your year",
                        detail: String(Calendar.current.component(.year, from: Date()))
                    ) { showingYearReview = true }
                }

                Button {
                    Task { await auth.signOut() }
                } label: {
                    Text("Sign out")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.healthRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.card))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)

                Button {
                    showingDeleteConfirm = true
                } label: {
                    Text("Delete account")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.healthRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.healthRed.opacity(0.4), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)

                Text("Deleting your account permanently removes all your people, notes, dates, gifts, and reminders. This cannot be undone.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.muted)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 140)
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
        .task { await viewModel.load() }
        .sheet(isPresented: $showingFrequencySheet) {
            FrequencyPickerSheet(
                current: viewModel.profile?.defaultContactFrequencyDays ?? 21
            ) { days in
                Task { await viewModel.updateFrequency(days: days) }
            }
        }
        .sheet(isPresented: $showingImportContacts) {
            ImportContactsView(isOnboarding: false) {
                showingImportContacts = false
                // Refresh the people count shown on this row.
                Task { await viewModel.load() }
            }
        }
        .sheet(isPresented: $showingQuietHoursSheet) {
            QuietHoursPickerSheet(
                currentStart: viewModel.profile?.quietHoursStart ?? 21,
                currentEnd: viewModel.profile?.quietHoursEnd ?? 8
            ) { start, end in
                Task { await viewModel.updateQuietHours(start: start, end: end) }
            }
        }
        .sheet(isPresented: $showingYearReview) {
            YearInReviewView(year: Calendar.current.component(.year, from: Date())) { person in
                showingYearReview = false
                onOpenPerson(person)
            }
        }
        .confirmationDialog(
            "Delete account?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Continue", role: .destructive) { showingDeleteFinal = true }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently deletes your account and all your data. This cannot be undone.")
        }
        .alert("Are you absolutely sure?", isPresented: $showingDeleteFinal) {
            Button("Delete forever", role: .destructive) {
                Task {
                    let ok = await auth.deleteAccount()
                    if !ok { deleteError = auth.errorMessage ?? "Could not delete account." }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your people, notes, dates, gifts, and reminders will all be erased.")
        }
        .alert("Couldn't delete account", isPresented: .init(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK", role: .cancel) { deleteError = nil }
        } message: {
            Text(deleteError ?? "")
        }
    }

    private var userCard: some View {
        CardView {
            HStack(spacing: 14) {
                AvatarView(
                    initials: initials(viewModel.profile?.name ?? "?"),
                    hue: 22, size: 50
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.profile?.name ?? "—")
                        .font(.system(size: 16, weight: .semibold))
                    Text(viewModel.profile?.email ?? "")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.muted)
                }
                Spacer()
            }
        }
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeaderView(title: title)
            CardView(padding: 0) {
                VStack(spacing: 0) { content() }
            }
        }
    }

    /// Inline toggle row with the same icon styling as `settingRow`.
    private func toggleRow(
        icon: String,
        label: String,
        accessibilityId: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.accentSoft)
                    .frame(width: 30, height: 30)
                Image(systemName: icon).font(.system(size: 14)).foregroundStyle(Color.accentDeep)
            }
            Text(label).font(.system(size: 14.5, weight: .medium))
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.accent)
                .accessibilityIdentifier(accessibilityId)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private func settingRow(
        icon: String,
        label: String,
        detail: String,
        action: (() -> Void)? = nil
    ) -> some View {
        let row = HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.accentSoft)
                    .frame(width: 30, height: 30)
                Image(systemName: icon).font(.system(size: 14)).foregroundStyle(Color.accentDeep)
            }
            Text(label).font(.system(size: 14.5, weight: .medium))
            Spacer()
            Text(detail).font(.system(size: 13)).foregroundStyle(Color.muted)
            if action != nil {
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Color.muted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)

        return Group {
            if let action {
                Button(action: action) { row.contentShape(Rectangle()) }
                    .buttonStyle(.plain)
            } else {
                row
            }
        }
    }

    private var quietHoursLabel: String {
        let start = viewModel.profile?.quietHoursStart ?? 21
        let end = viewModel.profile?.quietHoursEnd ?? 8
        return "\(formatHour(start)) – \(formatHour(end))"
    }

    private func formatHour(_ h: Int) -> String {
        if h == 0 { return "12am" }
        if h == 12 { return "12pm" }
        if h < 12 { return "\(h)am" }
        return "\(h - 12)pm"
    }
}

struct FrequencyPickerSheet: View {
    let current: Int
    var onSave: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Int

    init(current: Int, onSave: @escaping (Int) -> Void) {
        self.current = current
        self.onSave = onSave
        _selected = State(initialValue: current)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("How often do you want to be in touch by default?") {
                    Picker("", selection: $selected) {
                        ForEach([7, 14, 21, 30, 60, 90], id: \.self) { days in
                            Text(label(for: days)).tag(days)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section {
                    Text("You can override this for any individual person on their profile.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.muted)
                }
            }
            .navigationTitle("Default frequency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(selected); dismiss() }
                }
            }
        }
    }

    private func label(for days: Int) -> String {
        switch days {
        case 7: return "Every week"
        case 14: return "Every 2 weeks"
        case 21: return "Every 3 weeks"
        case 30: return "Every month"
        case 60: return "Every 2 months"
        case 90: return "Every 3 months"
        default: return "Every \(days) days"
        }
    }
}
