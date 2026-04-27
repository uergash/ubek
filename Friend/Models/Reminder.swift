import Foundation

/// A one-shot, time-bound to-do attached to a person — distinct from
/// `ImportantDate` (which is annual / recurring).
struct Reminder: Identifiable, Codable, Hashable {
    let id: UUID
    var personId: UUID
    var title: String
    var dueAt: Date
    var completed: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case personId = "person_id"
        case title
        case dueAt = "due_at"
        case completed
        case createdAt = "created_at"
    }
}

extension Reminder {
    /// Days until due, with overdue values returning a negative number.
    func daysUntilDue(now: Date = Date()) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: now)
        let end = cal.startOfDay(for: dueAt)
        return cal.dateComponents([.day], from: start, to: end).day ?? 0
    }

    var isOverdue: Bool { !completed && dueAt < Date() }

    /// Short label like "in 2 days", "tomorrow", "today", "2 days overdue".
    var dueLabel: String {
        if completed { return "Done" }
        let days = daysUntilDue()
        if days < 0 {
            return abs(days) == 1 ? "1 day overdue" : "\(abs(days)) days overdue"
        }
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        return "in \(days) days"
    }
}
