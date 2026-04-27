import Foundation

struct KeyFact: Identifiable, Codable, Hashable {
    let id: UUID
    var personId: UUID
    var text: String
    var sourceNoteId: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case personId = "person_id"
        case text
        case sourceNoteId = "source_note_id"
        case createdAt = "created_at"
    }
}
