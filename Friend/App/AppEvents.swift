import Foundation

/// Cross-screen events broadcast via NotificationCenter, so e.g. the profile
/// view can refresh when a note is saved from a sheet over it. Also drive
/// cache invalidation for Home and People.
extension Notification.Name {
    static let friendNoteSaved = Notification.Name("friend.noteSaved")
    static let friendPersonChanged = Notification.Name("friend.personChanged")
    static let friendGroupChanged = Notification.Name("friend.groupChanged")
    static let friendProfileChanged = Notification.Name("friend.profileChanged")
}

enum AppEvents {
    static func noteSaved(personId: UUID) {
        NotificationCenter.default.post(
            name: .friendNoteSaved,
            object: nil,
            userInfo: ["personId": personId]
        )
    }

    /// Fire when a person is created, edited, or deleted. Invalidates Home/People caches.
    static func personChanged() {
        NotificationCenter.default.post(name: .friendPersonChanged, object: nil)
    }

    /// Fire when a group or its membership changes.
    static func groupChanged() {
        NotificationCenter.default.post(name: .friendGroupChanged, object: nil)
    }

    /// Fire when the user profile changes (default contact frequency, AI toggle, etc.)
    /// since several derived sections depend on profile fields.
    static func profileChanged() {
        NotificationCenter.default.post(name: .friendProfileChanged, object: nil)
    }

    /// Returns the personId out of a note-saved notification, if it matches.
    static func personId(from notification: Notification) -> UUID? {
        notification.userInfo?["personId"] as? UUID
    }
}
