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
                  suggestion: "Ask how the Lisbon trip went and the new role's first weeks."),
            .init(person: Fixtures.person(name: "Priya Sharma", avatarHue: 320, lastInteractionDaysAgo: 42),
                  suggestion: "Share the article on color systems she'd been looking for."),
            .init(person: Fixtures.person(name: "Sam Lee", avatarHue: 150, lastInteractionDaysAgo: 60),
                  suggestion: "Check in on his move and offer to help unpack this weekend."),
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
