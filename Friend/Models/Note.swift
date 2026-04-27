import Foundation

enum InteractionType: String, Codable, CaseIterable, Hashable {
    case call = "Call"
    case coffee = "Coffee"
    case drinks = "Drinks"
    case event = "Event"
    case other = "Other"

    var iconName: String {
        switch self {
        case .call: return "phone.fill"
        case .coffee: return "cup.and.saucer.fill"
        case .drinks: return "wineglass.fill"
        case .event: return "calendar"
        case .other: return "doc.text"
        }
    }
}

struct Note: Identifiable, Codable, Hashable {
    let id: UUID
    var personId: UUID
    var interactionType: InteractionType
    var body: String
    let createdAt: Date
    /// Shared id when one capture was logged against multiple people. Null for
    /// single-person notes.
    var noteGroupId: UUID?

    init(
        id: UUID,
        personId: UUID,
        interactionType: InteractionType,
        body: String,
        createdAt: Date,
        noteGroupId: UUID? = nil
    ) {
        self.id = id
        self.personId = personId
        self.interactionType = interactionType
        self.body = body
        self.createdAt = createdAt
        self.noteGroupId = noteGroupId
    }

    enum CodingKeys: String, CodingKey {
        case id
        case personId = "person_id"
        case interactionType = "interaction_type"
        case body
        case createdAt = "created_at"
        case noteGroupId = "note_group_id"
    }
}
