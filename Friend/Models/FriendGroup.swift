import Foundation

struct FriendGroup: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID
    var name: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case createdAt = "created_at"
    }
}

struct GroupMember: Codable, Hashable {
    var groupId: UUID
    var personId: UUID

    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case personId = "person_id"
    }
}
