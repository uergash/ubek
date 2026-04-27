import SwiftUI

/// Manual create-person form. Used when the user wants to add someone who
/// isn't in their iOS Contacts (or who they didn't import at onboarding).
@MainActor
struct NewPersonSheet: View {
    var profileDefaultFrequency: Int
    var onCreate: (Person) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var relation: String = "Friend"
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var avatarHue: Int = randomHue()
    @State private var frequencyOverride: Int? = nil
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let hueOptions: [Int] = [0, 22, 60, 120, 160, 200, 240, 280, 320]
    private let frequencyOptions: [Int] = [7, 14, 21, 30, 60, 90]
    private let relationPresets = ["Friend", "Family", "Partner", "Colleague", "Other"]

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
                    TextField("Phone (optional)", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    TextField("Email (optional)", text: $email)
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

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.healthRed)
                    }
                }
            }
            .navigationTitle("New person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Add") { Task { await save() } }
                        .disabled(trimmedName.isEmpty || isSaving)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        guard let userId = await SupabaseService.shared.resolveCurrentUserId() else {
            errorMessage = "Not signed in."
            return
        }
        let person = Person(
            id: UUID(),
            userId: userId,
            name: trimmedName,
            relation: relation,
            avatarHue: avatarHue,
            phone: phone.isEmpty ? nil : phone,
            email: email.isEmpty ? nil : email,
            iosContactId: nil,
            contactFrequencyDays: frequencyOverride,
            lastInteractionAt: nil,
            createdAt: Date()
        )
        do {
            let saved = try await SupabaseService.shared.createPerson(person)
            AppEvents.personChanged()
            onCreate(saved)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // ─── Relation ──────────────────────────────────────────────────────────
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
        Binding(get: { frequencyOverride }, set: { frequencyOverride = $0 })
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

    private static func randomHue() -> Int {
        [0, 22, 60, 120, 160, 200, 240, 280, 320].randomElement() ?? 22
    }
}
