import Foundation

struct UserProfile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var email: String?
    var defaultContactFrequencyDays: Int
    var quietHoursStart: Int
    var quietHoursEnd: Int
    var aiFeaturesEnabled: Bool = true
    var voiceEnabled: Bool = true
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case defaultContactFrequencyDays = "default_contact_frequency_days"
        case quietHoursStart = "quiet_hours_start"
        case quietHoursEnd = "quiet_hours_end"
        case aiFeaturesEnabled = "ai_features_enabled"
        case voiceEnabled = "voice_enabled"
        case createdAt = "created_at"
    }
}
