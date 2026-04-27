import Foundation

/// In-memory cache of the last-loaded Home page state. Lets the Home tab
/// re-appear instantly without spinning the whole load chain again on every
/// tab switch. Cache lives only for the app session — invalidated by writes
/// (notes, people, groups, profile) and by a TTL safety net.
@MainActor
final class HomeCache {
    static let shared = HomeCache()

    struct Snapshot {
        var people: [Person]
        var profile: UserProfile?
        var upcomingDates: [(person: Person, date: ImportantDate)]
        var dueReminders: [(person: Person, reminder: Reminder)]
        var nudges: [HomeViewModel.Nudge]
        var celebrations: [OccasionCelebration]
        var memories: [HomeViewModel.Memory]
        var savedAt: Date
    }

    /// Five minutes — long enough to span a normal tab-switching session,
    /// short enough that data outside our invalidation events (e.g. a date
    /// crossing midnight, an external write) eventually refreshes on its own.
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
                Task { @MainActor in HomeCache.shared.invalidate() }
            }
        }
    }

    /// Returns the cached snapshot if present and within TTL. A stale entry
    /// is dropped on read so subsequent calls don't keep returning it.
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
