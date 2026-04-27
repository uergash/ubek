import Foundation
import Observation

/// Local-only persistence of dismissed reach-out suggestions. Keeps a
/// `personId → dismissedAt` map in UserDefaults and auto-resurfaces
/// suggestions after `cooldown` (14 days by default).
@MainActor
@Observable
final class DismissedSuggestionsStore {
    static let shared = DismissedSuggestionsStore()

    private static let key = "friend.dismissedSuggestions.v1"
    private static let cooldown: TimeInterval = 14 * 24 * 60 * 60

    /// personId → dismissedAt
    private(set) var dismissals: [UUID: Date] = [:]

    nonisolated init() {
        Task { @MainActor in self.load() }
    }

    private func load() {
        guard let raw = UserDefaults.standard.dictionary(forKey: Self.key) as? [String: TimeInterval] else { return }
        var parsed: [UUID: Date] = [:]
        for (k, v) in raw {
            if let id = UUID(uuidString: k) {
                parsed[id] = Date(timeIntervalSince1970: v)
            }
        }
        dismissals = parsed
    }

    private func persist() {
        let raw: [String: TimeInterval] = Dictionary(
            uniqueKeysWithValues: dismissals.map { ($0.key.uuidString, $0.value.timeIntervalSince1970) }
        )
        UserDefaults.standard.set(raw, forKey: Self.key)
    }

    /// Person IDs whose dismissal is still active (within the cooldown window).
    var activelyDismissed: Set<UUID> {
        let now = Date()
        return Set(dismissals.compactMap { id, date in
            now.timeIntervalSince(date) < Self.cooldown ? id : nil
        })
    }

    func dismiss(personId: UUID) {
        dismissals[personId] = Date()
        persist()
    }

    func undismiss(personId: UUID) {
        dismissals.removeValue(forKey: personId)
        persist()
    }
}
