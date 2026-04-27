import SwiftUI

@MainActor
@Observable
final class ImportContactsViewModel {
    enum LoadState {
        case idle, prompt, requesting, loading, denied, ready, importing
    }

    var loadState: LoadState = .idle
    var contacts: [ImportableContact] = []
    var selected: Set<String> = []
    var errorMessage: String?

    nonisolated init() {}

    /// Runs on view appear. Surfaces a consent screen *before* requesting
    /// the OS Contacts permission, so the user has chosen to import before
    /// we trigger the system prompt (App Store guideline 5.1.1).
    func load() async {
        switch ContactsService.shared.currentAccess {
        case .authorized:
            await fetch()
        case .denied, .restricted:
            loadState = .denied
        case .notDetermined:
            // Wait for the user to tap "Choose contacts" before prompting.
            loadState = .prompt
        }
    }

    /// Called when the user taps the explicit "Choose contacts" button.
    func requestAccessAndFetch() async {
        loadState = .requesting
        do {
            let granted = try await ContactsService.shared.requestAccess()
            if granted { await fetch() } else { loadState = .denied }
        } catch {
            errorMessage = error.localizedDescription
            loadState = .denied
        }
    }

    private func fetch() async {
        loadState = .loading
        do {
            let pulled = try await ContactsService.shared.fetchContacts()
            contacts = pulled
            // Default to selecting people with a birthday — they're most useful for the app.
            selected = Set(pulled.filter { $0.hasBirthday }.prefix(8).map { $0.id })
            loadState = .ready
        } catch {
            errorMessage = error.localizedDescription
            loadState = .denied
        }
    }

    func toggle(_ contact: ImportableContact) {
        if selected.contains(contact.id) { selected.remove(contact.id) }
        else { selected.insert(contact.id) }
    }

    /// Imports the selected contacts as Person rows + ImportantDate rows for birthdays.
    func importSelected() async -> Bool {
        guard let userId = SupabaseService.shared.currentUserId else { return false }
        loadState = .importing
        let chosen = contacts.filter { selected.contains($0.id) }
        do {
            for contact in chosen {
                let person = Person(
                    id: UUID(),
                    userId: userId,
                    name: contact.name,
                    relation: "Friend",
                    avatarHue: contact.avatarHue,
                    phone: contact.phone,
                    email: contact.email,
                    iosContactId: contact.id,
                    contactFrequencyDays: nil,
                    lastInteractionAt: nil,
                    avatarImageData: contact.thumbnailImageData?.base64EncodedString(),
                    createdAt: Date()
                )
                let created = try await SupabaseService.shared.createPerson(person)

                if let m = contact.birthdayMonth, let d = contact.birthdayDay {
                    let date = ImportantDate(
                        id: UUID(),
                        personId: created.id,
                        kind: .birthday,
                        label: "Birthday",
                        dateMonth: m,
                        dateDay: d,
                        remind: true,
                        remindDaysBefore: 1,
                        createdAt: Date()
                    )
                    _ = try await SupabaseService.shared.createDate(date)
                }
            }
            if !chosen.isEmpty { AppEvents.personChanged() }
            return true
        } catch {
            errorMessage = error.localizedDescription
            loadState = .ready
            return false
        }
    }
}

@MainActor
struct ImportContactsView: View {
    @State private var viewModel = ImportContactsViewModel()
    /// When true, the view shows the onboarding step indicator + welcoming copy.
    /// When false (e.g. opened from Settings), it shows a more direct title.
    var isOnboarding: Bool = true
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                header.padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 16)
                content
                Spacer(minLength: 0)
                footer
            }
        }
        .task { await viewModel.load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isOnboarding {
                Text("Step 3 of 4")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(0.96)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.accent)
            }
            Text(isOnboarding ? "Start with people\nyou already know" : "Import contacts")
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.56)
                .lineSpacing(2)
            Text("Pick a few from your contacts. We'll bring over their name, phone, and birthday.")
                .font(.system(size: 15))
                .foregroundStyle(Color.inkSoft)
                .lineSpacing(2)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .requesting, .loading, .importing:
            VStack { Spacer(); ProgressView(); Spacer() }
                .frame(maxWidth: .infinity)
        case .prompt:
            prompt
        case .denied:
            denied
        case .ready:
            list
        }
    }

    private var prompt: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Color.accent)
            Text("Bring people in from Contacts?")
                .font(.system(size: 17, weight: .semibold))
                .multilineTextAlignment(.center)
            Text("We'll only read the contacts you select. Names, phone numbers, and birthdays you tap \"Add\" become profiles in Friend.")
                .font(.system(size: 13.5))
                .foregroundStyle(Color.inkSoft)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 32)
            Button {
                Task { await viewModel.requestAccessAndFetch() }
            } label: {
                Text("Choose contacts")
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(Color.appBackground)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.ink))
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var denied: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Color.muted)
            Text("Contacts access is off")
                .font(.system(size: 17, weight: .semibold))
            Text("Open Settings to allow Friend to read your contacts, or skip this step.")
                .font(.system(size: 14))
                .foregroundStyle(Color.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(viewModel.contacts) { contact in
                    row(for: contact)
                    if contact.id != viewModel.contacts.last?.id {
                        Divider().background(Color.hairline).padding(.leading, 64)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private func row(for contact: ImportableContact) -> some View {
        let isOn = viewModel.selected.contains(contact.id)
        return Button {
            viewModel.toggle(contact)
        } label: {
            HStack(spacing: 12) {
                AvatarView(initials: initials(contact.name), hue: contact.avatarHue, size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.ink)
                    if let bday = contact.birthdayLabel {
                        Text(bday).font(.system(size: 12.5)).foregroundStyle(Color.muted)
                    }
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(isOn ? Color.accent : Color.hairline, lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    if isOn {
                        Circle().fill(Color.accent).frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider().background(Color.hairline)
            VStack(spacing: 12) {
                Button(action: importAndContinue) {
                    Text(viewModel.loadState == .importing
                         ? "Adding…"
                         : "Add \(viewModel.selected.count) \(viewModel.selected.count == 1 ? "person" : "people")")
                }
                .buttonStyle(AccentPrimaryLargeButton())
                .disabled(viewModel.selected.isEmpty || viewModel.loadState == .importing)

                Button(isOnboarding ? "Skip for now" : "Cancel", action: onFinish)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.muted)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 30)
            .background(Color.appBackground)
        }
    }

    private func importAndContinue() {
        Task {
            let ok = await viewModel.importSelected()
            if ok { onFinish() }
        }
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }
}
