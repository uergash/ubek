import XCTest
import SwiftUI
import SnapshotTesting
@testable import Friend

@MainActor
final class NudgesStripViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // isRecording = true   // ← uncomment + run once to refresh reference PNG
    }

    func test_strip_with_three_suggestions() {
        let suggestions: [PeopleViewModel.Suggestion] = [
            .init(person: Fixtures.person(name: "Alex Rivera", avatarHue: 22, lastInteractionDaysAgo: 28),
                  suggestion: "Hey — how was Lisbon? And how are the first weeks in the new role treating you?"),
            .init(person: Fixtures.person(name: "Priya Sharma", avatarHue: 320, lastInteractionDaysAgo: 42),
                  suggestion: "Hey Priya — finally found that color systems article you were after. Sending it over."),
            .init(person: Fixtures.person(name: "Sam Lee", avatarHue: 150, lastInteractionDaysAgo: 60),
                  suggestion: "Hey Sam — how's the move been going? Free this weekend if you want help unpacking."),
        ]

        let view = NudgesStripView(
            suggestions: suggestions,
            onOpenPerson: { _ in },
            onDismiss: { _ in }
        )
        .frame(width: 390)
        .background(Color.appBackground)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }
}
