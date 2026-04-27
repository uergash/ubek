import SwiftUI

/// Edit form for a Person. Lets the user change name, relation, contact info,
/// avatar color, and per-person reach-out frequency. Includes a destructive
/// Delete action at the bottom.
@MainActor
struct EditPersonSheet: View {
    @Bindable var viewModel: ProfileViewModel
    var profileDefaultFrequency: Int
    var onDeleted: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var relation: String = "Friend"
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var avatarHue: Int = 22
    /// Nil means "use profile default."
    @State private var frequencyOverride: Int? = nil

    @State private var showingDeleteConfirm = false

    /// Stable hues used by AvatarView. Spread around the wheel so adjacent
    /// swatches read as distinct in the picker.
    private let hueOptions: [Int] = [0, 22, 60, 120, 160, 200, 240, 280, 320]

    /// Frequency options match the profile-level FrequencyPickerSheet so the
    /// per-person override speaks the same language.
    private let frequencyOptions: [Int] = [7, 14, 21, 30, 60, 90]

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section("Relation") {
                    relationPicker
                }

                Section("Contact") {
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Avatar color") {
                    huePicker
                }

                Section {
                    frequencyPicker
                } header: {
                    Text("Reach-out cadence")
                } footer: {
                    Text(frequencyFooter)
                }

                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete person").font(.system(size: 15, weight: .semibold))
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.updatePerson(
                                name: trimmedName,
                                relation: relation,
                                phone: phone.isEmpty ? nil : phone,
                                email: email.isEmpty ? nil : email,
                                avatarHue: avatarHue,
                                contactFrequencyDays: frequencyOverride
                            )
                            dismiss()
                        }
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
        .onAppear { hydrateFromPerson() }
        .alert("Delete \(trimmedName.isEmpty ? "this person" : trimmedName)?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task {
                    let ok = await viewModel.deletePerson()
                    if ok {
                        dismiss()
                        onDeleted()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes their notes, facts, gifts, dates, and reminders. This cannot be undone.")
        }
    }

    private func hydrateFromPerson() {
        guard let p = viewModel.person else { return }
        name = p.name
        relation = p.relation
        phone = p.phone ?? ""
        email = p.email ?? ""
        avatarHue = p.avatarHue
        frequencyOverride = p.contactFrequencyDays
    }

    // ─── Relation ──────────────────────────────────────────────────────────
    private let relationPresets = ["Friend", "Family", "Partner", "Colleague", "Other"]

    @ViewBuilder
    private var relationPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(relationPresets, id: \.self) { option in
                    let isActive = relation == option
                    Button { relation = option } label: {
                        Text(option)
                            .font(.system(size: 13.5, weight: .medium))
                            .foregroundStyle(isActive ? Color.appBackground : Color.ink)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(isActive ? Color.ink : Color.chipBg))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
        TextField("Custom relation", text: $relation)
            .font(.system(size: 14))
    }

    // ─── Avatar hue ────────────────────────────────────────────────────────
    private var huePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(hueOptions, id: \.self) { h in
                    Button { avatarHue = h } label: {
                        AvatarView(initials: initialsForPreview, hue: h, size: 38, ring: avatarHue == h)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var initialsForPreview: String {
        let parts = trimmedName.split(separator: " ").prefix(2)
        let s = parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
        return s.isEmpty ? "?" : s
    }

    // ─── Frequency override ────────────────────────────────────────────────
    @ViewBuilder
    private var frequencyPicker: some View {
        Picker("Frequency", selection: bindingForFrequency) {
            Text("Use default (\(profileDefaultFrequency)d)").tag(Int?.none)
            ForEach(frequencyOptions, id: \.self) { d in
                Text(label(for: d)).tag(Int?.some(d))
            }
        }
        .pickerStyle(.inline)
        .labelsHidden()
    }

    private var bindingForFrequency: Binding<Int?> {
        Binding(
            get: { frequencyOverride },
            set: { frequencyOverride = $0 }
        )
    }

    private var frequencyFooter: String {
        if frequencyOverride == nil {
            return "Following your account default of \(profileDefaultFrequency) days."
        }
        return "Overrides the account default for this person only."
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
