import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    let personId: UUID

    var person: Person?
    var notes: [Note] = []
    var keyFacts: [KeyFact] = []
    var gifts: [Gift] = []
    var dates: [ImportantDate] = []
    var reminders: [Reminder] = []
    var summary: String?
    var celebration: OccasionCelebration?
    /// For notes that were captured against multiple people, maps the note's id
    /// to the *other* attendees (not this profile's person).
    var coAttendeesByNoteId: [UUID: [Person]] = [:]

    var isLoading = false
    var isSummarizing = false
    var errorMessage: String?

    nonisolated init(personId: UUID) { self.personId = personId }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        // Fire all reads in parallel. Each await is wrapped so a failure in
        // one section (e.g. gifts decoding) doesn't cascade and leave other
        // sections empty.
        async let peopleTask = SupabaseService.shared.fetchPeople()
        async let notesTask = SupabaseService.shared.fetchNotes(personId: personId)
        async let factsTask = SupabaseService.shared.fetchKeyFacts(personId: personId)
        async let giftsTask = SupabaseService.shared.fetchGifts(personId: personId)
        async let datesTask = SupabaseService.shared.fetchDates(personId: personId)
        async let remindersTask = SupabaseService.shared.fetchReminders(personId: personId)

        var allPeople: [Person] = []
        if let people = try? await peopleTask {
            allPeople = people
            person = people.first(where: { $0.id == personId })
        }
        notes = (try? await notesTask) ?? []
        keyFacts = (try? await factsTask) ?? []
        gifts = (try? await giftsTask) ?? []
        dates = (try? await datesTask) ?? []
        reminders = (try? await remindersTask) ?? []

        await loadCoAttendees(allPeople: allPeople)
        await refreshSummary()
        await loadCelebration()
    }

    /// Builds the OccasionCelebration shown at the top of the Overview tab
    /// when today is the person's birthday or anniversary. Mirrors Home's
    /// logic; reuses the same cache.
    private func loadCelebration() async {
        guard let person else { celebration = nil; return }
        let cal = Calendar.current
        let today = Date()
        let m = cal.component(.month, from: today)
        let d = cal.component(.day, from: today)
        let currentYear = cal.component(.year, from: today)
        let oneYearAgo = cal.date(byAdding: .year, value: -1, to: today) ?? today

        guard let date = dates.first(where: {
            $0.dateMonth == m && $0.dateDay == d && ($0.kind == .birthday || $0.kind == .anniversary)
        }) else {
            celebration = nil
            return
        }

        let yearNotes = notes.filter { $0.createdAt >= oneYearAgo }
        let yearGifts = gifts.filter { g in
            g.status == .given && (g.givenDate ?? .distantPast) >= oneYearAgo
        }
        let stats = OccasionCelebration.Stats(
            noteCount: yearNotes.count,
            giftCount: yearGifts.count,
            factCount: keyFacts.count
        )

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
                    keyFacts: keyFacts.map(\.text),
                    gifts: yearGifts
                  ) {
            headline = result.headline
            summary = result.summary
            AnnualSummaryStore.setCachedSummary(
                .init(headline: headline, summary: summary),
                personId: person.id, year: currentYear, kind: date.kind
            )
        } else {
            headline = date.kind == .birthday ? "It's \(person.firstName)'s day" : "Celebrating \(person.firstName)"
            summary = "Take a moment to reach out and make their day."
        }

        celebration = OccasionCelebration(
            person: person, date: date,
            headline: headline, summary: summary, stats: stats
        )
    }

    /// Resolves the other attendees for any notes that share a note_group_id
    /// with another person's note. Skipped when no notes use grouping.
    private func loadCoAttendees(allPeople: [Person]) async {
        let groupIds = Array(Set(notes.compactMap(\.noteGroupId)))
        guard !groupIds.isEmpty else {
            coAttendeesByNoteId = [:]
            return
        }
        let peers = (try? await SupabaseService.shared.fetchNoteGroupPeers(groupIds: groupIds)) ?? []
        let peerIdsByGroup: [UUID: [UUID]] = Dictionary(grouping: peers, by: { $0.groupId })
            .mapValues { rows in rows.map(\.personId).filter { $0 != personId } }
        let peopleById = Dictionary(uniqueKeysWithValues: allPeople.map { ($0.id, $0) })

        var map: [UUID: [Person]] = [:]
        for note in notes {
            guard let gid = note.noteGroupId else { continue }
            let ids = peerIdsByGroup[gid] ?? []
            let peerPeople = ids.compactMap { peopleById[$0] }
            if !peerPeople.isEmpty { map[note.id] = peerPeople }
        }
        coAttendeesByNoteId = map
    }

    func refreshSummary() async {
        guard let person else { return }
        // Respect the user's AI-off preference. The Overview tab still
        // renders a static hint if a summary was never generated.
        guard UserSettings.shared.aiFeaturesEnabled else {
            if summary == nil { summary = "AI features are off — turn them on in Settings to see summaries." }
            return
        }
        isSummarizing = true
        defer { isSummarizing = false }
        do {
            summary = try await ClaudeService.shared.generateSummary(
                personName: person.firstName,
                notes: notes
            )
        } catch {
            if summary == nil { summary = "Add a note to start building a picture." }
        }
    }

    var wishlistGifts: [Gift] { gifts.filter { $0.status == .wishlist } }
    var giftedGifts: [Gift] { gifts.filter { $0.status == .given } }

    var nextUpcomingDate: ImportantDate? {
        dates.sorted(by: { $0.daysUntilNext < $1.daysUntilNext }).first
    }

    /// Persists edits to the underlying Person row and reflects the change
    /// locally so the profile header / health pill update without reloading.
    func updatePerson(
        name: String,
        relation: String,
        phone: String?,
        email: String?,
        avatarHue: Int,
        contactFrequencyDays: Int?
    ) async {
        guard var current = person else { return }
        current.name = name
        current.relation = relation
        current.phone = phone
        current.email = email
        current.avatarHue = avatarHue
        current.contactFrequencyDays = contactFrequencyDays
        do {
            try await SupabaseService.shared.updatePerson(current)
            person = current
            AppEvents.personChanged()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Hard-deletes the person. Cascades on the server delete every related
    /// row (notes, facts, gifts, dates, reminders). Returns true on success
    /// so the caller can pop the navigation stack.
    func deletePerson() async -> Bool {
        do {
            try await SupabaseService.shared.deletePerson(id: personId)
            AppEvents.personChanged()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func markGiftAsGiven(_ gift: Gift, occasion: String, reaction: GiftReaction) async {
        var updated = gift
        updated.status = .given
        updated.occasion = occasion
        updated.givenDate = Date()
        updated.reaction = reaction
        do {
            try await SupabaseService.shared.updateGift(updated)
            if let idx = gifts.firstIndex(where: { $0.id == gift.id }) {
                gifts[idx] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleDateReminder(_ date: ImportantDate) async {
        var updated = date
        updated.remind.toggle()
        do {
            try await SupabaseService.shared.updateDate(updated)
            if let idx = dates.firstIndex(where: { $0.id == date.id }) {
                dates[idx] = updated
            }
            // Refresh local schedule so toggling actually takes effect.
            if let person = person {
                await NotificationService.shared.scheduleDateReminders(for: person, dates: dates)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addGift(name: String, note: String?) async {
        do {
            let gift = Gift(
                id: UUID(),
                personId: personId,
                name: name,
                note: note,
                status: .wishlist,
                occasion: nil,
                givenDate: nil,
                reaction: nil,
                createdAt: Date()
            )
            let saved = try await SupabaseService.shared.createGift(gift)
            gifts.insert(saved, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // ─── Reminders ─────────────────────────────────────────────────────────
    func addReminder(title: String, dueAt: Date) async {
        do {
            let reminder = Reminder(
                id: UUID(),
                personId: personId,
                title: title,
                dueAt: dueAt,
                completed: false,
                createdAt: Date()
            )
            let saved = try await SupabaseService.shared.createReminder(reminder)
            reminders.append(saved)
            reminders.sort { $0.dueAt < $1.dueAt }
            if let person {
                await NotificationService.shared.scheduleReminders(for: person, reminders: reminders)
            }
            AppEvents.personChanged()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleReminderCompleted(_ reminder: Reminder) async {
        var updated = reminder
        updated.completed.toggle()
        do {
            try await SupabaseService.shared.updateReminder(updated)
            if let i = reminders.firstIndex(where: { $0.id == reminder.id }) {
                reminders[i] = updated
            }
            if let person {
                await NotificationService.shared.scheduleReminders(for: person, reminders: reminders)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteReminder(_ reminder: Reminder) async {
        do {
            try await SupabaseService.shared.deleteReminder(id: reminder.id)
            reminders.removeAll { $0.id == reminder.id }
            if let person {
                await NotificationService.shared.scheduleReminders(for: person, reminders: reminders)
            }
            AppEvents.personChanged()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var openReminders: [Reminder] { reminders.filter { !$0.completed } }
    var doneReminders: [Reminder] { reminders.filter { $0.completed } }

    func addDate(kind: DateKind, label: String, month: Int, day: Int) async {
        do {
            let date = ImportantDate(
                id: UUID(),
                personId: personId,
                kind: kind,
                label: label,
                dateMonth: month,
                dateDay: day,
                remind: true,
                remindDaysBefore: 1,
                createdAt: Date()
            )
            let saved = try await SupabaseService.shared.createDate(date)
            dates.append(saved)
            AppEvents.personChanged()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Persist edits to an existing date and refresh local state + reminders.
    func updateDate(_ date: ImportantDate, kind: DateKind, label: String, month: Int, day: Int) async {
        var updated = date
        updated.kind = kind
        updated.label = label
        updated.dateMonth = month
        updated.dateDay = day
        do {
            try await SupabaseService.shared.updateDate(updated)
            if let i = dates.firstIndex(where: { $0.id == date.id }) {
                dates[i] = updated
            }
            if let person {
                await NotificationService.shared.scheduleDateReminders(for: person, dates: dates)
            }
            AppEvents.personChanged()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteDate(_ date: ImportantDate) async {
        do {
            try await SupabaseService.shared.deleteDate(id: date.id)
            dates.removeAll { $0.id == date.id }
            if let person {
                await NotificationService.shared.scheduleDateReminders(for: person, dates: dates)
            }
            AppEvents.personChanged()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
