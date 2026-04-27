import Foundation
import Observation

@MainActor
@Observable
final class PeopleViewModel {
    var people: [Person] = []
    var profile: UserProfile?
    var topContacts: [(person: Person, score: Int)] = []
    var suggestions: [Suggestion] = []
    var groups: [FriendGroup] = []
    var groupMemberCounts: [UUID: Int] = [:]
    var spotlight: Spotlight?
    var recentInteractions: [(person: Person, note: Note)] = []
    var isLoading = false
    /// Stays true once the first `load()` completes. Lets the view hold a single
    /// loading state until every section's data is ready, instead of revealing
    /// sections one by one as their async work finishes.
    var hasLoaded = false
    var errorMessage: String?

    /// "Person of the day" pick to remind the user of an existing relationship.
    /// `highlight` is either a key fact about the person or a gentle fallback
    /// when there's nothing on file yet.
    struct Spotlight {
        let person: Person
        let highlight: String
    }

    private let dismissedStore = DismissedSuggestionsStore.shared

    struct Suggestion: Identifiable {
        let person: Person
        let suggestion: String
        var id: UUID { person.id }
    }

    init() {
        applyCachedSnapshotIfAvailable()
    }

    @discardableResult
    private func applyCachedSnapshotIfAvailable() -> Bool {
        guard let snap = PeopleCache.shared.current() else { return false }
        people = snap.people
        profile = snap.profile
        topContacts = snap.topContacts
        suggestions = snap.suggestions
        groups = snap.groups
        groupMemberCounts = snap.groupMemberCounts
        spotlight = snap.spotlight
        recentInteractions = snap.recentInteractions
        hasLoaded = true
        return true
    }

    /// Called from `.task` on first appear. Cache hit → render immediately and
    /// skip the load. Cache miss → full load.
    func loadIfNeeded() async {
        if applyCachedSnapshotIfAvailable() { return }
        await load()
    }

    func load() async {
        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }
        guard await SupabaseService.shared.resolveCurrentUserId() != nil else {
            errorMessage = "Not signed in yet."
            return
        }

        do { people = try await SupabaseService.shared.fetchPeople() }
        catch is CancellationError {} catch { errorMessage = error.localizedDescription }

        do { profile = try await SupabaseService.shared.fetchProfile() }
        catch is CancellationError {} catch {}

        await rankTopContacts()
        await loadSuggestions()
        await loadGroups()
        await loadSpotlight()
        await loadRecentInteractions()
        saveSnapshot()
    }

    private func saveSnapshot() {
        PeopleCache.shared.store(.init(
            people: people,
            profile: profile,
            topContacts: topContacts,
            suggestions: suggestions,
            groups: groups,
            groupMemberCounts: groupMemberCounts,
            spotlight: spotlight,
            recentInteractions: recentInteractions,
            savedAt: Date()
        ))
    }

    /// Top 6 newest notes across all of the user's people, paired with their
    /// person for display.
    private func loadRecentInteractions() async {
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
        recentInteractions = pairs
            .sorted { $0.note.createdAt > $1.note.createdAt }
            .prefix(6)
            .map { $0 }
    }

    /// Called when a note is saved elsewhere — if the new note is for today's
    /// spotlighted person, the cached bond line is now stale (the note may
    /// reveal new context). Drop the cache and regenerate.
    func invalidateSpotlightIfMatches(personId: UUID) async {
        guard let current = spotlight, current.person.id == personId else { return }
        let dayOffset = Int(Date().timeIntervalSinceReferenceDate / 86_400)
        let cacheKey = "spotlight.bondLine.\(personId.uuidString).\(dayOffset)"
        UserDefaults.standard.removeObject(forKey: cacheKey)
        await loadSpotlight()
    }

    /// Picks one person to spotlight today. Same person across the whole day
    /// (deterministic by date), rotates to a new person each day.
    private func loadSpotlight() async {
        guard !people.isEmpty else { spotlight = nil; return }
        let pool = people.sorted { $0.id.uuidString < $1.id.uuidString }
        let dayOffset = Int(Date().timeIntervalSinceReferenceDate / 86_400)
        let person = pool[dayOffset % pool.count]

        // Use a per-day cache key so the Claude-generated line is stable
        // across pull-to-refresh and only regenerates when the day changes.
        let cacheKey = "spotlight.bondLine.\(person.id.uuidString).\(dayOffset)"
        if let cached = UserDefaults.standard.string(forKey: cacheKey), !cached.isEmpty {
            spotlight = Spotlight(person: person, highlight: cached)
            return
        }

        // Show a fallback immediately so the UI isn't empty while Claude runs.
        let facts = (try? await SupabaseService.shared.fetchKeyFacts(personId: person.id)) ?? []
        let notes = (try? await SupabaseService.shared.fetchNotes(personId: person.id)) ?? []
        let interim = facts.isEmpty
            ? "Take a moment today to think about \(person.firstName)."
            : facts[dayOffset % facts.count].text
        spotlight = Spotlight(person: person, highlight: interim)

        // Try to upgrade to a Claude-generated bond line. Skip when the user
        // has AI features off; failures keep the fallback in place.
        guard UserSettings.shared.aiFeaturesEnabled else { return }
        if let line = try? await ClaudeService.shared.generateBondLine(
            personName: person.firstName,
            keyFacts: facts.map(\.text),
            recentNotes: notes
        ), !line.isEmpty {
            UserDefaults.standard.set(line, forKey: cacheKey)
            spotlight = Spotlight(person: person, highlight: line)
        }
    }

    private func loadGroups() async {
        do {
            groups = try await SupabaseService.shared.fetchGroups()
        } catch {
            groups = []
        }
        var counts: [UUID: Int] = [:]
        await withTaskGroup(of: (UUID, Int).self) { taskGroup in
            for g in groups {
                taskGroup.addTask {
                    let members = (try? await SupabaseService.shared.fetchGroupMembers(groupId: g.id)) ?? []
                    return (g.id, members.count)
                }
            }
            for await (gid, c) in taskGroup { counts[gid] = c }
        }
        groupMemberCounts = counts
    }

    /// Persists a new group and its initial members. Refreshes local state on success.
    func createGroup(name: String, memberIds: Set<UUID>) async {
        guard let uid = await SupabaseService.shared.resolveCurrentUserId() else { return }
        let group = FriendGroup(id: UUID(), userId: uid, name: name, createdAt: Date())
        do {
            let saved = try await SupabaseService.shared.createGroup(group)
            for pid in memberIds {
                try? await SupabaseService.shared.addGroupMember(
                    GroupMember(groupId: saved.id, personId: pid)
                )
            }
            groups.append(saved)
            groups.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            groupMemberCounts[saved.id] = memberIds.count
            AppEvents.groupChanged()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Engagement score = (notes_in_last_90_days * 2) + (90 - daysSinceLastInteraction).
    /// Negative recency contribution is clamped to 0 so people never seen don't go below zero.
    private func rankTopContacts() async {
        var scored: [(Person, Int)] = []
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        await withTaskGroup(of: (Person, Int).self) { group in
            for person in people {
                group.addTask {
                    let notes = (try? await SupabaseService.shared.fetchNotes(personId: person.id)) ?? []
                    let recentCount = notes.filter { $0.createdAt >= cutoff }.count
                    let days = person.daysSinceLastInteraction() ?? 90
                    let recencyBonus = max(0, 90 - days)
                    let score = recentCount * 2 + recencyBonus
                    return (person, score)
                }
            }
            for await (person, score) in group {
                if score > 0 { scored.append((person, score)) }
            }
        }
        topContacts = scored
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { $0 }
    }

    /// Overdue people (red health), AI-suggested copy per person, filtered
    /// against the dismissal store.
    private func loadSuggestions() async {
        let defaultFreq = profile?.defaultContactFrequencyDays ?? 21
        let dismissed = dismissedStore.activelyDismissed
        let pool = people
            .filter { $0.healthState(profileDefault: defaultFreq) == .red }
            .filter { !dismissed.contains($0.id) }
            .sorted { ($0.daysSinceLastInteraction() ?? .max) > ($1.daysSinceLastInteraction() ?? .max) }
            .prefix(8)
        let candidates = pool.shuffled().prefix(3)

        var generated: [Suggestion] = []
        await withTaskGroup(of: Suggestion?.self) { group in
            for person in candidates {
                group.addTask {
                    do {
                        let facts = try await SupabaseService.shared.fetchKeyFacts(personId: person.id)
                        let notes = try await SupabaseService.shared.fetchNotes(personId: person.id)
                        let aiOn = await UserSettings.shared.aiFeaturesEnabled
                        if facts.isEmpty && notes.isEmpty || !aiOn {
                            return Suggestion(person: person, suggestion: NudgeCopy.coldFallback(person: person))
                        }
                        let suggestion = try await ClaudeService.shared.generateNudge(
                            personName: person.firstName,
                            keyFacts: facts.map { $0.text },
                            lastNotes: Array(notes.prefix(5)),
                            daysSince: person.daysSinceLastInteraction() ?? 0
                        )
                        return Suggestion(person: person, suggestion: suggestion)
                    } catch {
                        return nil
                    }
                }
            }
            for await maybe in group {
                if let s = maybe { generated.append(s) }
            }
        }
        suggestions = generated.sorted {
            ($0.person.daysSinceLastInteraction() ?? .max) > ($1.person.daysSinceLastInteraction() ?? .max)
        }
    }

    func dismissSuggestion(_ personId: UUID) {
        dismissedStore.dismiss(personId: personId)
        suggestions.removeAll { $0.person.id == personId }
    }
}
