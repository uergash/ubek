import Foundation

/// Lightweight snapshot the main app writes for the widget to read.
/// Stored as JSON in shared UserDefaults so the widget extension can decode it
/// without touching Supabase or holding an auth session.
struct WidgetSnapshot: Codable {
    struct UpcomingItem: Codable, Hashable {
        let personId: UUID
        let firstName: String
        let avatarHue: Int
        let label: String
        let kind: DateKind
        let dateString: String   // e.g. "May 14"
        let daysAway: Int
    }

    struct NudgeItem: Codable, Hashable {
        let personId: UUID
        let firstName: String
        let avatarHue: Int
        let suggestion: String
    }

    var upcoming: [UpcomingItem]
    var nudges: [NudgeItem]
    var updatedAt: Date

    static let appGroupId = "group.ai.ubek.friend"
    static let storageKey = "widget.snapshot.v1"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    static func load() -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder.iso8601.decode(WidgetSnapshot.self, from: data)
    }

    static func save(_ snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder.iso8601.encode(snapshot) else { return }
        defaults?.set(data, forKey: storageKey)
    }
}

extension JSONEncoder {
    static let iso8601: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}

extension JSONDecoder {
    static let iso8601: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
