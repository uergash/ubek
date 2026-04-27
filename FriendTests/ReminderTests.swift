import XCTest
@testable import Friend

final class ReminderTests: XCTestCase {
    func test_isOverdue_when_past_and_not_completed() {
        let r = Fixtures.reminder(dueDaysFromNow: -2, completed: false)
        XCTAssertTrue(r.isOverdue)
    }

    func test_not_overdue_when_completed() {
        let r = Fixtures.reminder(dueDaysFromNow: -2, completed: true)
        XCTAssertFalse(r.isOverdue)
    }

    func test_not_overdue_when_due_in_future() {
        let r = Fixtures.reminder(dueDaysFromNow: 3)
        XCTAssertFalse(r.isOverdue)
    }

    func test_dueLabel_completed_says_done() {
        let r = Fixtures.reminder(dueDaysFromNow: -1, completed: true)
        XCTAssertEqual(r.dueLabel, "Done")
    }

    func test_dueLabel_today() {
        let r = Reminder(
            id: UUID(),
            personId: UUID(),
            title: "x",
            dueAt: Calendar.current.startOfDay(for: Date()).addingTimeInterval(60 * 60 * 23),
            completed: false,
            createdAt: Date()
        )
        XCTAssertEqual(r.dueLabel, "Today")
    }

    func test_dueLabel_tomorrow() {
        let dueAt = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let r = Reminder(
            id: UUID(), personId: UUID(), title: "x",
            dueAt: dueAt, completed: false, createdAt: Date()
        )
        XCTAssertEqual(r.dueLabel, "Tomorrow")
    }

    func test_dueLabel_one_day_overdue_singular() {
        let dueAt = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let r = Reminder(
            id: UUID(), personId: UUID(), title: "x",
            dueAt: dueAt, completed: false, createdAt: Date()
        )
        XCTAssertEqual(r.dueLabel, "1 day overdue")
    }

    func test_dueLabel_multiple_days_overdue_plural() {
        let dueAt = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let r = Reminder(
            id: UUID(), personId: UUID(), title: "x",
            dueAt: dueAt, completed: false, createdAt: Date()
        )
        XCTAssertEqual(r.dueLabel, "5 days overdue")
    }

    func test_dueLabel_in_future_days() {
        let dueAt = Calendar.current.date(byAdding: .day, value: 4, to: Date())!
        let r = Reminder(
            id: UUID(), personId: UUID(), title: "x",
            dueAt: dueAt, completed: false, createdAt: Date()
        )
        XCTAssertEqual(r.dueLabel, "in 4 days")
    }
}
