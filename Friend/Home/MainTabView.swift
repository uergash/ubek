import SwiftUI

/// Routes navigation to a person's profile, optionally pinned to a specific
/// initial tab (e.g. Notes after a fresh save).
struct ProfileDestination: Hashable {
    let personId: UUID
    var initialTab: ProfileView.Tab = .overview
}

@MainActor
struct MainTabView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var activeTab: MainTab = .home
    @State private var navPath = NavigationPath()
    @State private var pendingNote: PendingNote?
    @State private var showingPersonPicker = false
    @State private var showingCaptureChoice = false
    @State private var showingAddStory = false
    /// Choice picked in the FAB sheet — read in onDismiss to chain into the
    /// matching capture sheet without nested presentations.
    @State private var pendingChoice: CaptureChoice?
    private let router = NotificationRouter.shared

    /// Wraps the people a new-note sheet should open for. `openedFromFAB` is
    /// true when the sheet was launched from the global "+" button or a deep
    /// link; false when launched from inside an existing profile (where we
    /// don't want to push a duplicate profile after save).
    struct PendingNote: Identifiable {
        let id = UUID()
        let people: [Person]
        var openedFromFAB: Bool = true
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground.ignoresSafeArea()

            NavigationStack(path: $navPath) {
                tabContent
                    .navigationDestination(for: ProfileDestination.self) { dest in
                        ProfileView(personId: dest.personId, initialTab: dest.initialTab) { p in
                            // Sheets opened from inside a profile shouldn't
                            // re-navigate when they save — we're already there.
                            pendingNote = PendingNote(people: [p], openedFromFAB: false)
                        }
                    }
            }

            MainTabBar(
                active: $activeTab,
                onSelect: { _ in
                    // Pop to root on every tab tap, including taps on the
                    // already-active tab — matches standard iOS tab bar UX.
                    navPath = NavigationPath()
                },
                onAdd: { showingCaptureChoice = true }
            )
        }
        .sheet(item: $pendingNote) { pending in
            AddNoteView(people: pending.people) { primary in
                guard pending.openedFromFAB else { return }
                navPath.append(ProfileDestination(personId: primary.id, initialTab: .notes))
            }
        }
        .sheet(isPresented: $showingPersonPicker) {
            PersonPickerSheet { people in
                pendingNote = PendingNote(people: people, openedFromFAB: true)
            }
        }
        .sheet(isPresented: $showingAddStory) {
            AddStoryView()
        }
        .sheet(
            isPresented: $showingCaptureChoice,
            onDismiss: {
                // SwiftUI can't stack two sheets at once; chain via onDismiss
                // so the next capture sheet only opens after this one is gone.
                switch pendingChoice {
                case .story: showingAddStory = true
                case .note:  showingPersonPicker = true
                case .none:  break
                }
                pendingChoice = nil
            }
        ) {
            CaptureChoiceSheet { choice in pendingChoice = choice }
        }
        .onChange(of: router.pendingPersonId) { _, newId in
            guard let id = newId else { return }
            Task { @MainActor in
                if let person = try? await SupabaseService.shared.fetchPeople()
                    .first(where: { $0.id == id }) {
                    activeTab = .home
                    navPath.append(ProfileDestination(personId: person.id))
                }
                router.pendingPersonId = nil
            }
        }
        .onOpenURL { url in
            guard url.scheme == "friend" else { return }
            guard let id = UUID(uuidString: url.lastPathComponent) else { return }
            switch url.host {
            case "person":
                router.pendingPersonId = id
            case "add-note":
                Task { @MainActor in
                    if let person = try? await SupabaseService.shared.fetchPeople()
                        .first(where: { $0.id == id }) {
                        // Treat as FAB-style entry — land on the profile after save.
                        pendingNote = PendingNote(people: [person], openedFromFAB: true)
                    }
                }
            default:
                break
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch activeTab {
        case .home:
            HomeView(
                onOpenPerson: { person in
                    navPath.append(ProfileDestination(personId: person.id))
                },
                onOpenReminder: { person in
                    navPath.append(ProfileDestination(personId: person.id, initialTab: .reminders))
                },
                onAddNote: { p in
                    if let p { pendingNote = PendingNote(people: [p], openedFromFAB: true) }
                }
            )
        case .stories:
            StoriesView()
        case .people:
            PeopleView(onOpenPerson: { person in
                navPath.append(ProfileDestination(personId: person.id))
            })
        case .settings:
            SettingsView { person in
                navPath.append(ProfileDestination(personId: person.id))
            }
        }
    }
}
