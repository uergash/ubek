import Foundation

enum DateKind: String, Codable, Hashable, CaseIterable {
    case birthday
    case anniversary
    case custom

    var iconName: String {
        switch self {
        case .birthday: return "birthday.cake.fill"
        case .anniversary: return "heart.fill"
        case .custom: return "star.fill"
        }
    }
}

struct ImportantDate: Identifiable, Codable, Hashable {
    let id: UUID
    var personId: UUID
    var kind: DateKind
    var label: String
    var dateMonth: Int
    var dateDay: Int
    var remind: Bool
    var remindDaysBefore: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case personId = "person_id"
        case kind
        case label
        case dateMonth = "date_month"
        case dateDay = "date_day"
        case remind
        case remindDaysBefore = "remind_days_before"
        case createdAt = "created_at"
    }
}

extension ImportantDate {
    /// Returns the next occurrence of this date (today or in the future).
    var nextOccurrence: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let year = calendar.component(.year, from: today)

        var components = DateComponents(year: year, month: dateMonth, day: dateDay)
        if let candidate = calendar.date(from: components), candidate >= today {
            return candidate
        }
        components.year = year + 1
        return calendar.date(from: components) ?? today
    }

    var daysUntilNext: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.dateComponents([.day], from: today, to: nextOccurrence).day ?? 0
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: nextOccurrence)
    }
}
