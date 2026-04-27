import Foundation

/// In-memory cache of the last-loaded People page state. Mirrors `HomeCache`
/// — lets the tab re-appear instantly across navigation without re-running
/// the full load chain. Same invalidation triggers, same TTL.
@MainActor
final class PeopleCache {
    static let shared = PeopleCache()

    struct Snapshot {
        var people: [Person]
        var profile: UserProfile?
        var topContacts: [(person: Person, score: Int)]
        var suggestions: [PeopleViewModel.Suggestion]
        var groups: [FriendGroup]
        var groupMemberCounts: [UUID: Int]
        var spotlight: PeopleViewModel.Spotlight?
        var recentInteractions: [(person: Person, note: Note)]
        var savedAt: Date
    }

    private let ttl: TimeInterval = 300

    private var snapshot: Snapshot?
    private var observers: [NSObjectProtocol] = []

    private init() {
        let names: [Notification.Name] = [
            .friendNoteSaved,
            .friendPersonChanged,
            .friendGroupChanged,
            .friendProfileChanged
        ]
        let center = NotificationCenter.default
        observers = names.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { _ in
                Task { @MainActor in PeopleCache.shared.invalidate() }
            }
        }
    }

    func current() -> Snapshot? {
        guard let snap = snapshot else { return nil }
        guard Date().timeIntervalSince(snap.savedAt) < ttl else {
            snapshot = nil
            return nil
        }
        return snap
    }

    func store(_ snapshot: Snapshot) {
        self.snapshot = snapshot
    }

    func invalidate() {
        snapshot = nil
    }
}
