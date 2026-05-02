import Foundation

struct Story: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID
    var body: String
    var archivedAt: Date?
    let createdAt: Date

    init(
        id: UUID,
        userId: UUID,
        body: String,
        archivedAt: Date? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.body = body
        self.archivedAt = archivedAt
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case body
        case archivedAt = "archived_at"
        case createdAt = "created_at"
    }
}

struct SelfFact: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID
    var text: String
    var sourceStoryId: UUID?
    let createdAt: Date

    init(
        id: UUID,
        userId: UUID,
        text: String,
        sourceStoryId: UUID? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.text = text
        self.sourceStoryId = sourceStoryId
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case text
        case sourceStoryId = "source_story_id"
        case createdAt = "created_at"
    }
}
