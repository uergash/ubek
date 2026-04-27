import XCTest
@testable import Friend

final class PersonTests: XCTestCase {
    func test_firstName_singleWord() {
        XCTAssertEqual(Fixtures.person(name: "Alex").firstName, "Alex")
    }

    func test_firstName_multiWord() {
        XCTAssertEqual(Fixtures.person(name: "Priya Sharma").firstName, "Priya")
    }

    func test_initials_two_words() {
        XCTAssertEqual(Fixtures.person(name: "Alex Rivera").initials, "AR")
    }

    func test_initials_single_word() {
        XCTAssertEqual(Fixtures.person(name: "Mom").initials, "M")
    }

    func test_initials_caps_lowercase() {
        XCTAssertEqual(Fixtures.person(name: "alex rivera").initials, "AR")
    }

    func test_initials_three_words_takes_first_two() {
        XCTAssertEqual(Fixtures.person(name: "Anna Marie Lopez").initials, "AM")
    }

    func test_daysSinceLastInteraction_uses_calendar_days() {
        let p = Fixtures.person(lastInteractionDaysAgo: 5)
        XCTAssertEqual(p.daysSinceLastInteraction(now: Fixtures.now), 5)
    }

    func test_daysSinceLastInteraction_never_seen_returns_nil() {
        let p = Fixtures.person(lastInteractionDaysAgo: nil)
        XCTAssertNil(p.daysSinceLastInteraction())
    }
}
