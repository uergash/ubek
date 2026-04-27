import XCTest
@testable import Friend

final class ImportantDateTests: XCTestCase {
    private func date(month: Int, day: Int) -> ImportantDate {
        ImportantDate(
            id: UUID(),
            personId: UUID(),
            kind: .birthday,
            label: "Birthday",
            dateMonth: month,
            dateDay: day,
            remind: true,
            remindDaysBefore: 1,
            createdAt: Date()
        )
    }

    func test_today_returns_zero_days_until_next() {
        let cal = Calendar.current
        let today = Date()
        let d = date(month: cal.component(.month, from: today),
                     day: cal.component(.day, from: today))
        XCTAssertEqual(d.daysUntilNext, 0)
    }

    func test_tomorrow_returns_one_day() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let cal = Calendar.current
        let d = date(month: cal.component(.month, from: tomorrow),
                     day: cal.component(.day, from: tomorrow))
        XCTAssertEqual(d.daysUntilNext, 1)
    }

    func test_yesterday_rolls_to_next_year() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let cal = Calendar.current
        let d = date(month: cal.component(.month, from: yesterday),
                     day: cal.component(.day, from: yesterday))
        // Should be roughly 364–365 days, never negative
        XCTAssertGreaterThan(d.daysUntilNext, 360)
        XCTAssertLessThanOrEqual(d.daysUntilNext, 366)
    }
}
