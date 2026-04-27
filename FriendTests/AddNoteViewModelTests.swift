import XCTest
@testable import Friend

/// Tests for AddNoteViewModel state that doesn't require talking to Supabase.
/// The save/extract flows hit network and aren't covered here — they need a
/// SupabaseService protocol + a test double, which is a larger refactor.
@MainActor
final class AddNoteViewModelTests: XCTestCase {
    func test_isMultiPerson_false_for_single_person_init() {
        let vm = AddNoteViewModel(person: Fixtures.person())
        XCTAssertFalse(vm.isMultiPerson)
        XCTAssertEqual(vm.people.count, 1)
    }

    func test_isMultiPerson_true_for_two_or_more() {
        let vm = AddNoteViewModel(people: [Fixtures.person(), Fixtures.person()])
        XCTAssertTrue(vm.isMultiPerson)
    }

    func test_isMultiPerson_false_for_single_in_array_init() {
        let vm = AddNoteViewModel(people: [Fixtures.person()])
        XCTAssertFalse(vm.isMultiPerson)
    }

    func test_primary_person_is_first_selected() {
        let primary = Fixtures.person(name: "Alex Rivera")
        let secondary = Fixtures.person(name: "Priya Sharma")
        let vm = AddNoteViewModel(people: [primary, secondary])
        XCTAssertEqual(vm.person.id, primary.id)
    }

    func test_toggleFact_flips_keep_state() {
        let vm = AddNoteViewModel(person: Fixtures.person())
        vm.candidateFacts = [
            .init(text: "Loves indie movies"),
            .init(text: "Has a younger brother in Madrid"),
        ]
        let firstId = vm.candidateFacts[0].id
        XCTAssertTrue(vm.candidateFacts[0].keep)
        vm.toggleFact(firstId)
        XCTAssertFalse(vm.candidateFacts[0].keep)
        XCTAssertTrue(vm.candidateFacts[1].keep, "Toggling one fact must not affect siblings")
    }

    func test_default_interaction_type_is_coffee() {
        let vm = AddNoteViewModel(person: Fixtures.person())
        XCTAssertEqual(vm.interactionType, .coffee)
    }

    func test_starts_in_compose_mode() {
        let vm = AddNoteViewModel(person: Fixtures.person())
        XCTAssertEqual(vm.mode, .compose)
    }
}
