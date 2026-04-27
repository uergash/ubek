import XCTest
@testable import Friend

final class HealthStateTests: XCTestCase {
    func test_green_when_well_within_frequency() {
        // 7 days since last, expected every 21 → ratio 0.33 → green
        XCTAssertEqual(HealthState.compute(lastInteractionDays: 7, frequencyDays: 21), .green)
    }

    func test_yellow_at_just_under_threshold() {
        // ratio 0.85 is the green/yellow boundary; >= 0.85 should be yellow
        XCTAssertEqual(HealthState.compute(lastInteractionDays: 18, frequencyDays: 21), .yellow)
    }

    func test_red_when_overdue() {
        // ratio 1.25+ → red
        XCTAssertEqual(HealthState.compute(lastInteractionDays: 30, frequencyDays: 21), .red)
    }

    func test_zero_frequency_is_safe() {
        // Defensive: never divide by zero
        XCTAssertEqual(HealthState.compute(lastInteractionDays: 100, frequencyDays: 0), .green)
    }

    func test_person_uses_per_person_override_when_set() {
        let p = Fixtures.person(contactFrequencyDays: 7, lastInteractionDaysAgo: 10)
        XCTAssertEqual(p.healthState(profileDefault: 90), .red, "Person override of 7d should win over default 90d")
    }

    func test_person_falls_back_to_profile_default() {
        let p = Fixtures.person(contactFrequencyDays: nil, lastInteractionDaysAgo: 5)
        XCTAssertEqual(p.healthState(profileDefault: 21), .green)
    }

    func test_never_seen_person_is_red() {
        let p = Fixtures.person(lastInteractionDaysAgo: nil)
        XCTAssertEqual(p.healthState(profileDefault: 21), .red)
    }

    func test_compute_returns_red_when_days_is_nil() {
        XCTAssertEqual(HealthState.compute(lastInteractionDays: nil, frequencyDays: 21), .red)
    }
}
