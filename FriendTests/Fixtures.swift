import Foundation
@testable import Friend

/// Shared fixtures for unit + snapshot tests. All ids and dates are
/// deterministic so snapshots and assertions stay stable across runs.
enum Fixtures {
    static let userId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    /// Anchor date used as "now" for tests that compare against today/yesterday.
    /// Snapshots that depend on relative-date strings should pass this in.
    static let now: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 25
        components.hour = 12
        return Calendar(identifier: .gregorian).date(from: components)!
    }()

    static func date(daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: now)!
    }

    static func person(
        id: UUID = UUID(),
        name: String = "Alex Rivera",
        relation: String = "Friend",
        avatarHue: Int = 22,
        contactFrequencyDays: Int? = nil,
        lastInteractionDaysAgo: Int? = 5
    ) -> Person {
        Person(
            id: id,
            userId: userId,
            name: name,
            relation: relation,
            avatarHue: avatarHue,
            phone: nil,
            email: nil,
            iosContactId: nil,
            contactFrequencyDays: contactFrequencyDays,
            lastInteractionAt: lastInteractionDaysAgo.map { date(daysAgo: $0) },
            createdAt: date(daysAgo: 200)
        )
    }

    static func note(
        id: UUID = UUID(),
        personId: UUID = UUID(),
        type: InteractionType = .coffee,
        body: String = "Caught up over coffee — talked about her trip to Lisbon and the new role.",
        daysAgo: Int = 3,
        noteGroupId: UUID? = nil
    ) -> Note {
        Note(
            id: id,
            personId: personId,
            interactionType: type,
            body: body,
            createdAt: date(daysAgo: daysAgo),
            noteGroupId: noteGroupId
        )
    }

    static func reminder(
        title: String = "Send the book recommendation",
        dueDaysFromNow: Int = 1,
        completed: Bool = false
    ) -> Reminder {
        let due = Calendar.current.date(byAdding: .day, value: dueDaysFromNow, to: now)!
        return Reminder(
            id: UUID(),
            personId: UUID(),
            title: title,
            dueAt: due,
            completed: completed,
            createdAt: date(daysAgo: 1)
        )
    }
}
