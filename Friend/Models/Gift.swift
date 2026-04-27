import Foundation

enum GiftStatus: String, Codable, Hashable {
    case wishlist
    case given
}

enum GiftReaction: String, Codable, Hashable, CaseIterable {
    case loved
    case neutral
    case disliked

    var label: String {
        switch self {
        case .loved: return "Loved it"
        case .neutral: return "Neutral"
        case .disliked: return "Didn't like"
        }
    }
}

struct Gift: Identifiable, Codable, Hashable {
    let id: UUID
    var personId: UUID
    var name: String
    var note: String?
    var status: GiftStatus
    var occasion: String?
    var givenDate: Date?
    var reaction: GiftReaction?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case personId = "person_id"
        case name
        case note
        case status
        case occasion
        case givenDate = "given_date"
        case reaction
        case createdAt = "created_at"
    }

    init(
        id: UUID,
        personId: UUID,
        name: String,
        note: String?,
        status: GiftStatus,
        occasion: String?,
        givenDate: Date?,
        reaction: GiftReaction?,
        createdAt: Date
    ) {
        self.id = id
        self.personId = personId
        self.name = name
        self.note = note
        self.status = status
        self.occasion = occasion
        self.givenDate = givenDate
        self.reaction = reaction
        self.createdAt = createdAt
    }

    /// Custom decoder because `gifts.given_date` is a Postgres `date` column —
    /// returned as "yyyy-MM-dd", not the ISO-8601 timestamp the default
    /// JSONDecoder strategy expects. Falls back to ISO-8601 in case the
    /// column type ever changes.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        personId = try c.decode(UUID.self, forKey: .personId)
        name = try c.decode(String.self, forKey: .name)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        status = try c.decode(GiftStatus.self, forKey: .status)
        occasion = try c.decodeIfPresent(String.self, forKey: .occasion)
        reaction = try c.decodeIfPresent(GiftReaction.self, forKey: .reaction)
        createdAt = try c.decode(Date.self, forKey: .createdAt)

        if let s = try c.decodeIfPresent(String.self, forKey: .givenDate) {
            givenDate = Gift.parseDate(s)
        } else {
            givenDate = nil
        }
    }

    private static let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static func parseDate(_ s: String) -> Date? {
        if let d = dateOnlyFormatter.date(from: s) { return d }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: s) { return d }
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: s)
    }
}
