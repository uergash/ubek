import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    // ─── Loaded state ──────────────────────────────────────────────────────
    var people: [Person] = []
    var profile: UserProfile?
    private var allDates: [ImportantDate] = []
    private var allReminders: [Reminder] = []

    var upcomingDates: [(person: Person, date: ImportantDate)] = []
    var dueReminders: [(person: Person, reminder: Reminder)] = []
    var nudges: [Nudge] = []
    var celebrations: [OccasionCelebration] = []
    var memories: [Memory] = []

    /// One past-year note that fell on today's calendar date.
    struct Memory: Identifiable {
        let person: Person
        let note: Note
        let yearsAgo: Int
        var id: UUID { note.id }
    }

    var isLoading = false
    /// Stays true once the first `load()` completes. Lets the view hold a single
    /// loading state until every section's data is ready, instead of revealing
    /// sections one by one as their async work finishes.
    var hasLoaded = false
    var errorMessage: String?

    // ─── Nudge ─────────────────────────────────────────────────────────────
    struct Nudge: Identifiable {
        let person: Person
        let suggestion: String
        var id: UUID { person.id }
    }

    /// Hydrates from the in-memory cache so a re-mount (tab switch, deep link
    /// dismissal) renders the previous state immediately instead of flashing
    /// the loading view for the duration of `.task`.
    init() {
        applyCachedSnapshotIfAvailable()
    }

    @discardableResult
    private func applyCachedSnapshotIfAvailable() -> Bool {
        guard let snap = HomeCache.shared.current() else { return false }
        people = snap.people
        profile = snap.profile
        upcomingDates = snap.upcomingDates
        dueReminders = snap.dueReminders
        nudges = snap.nudges
        celebrations = snap.celebrations
        memories = snap.memories
        hasLoaded = true
        return true
    }

    /// Called from `.task` on first appear. Skips the network load entirely
    /// when a fresh cache snapshot is available; otherwise runs the full load.
    func loadIfNeeded() async {
        if applyCachedSnapshotIfAvailable() { return }
        await load()
    }

    // ─── Loading ───────────────────────────────────────────────────────────
    func load() async {
        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }

        // Wait for the auth session to be available before firing queries — otherwise
        // RLS-gated tables come back empty.
        guard await SupabaseService.shared.resolveCurrentUserId() != nil else {
            errorMessage = "Not signed in yet."
            return
        }

        do { people = try await SupabaseService.shared.fetchPeople() }
        catch is CancellationError {} catch { errorMessage = error.localizedDescription }

        do { profile = try await SupabaseService.shared.fetchProfile() }
        catch is CancellationError {} catch {}

        await loadUpcomingDates()
        await loadDueReminders()
        await loadMemories()
        await generateNudges()
        await loadCelebrations()
        await rescheduleAllReminders()
        writeWidgetSnapshot()
        saveSnapshot()

        if !people.isEmpty { errorMessage = nil }
    }

    private func saveSnapshot() {
        HomeCache.shared.store(.init(
            people: people,
            profile: profile,
            upcomingDates: upcomingDates,
            dueReminders: dueReminders,
            nudges: nudges,
            celebrations: celebrations,
            memories: memories,
            savedAt: Date()
        ))
    }

    private func writeWidgetSnapshot() {
        let upcoming: [WidgetSnapshot.UpcomingItem] = upcomingDates.prefix(5).map { (person, date) in
            WidgetSnapshot.UpcomingItem(
                personId: person.id,
                firstName: person.firstName,
                avatarHue: person.avatarHue,
                label: date.label,
                kind: date.kind,
                dateString: date.formattedDate,
                daysAway: date.daysUntilNext
            )
        }
        let nudgeItems: [WidgetSnapshot.NudgeItem] = nudges.prefix(2).map { n in
            WidgetSnapshot.NudgeItem(
                personId: n.person.id,
                firstName: n.person.firstName,
                avatarHue: n.person.avatarHue,
                suggestion: n.suggestion
            )
        }
        WidgetSnapshot.save(WidgetSnapshot(
            upcoming: upcoming,
            nudges: nudgeItems,
            updatedAt: Date()
        ))
        #if canImport(WidgetKit)
        WidgetKitReloader.reload()
        #endif
    }

    /// Re-installs both date-based and reminder-based local notifications.
    private func rescheduleAllReminders() async {
        await NotificationService.shared.scheduleAllReminders(people: people, allDates: allDates)
        let remindersByPerson = Dictionary(grouping: allReminders, by: { $0.personId })
        for person in people {
            let r = remindersByPerson[person.id] ?? []
            await NotificationService.shared.scheduleReminders(for: person, reminders: r)
        }
    }

    /// Pulls all important dates for everyone in parallel; surfaces dates within
    /// the next 30 days for the Home Upcoming section.
    private func loadUpcomingDates() async {
        var fullSet: [ImportantDate] = []
        var upcoming: [(person: Person, date: ImportantDate)] = []
        await withTaskGroup(of: (Person, [ImportantDate]).self) { group in
            for person in people {
                group.addTask {
                    let dates = (try? await SupabaseService.shared.fetchDates(personId: person.id)) ?? []
                    return (person, dates)
                }
            }
            for await (person, dates) in group {
                fullSet.append(contentsOf: dates)
                for d in dates where d.daysUntilNext <= 30 {
                    upcoming.append((person, d))
                }
            }
        }
        upcomingDates = upcoming.sorted { $0.date.daysUntilNext < $1.date.daysUntilNext }
        allDates = fullSet
    }

    /// Reminders due in the next 14 days, plus any overdue ones.
    private func loadDueReminders() async {
        do {
            let pulled = try await SupabaseService.shared.fetchUpcomingReminders(daysAhead: 14)
            allReminders = pulled
            let peopleById = Dictionary(uniqueKeysWithValues: people.map { ($0.id, $0) })
            dueReminders = pulled.compactMap { r in
                peopleById[r.personId].map { (person: $0, reminder: r) }
            }
        } catch {
            allReminders = []
            dueReminders = []
        }
    }

    /// Loads every note across every person once, then derives the
    /// "On this day" memories — past-year notes sharing today's calendar date.
    private func loadMemories() async {
        var pairs: [(person: Person, note: Note)] = []
        await withTaskGroup(of: (Person, [Note]).self) { group in
            for person in people {
                group.addTask {
                    let notes = (try? await SupabaseService.shared.fetchNotes(personId: person.id)) ?? []
                    return (person, notes)
                }
            }
            for await (person, notes) in group {
                pairs.append(contentsOf: notes.map { (person, $0) })
            }
        }
        memories = computeMemories(from: pairs)
    }

    private func computeMemories(from pairs: [(person: Person, note: Note)]) -> [Memory] {
        let cal = Calendar.current
        let today = Date()
        let todayMonth = cal.component(.month, from: today)
        let todayDay = cal.component(.day, from: today)
        let currentYear = cal.component(.year, from: today)

        let onThisDay = pairs.compactMap { pair -> Memory? in
            let m = cal.component(.month, from: pair.note.createdAt)
            let d = cal.component(.day, from: pair.note.createdAt)
            let y = cal.component(.year, from: pair.note.createdAt)
            guard m == todayMonth && d == todayDay && y < currentYear else { return nil }
            return Memory(person: pair.person, note: pair.note, yearsAgo: currentYear - y)
        }
        // Show the oldest memories first — older = more nostalgic — and cap
        // at 3 so the section doesn't dominate Home.
        return onThisDay
            .sorted { $0.yearsAgo > $1.yearsAgo }
            .prefix(3)
            .map { $0 }
    }

    /// Build a celebration card for every person whose birthday or anniversary
    /// is today. Pulls past-year notes, current key facts, and gifts given in
    /// the past year, then asks Claude (via cache when possible) for a
    /// retrospective summary.
    private func loadCelebrations() async {
        let today = Date()
        let cal = Calendar.current
        let todayMonth = cal.component(.month, from: today)
        let todayDay = cal.component(.day, from: today)
        let currentYear = cal.component(.year, from: today)
        let oneYearAgo = cal.date(byAdding: .year, value: -1, to: today) ?? today

        // Find dates that match today and are birthday/anniversary kind.
        let occasions = allDates
            .filter { $0.dateMonth == todayMonth && $0.dateDay == todayDay }
            .filter { $0.kind == .birthday || $0.kind == .anniversary }

        guard !occasions.isEmpty else { celebrations = []; return }

        let peopleById = Dictionary(uniqueKeysWithValues: people.map { ($0.id, $0) })

        var built: [OccasionCelebration] = []
        for date in occasions {
            guard let person = peopleById[date.personId] else { continue }

            // Past 12 months of notes, all current key facts, gifts given in the past year.
            let allNotes = (try? await SupabaseService.shared.fetchNotes(personId: person.id)) ?? []
            let yearNotes = allNotes.filter { $0.createdAt >= oneYearAgo }
            let facts = (try? await SupabaseService.shared.fetchKeyFacts(personId: person.id)) ?? []
            let allGifts = (try? await SupabaseService.shared.fetchGifts(personId: person.id)) ?? []
            let yearGifts = allGifts.filter { g in
                g.status == .given && (g.givenDate ?? .distantPast) >= oneYearAgo
            }

            let stats = OccasionCelebration.Stats(
                noteCount: yearNotes.count,
                giftCount: yearGifts.count,
                factCount: facts.count
            )

            // Use cached summary if available; otherwise ask Claude (when AI on).
            let cached = AnnualSummaryStore.cachedSummary(
                personId: person.id, year: currentYear, kind: date.kind
            )
            let headline: String
            let summary: String
            if let cached {
                headline = cached.headline
                summary = cached.summary
            } else if UserSettings.shared.aiFeaturesEnabled,
                      let result = try? await ClaudeService.shared.generateAnnualSummary(
                        personName: person.firstName,
                        occasionLabel: date.kind.rawValue,
                        notes: yearNotes,
                        keyFacts: facts.map(\.text),
                        gifts: yearGifts
                      ) {
                headline = result.headline
                summary = result.summary
                AnnualSummaryStore.setCachedSummary(
                    .init(headline: headline, summary: summary),
                    personId: person.id, year: currentYear, kind: date.kind
                )
            } else {
                // AI off OR call failed → still surface the card with a hand-written copy.
                headline = date.kind == .birthday
                    ? "It's \(person.firstName)'s day"
                    : "Celebrating \(person.firstName)"
                summary = "Take a moment to reach out and make their day."
            }

            built.append(OccasionCelebration(
                person: person, date: date,
                headline: headline, summary: summary, stats: stats
            ))
        }
        celebrations = built
    }

    /// Picks 3 people at random from the most overdue 8, so the same faces
    /// don't dominate every session, then asks Claude for a personalised nudge
    /// for each. Honours the dismissal cooldown shared with the People page.
    private func generateNudges() async {
        let defaultFreq = profile?.defaultContactFrequencyDays ?? 21
        let dismissed = DismissedSuggestionsStore.shared.activelyDismissed
        let pool = people
            .filter { $0.healthState(profileDefault: defaultFreq) == .red }
            .filter { !dismissed.contains($0.id) }
            .sorted { ($0.daysSinceLastInteraction() ?? .max) > ($1.daysSinceLastInteraction() ?? .max) }
            .prefix(8)
        let candidates = pool.shuffled().prefix(3)

        var generated: [Nudge] = []
        await withTaskGroup(of: Nudge?.self) { group in
            for person in candidates {
                group.addTask { [weak self] in
                    await self?.makeNudge(for: person)
                }
            }
            for await maybe in group {
                if let n = maybe { generated.append(n) }
            }
        }
        nudges = generated.sorted {
            ($0.person.daysSinceLastInteraction() ?? .max) > ($1.person.daysSinceLastInteraction() ?? .max)
        }
    }

    private func makeNudge(for person: Person) async -> Nudge? {
        do {
            let facts = try await SupabaseService.shared.fetchKeyFacts(personId: person.id)
            let notes = try await SupabaseService.shared.fetchNotes(personId: person.id)
            // No notes and no facts, OR user has AI features off → use the
            // hand-written fallback instead of calling Claude.
            if facts.isEmpty && notes.isEmpty || !UserSettings.shared.aiFeaturesEnabled {
                return Nudge(person: person, suggestion: NudgeCopy.coldFallback(person: person))
            }
            let suggestion = try await ClaudeService.shared.generateNudge(
                personName: person.firstName,
                keyFacts: facts.map { $0.text },
                lastNotes: Array(notes.prefix(5)),
                daysSince: person.daysSinceLastInteraction() ?? 0
            )
            return Nudge(person: person, suggestion: suggestion)
        } catch {
            return nil
        }
    }
}

/// Hand-written nudge copy for cases where we don't have enough data to
/// usefully prompt Claude.
enum NudgeCopy {
    static func coldFallback(person: Person) -> String {
        if person.daysSinceLastInteraction() == nil {
            return "You haven't logged anything for \(person.firstName) yet. A quick hello is a good place to start."
        }
        return "It's been a while since you connected with \(person.firstName). A quick hello goes a long way."
    }
}

extension HealthState {
    var sortKey: Int {
        switch self {
        case .red: return 0
        case .yellow: return 1
        case .green: return 2
        }
    }
}
