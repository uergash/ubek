import Foundation

/// Aggregates a year's worth of relationship activity for the Year-in-Review
/// screen. Cheap counts run client-side from already-fetched data; the
/// Claude-generated narrative is cached per-year in UserDefaults.
@MainActor
final class YearReviewService {
    static let shared = YearReviewService()
    private init() {}

    struct YearReview {
        let year: Int
        let totalNotes: Int
        let totalGifts: Int
        let topPeople: [TopPerson]
        let headline: String
        let reflection: String

        struct TopPerson: Identifiable {
            let person: Person
            let noteCount: Int
            var id: UUID { person.id }
        }
    }

    func loadReview(for year: Int) async -> YearReview? {
        let people = (try? await SupabaseService.shared.fetchPeople()) ?? []
        guard !people.isEmpty else { return nil }

        // Year window: Jan 1 to Dec 31 of the requested year.
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        let yearStart = cal.date(from: DateComponents(year: year, month: 1, day: 1)) ?? Date()
        let yearEnd = cal.date(from: DateComponents(year: year + 1, month: 1, day: 1)) ?? Date()

        // Pull all notes and gifts in parallel.
        var allNotesByPerson: [(person: Person, notes: [Note])] = []
        var allGiftsByPerson: [(person: Person, gifts: [Gift])] = []

        await withTaskGroup(of: (Person, [Note]).self) { group in
            for person in people {
                group.addTask {
                    let n = (try? await SupabaseService.shared.fetchNotes(personId: person.id)) ?? []
                    return (person, n)
                }
            }
            for await pair in group { allNotesByPerson.append(pair) }
        }
        await withTaskGroup(of: (Person, [Gift]).self) { group in
            for person in people {
                group.addTask {
                    let g = (try? await SupabaseService.shared.fetchGifts(personId: person.id)) ?? []
                    return (person, g)
                }
            }
            for await pair in group { allGiftsByPerson.append(pair) }
        }

        // Filter to the year window.
        let yearNotesByPerson: [(person: Person, notes: [Note])] = allNotesByPerson.map { p in
            (p.person, p.notes.filter { $0.createdAt >= yearStart && $0.createdAt < yearEnd })
        }
        let totalNotes = yearNotesByPerson.reduce(0) { $0 + $1.notes.count }

        let yearGiftsWithReactions: [(personName: String, gift: Gift)] = allGiftsByPerson.flatMap { p in
            p.gifts
                .filter { $0.status == .given && ($0.givenDate ?? .distantPast) >= yearStart && ($0.givenDate ?? .distantPast) < yearEnd }
                .map { (p.person.name, $0) }
        }
        let totalGifts = yearGiftsWithReactions.count

        // Top 5 people by year note count.
        let topPeople = yearNotesByPerson
            .filter { !$0.notes.isEmpty }
            .sorted { $0.notes.count > $1.notes.count }
            .prefix(5)
            .map { YearReview.TopPerson(person: $0.person, noteCount: $0.notes.count) }

        // Notable notes for Claude prompt: 1 per top person, longest body.
        let notableNotes: [(personName: String, note: Note)] = topPeople.compactMap { tp in
            yearNotesByPerson
                .first(where: { $0.person.id == tp.person.id })?
                .notes
                .max(by: { $0.body.count < $1.body.count })
                .map { (tp.person.firstName, $0) }
        }

        // Try cache first.
        let cacheKey = "yearReview.\(year)"
        if let cached = cachedReflection(forKey: cacheKey) {
            return YearReview(
                year: year,
                totalNotes: totalNotes,
                totalGifts: totalGifts,
                topPeople: topPeople,
                headline: cached.headline,
                reflection: cached.reflection
            )
        }

        // Otherwise call Claude (when AI on). On failure or AI off, return a
        // hand-written fallback so the screen still works.
        if UserSettings.shared.aiFeaturesEnabled {
            let topNamePairs = topPeople.map { (name: $0.person.firstName, noteCount: $0.noteCount) }
            if let result = try? await ClaudeService.shared.generateYearReview(
                year: year,
                totalNotes: totalNotes,
                totalGifts: totalGifts,
                topPeople: topNamePairs,
                notableNotes: notableNotes,
                giftsWithReactions: yearGiftsWithReactions
            ) {
                cacheReflection(headline: result.headline, reflection: result.reflection, forKey: cacheKey)
                return YearReview(
                    year: year,
                    totalNotes: totalNotes,
                    totalGifts: totalGifts,
                    topPeople: topPeople,
                    headline: result.headline,
                    reflection: result.reflection
                )
            }
        }

        // Fallback when Claude unavailable / disabled.
        let fallbackHeadline = totalNotes == 0
            ? "A year just getting started"
            : "A year of showing up"
        let fallbackReflection = totalNotes == 0
            ? "You're just getting started here. Log a few notes about people you care about and revisit this when there's a year to look back on."
            : "You logged \(totalNotes) interactions across \(topPeople.count) people. Take a moment today to think about who showed up for you — and who you showed up for."
        return YearReview(
            year: year,
            totalNotes: totalNotes,
            totalGifts: totalGifts,
            topPeople: topPeople,
            headline: fallbackHeadline,
            reflection: fallbackReflection
        )
    }

    // ─── Cache ─────────────────────────────────────────────────────────────
    private struct CachedReflection: Codable {
        let headline: String
        let reflection: String
    }

    private func cachedReflection(forKey key: String) -> CachedReflection? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(CachedReflection.self, from: data)
        else { return nil }
        return decoded
    }

    private func cacheReflection(headline: String, reflection: String, forKey key: String) {
        if let data = try? JSONEncoder().encode(CachedReflection(headline: headline, reflection: reflection)) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
