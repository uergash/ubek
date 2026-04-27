import XCTest
import SwiftUI
import SnapshotTesting
@testable import Friend

/// Snapshot regression tests for stand-alone SwiftUI components.
///
/// First run: change `record: false` → `record: .all` (or set
/// `isRecording = true` in setUp) to capture reference PNGs into
/// __Snapshots__. Commit those, then flip back to `record: false`.
@MainActor
final class NoteCardViewSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // isRecording = true   // ← uncomment + run once to refresh reference PNGs
    }

    func test_noteCard_singlePerson_withFacts() {
        let note = Fixtures.note()
        let view = NoteCardView(
            note: note,
            facts: ["Loves indie sci-fi", "New role at the design studio"],
            coAttendees: []
        )
        .frame(width: 360)
        .padding()
        .background(Color.appBackground)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func test_noteCard_multiPerson_attribution() {
        let groupId = UUID()
        let note = Fixtures.note(noteGroupId: groupId)
        let view = NoteCardView(
            note: note,
            facts: [],
            coAttendees: [
                Fixtures.person(name: "Priya Sharma", avatarHue: 320),
                Fixtures.person(name: "Sam Lee", avatarHue: 150),
            ]
        )
        .frame(width: 360)
        .padding()
        .background(Color.appBackground)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }

    func test_noteCard_no_facts_no_coattendees() {
        let view = NoteCardView(
            note: Fixtures.note(body: "Quick text. Just confirming Sunday."),
            facts: [],
            coAttendees: []
        )
        .frame(width: 360)
        .padding()
        .background(Color.appBackground)

        assertSnapshot(of: view, as: .image(layout: .sizeThatFits))
    }
}
