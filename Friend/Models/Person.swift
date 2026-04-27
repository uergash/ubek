import Foundation

struct Person: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID
    var name: String
    var relation: String
    var avatarHue: Int
    var phone: String?
    var email: String?
    var iosContactId: String?
    var contactFrequencyDays: Int?
    var lastInteractionAt: Date?
    /// Base64-encoded JPEG thumbnail, populated by the Contacts import flow
    /// when the source contact has a photo. Nil → fall back to gradient initials.
    var avatarImageData: String? = nil
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case relation
        case avatarHue = "avatar_hue"
        case phone
        case email
        case iosContactId = "ios_contact_id"
        case contactFrequencyDays = "contact_frequency_days"
        case lastInteractionAt = "last_interaction_at"
        case avatarImageData = "avatar_image_data"
        case createdAt = "created_at"
    }
}

extension Person {
    var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    /// Decodes the stored base64 thumbnail into Data, or nil if absent.
    func avatarImageDecoded() -> Data? {
        guard let s = avatarImageData, !s.isEmpty else { return nil }
        return Data(base64Encoded: s)
    }
}
