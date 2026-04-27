import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()
    private init() {}

    enum Status {
        case notDetermined, denied, authorized, provisional
    }

    var currentStatus: Status {
        get async {
            let settings = await center.notificationSettings()
            switch settings.authorizationStatus {
            case .notDetermined: return .notDetermined
            case .denied:        return .denied
            case .authorized:    return .authorized
            case .provisional:   return .provisional
            case .ephemeral:     return .authorized
            @unknown default:    return .denied
            }
        }
    }

    @discardableResult
    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // ─── Reminder scheduling ───────────────────────────────────────────────

    /// Schedules a yearly recurring reminder for each `ImportantDate` with `remind=true`.
    /// Existing pending notifications for the same date id are replaced.
    func scheduleDateReminders(for person: Person, dates: [ImportantDate]) async {
        guard await currentStatus == .authorized else { return }

        // Cancel any existing pending notifications for this person's dates.
        let existingIds = dates.map { reminderIdentifier(for: $0) }
        center.removePendingNotificationRequests(withIdentifiers: existingIds)

        for date in dates where date.remind {
            await schedule(date: date, for: person)
        }
    }

    /// Schedules reminders for every person/date in one pass — call after data loads.
    func scheduleAllReminders(people: [Person], allDates: [ImportantDate]) async {
        guard await currentStatus == .authorized else { return }
        let datesByPerson = Dictionary(grouping: allDates, by: { $0.personId })
        for person in people {
            let dates = datesByPerson[person.id] ?? []
            await scheduleDateReminders(for: person, dates: dates)
        }
    }

    private func schedule(date: ImportantDate, for person: Person) async {
        let content = UNMutableNotificationContent()
        content.title = "\(person.firstName)'s \(date.label.lowercased()) is in \(date.remindDaysBefore) day\(date.remindDaysBefore == 1 ? "" : "s")"
        content.body = "Tap to open their profile and prep something thoughtful."
        content.sound = .default
        content.userInfo = [
            "person_id": person.id.uuidString,
            "kind": "date",
            "date_id": date.id.uuidString,
        ]

        // Compute trigger month/day with `remind_days_before` offset and yearly recurrence.
        let cal = Calendar.current
        var components = DateComponents()
        components.month = date.dateMonth
        components.day = date.dateDay
        components.hour = 9
        components.minute = 0

        // Subtract remind_days_before by going through a representative full date.
        if let representative = cal.date(from: components),
           let offset = cal.date(byAdding: .day, value: -date.remindDaysBefore, to: representative) {
            components = cal.dateComponents([.month, .day, .hour, .minute], from: offset)
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: reminderIdentifier(for: date),
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    private func reminderIdentifier(for date: ImportantDate) -> String {
        "date.\(date.id.uuidString)"
    }

    // ─── Reminder scheduling (one-shot) ────────────────────────────────────

    /// Schedules a one-shot notification for each uncompleted reminder.
    /// Cancels and re-installs every time so toggling complete / changing
    /// due date is naturally idempotent.
    func scheduleReminders(for person: Person, reminders: [Reminder]) async {
        guard await currentStatus == .authorized else { return }

        let allIds = reminders.map { reminderNotificationId(for: $0) }
        center.removePendingNotificationRequests(withIdentifiers: allIds)

        for reminder in reminders where !reminder.completed && reminder.dueAt > Date() {
            await schedule(reminder: reminder, for: person)
        }
    }

    private func schedule(reminder: Reminder, for person: Person) async {
        let content = UNMutableNotificationContent()
        content.title = "Reminder for \(person.firstName)"
        content.body = reminder.title
        content.sound = .default
        content.userInfo = [
            "person_id": person.id.uuidString,
            "kind": "reminder",
            "reminder_id": reminder.id.uuidString,
        ]

        let cal = Calendar.current
        let components = cal.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminder.dueAt
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: reminderNotificationId(for: reminder),
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    private func reminderNotificationId(for reminder: Reminder) -> String {
        "reminder.\(reminder.id.uuidString)"
    }

    // ─── Nudge notifications ───────────────────────────────────────────────

    /// Posts a one-off "reach out" nudge notification immediately. Used by the
    /// background refresh task when a person crosses the overdue threshold.
    func postNudge(for person: Person, suggestion: String) async {
        guard await currentStatus == .authorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "Reach out to \(person.firstName)?"
        content.body = suggestion
        content.sound = .default
        content.userInfo = [
            "person_id": person.id.uuidString,
            "kind": "nudge",
        ]
        let request = UNNotificationRequest(
            identifier: "nudge.\(person.id.uuidString).\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: nil
        )
        try? await center.add(request)
    }
}
