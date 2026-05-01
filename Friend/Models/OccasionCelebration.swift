import Foundation

/// All the info the OccasionTakeoverView needs in one place — built up by the
/// parent view model and handed to the card. Lives in Models so the widget
/// target (which compiles Models + Design) can reference it.
struct OccasionCelebration: Identifiable {
    let person: Person
    let date: ImportantDate
    let headline: String
    let summary: String
    let stats: Stats
    /// Up to ~3 wishlist gifts, surfaced inline on the takeover so the user
    /// has something concrete to act on. Empty if the person has no wishlist.
    let giftIdeas: [Gift]

    var id: UUID { date.id }

    struct Stats {
        let noteCount: Int
        let giftCount: Int
        let factCount: Int
    }
}
