import Foundation
import Observation

@MainActor
@Observable
final class AddNoteViewModel {
    enum Mode {
        case compose       // text or pre-recording
        case recording     // live mic
        case extracting    // hitting Claude
        case facts         // showing extracted facts for confirmation
    }

    /// One or more people this note is being captured against. The first entry
    /// is treated as the "primary" for prompting purposes (Claude sees that
    /// person's existing facts, prompt copy uses their first name, etc.).
    let people: [Person]
    var mode: Mode = .compose
    var text: String = ""
    var interactionType: InteractionType = .coffee

    /// Facts surfaced from Claude. Each entry tracks whether the user kept it.
    struct CandidateFact: Identifiable {
        let id = UUID()
        var text: String
        var keep: Bool = true
    }
    var candidateFacts: [CandidateFact] = []

    /// Time-bound follow-ups surfaced from Claude — kept ones become Reminders
    /// against the primary person.
    struct CandidateFollowup: Identifiable {
        let id = UUID()
        var title: String
        var dueAt: Date
        var keep: Bool = true
    }
    var candidateFollowups: [CandidateFollowup] = []

    /// Gift ideas surfaced from Claude — kept ones land on the primary
    /// person's wishlist.
    struct CandidateGift: Identifiable {
        let id = UUID()
        var name: String
        var note: String
        var keep: Bool = true
    }
    var candidateGifts: [CandidateGift] = []

    /// One row id per person inserted, so confirmed key facts can be
    /// associated to each person's note row individually.
    var savedNoteIdsByPerson: [UUID: UUID] = [:]
    var errorMessage: String?
    var isWorking = false

    let speech = SpeechRecognizer()
    /// Existing facts for the *primary* person — passed to Claude for dedupe.
    private var existingFacts: [String] = []
    /// Existing gift names (wishlist + given) for the *primary* person —
    /// passed to Claude so it doesn't re-suggest things already tracked.
    private var existingGiftNames: [String] = []

    var person: Person { people[0] }
    var isMultiPerson: Bool { people.count > 1 }

    nonisolated init(person: Person) {
        self.people = [person]
    }

    nonisolated init(people: [Person]) {
        precondition(!people.isEmpty, "AddNoteViewModel requires at least one person")
        self.people = people
    }

    /// Pre-loads existing facts and gifts so Claude can dedupe.
    func prepare() async {
        async let factsTask = SupabaseService.shared.fetchKeyFacts(personId: person.id)
        async let giftsTask = SupabaseService.shared.fetchGifts(personId: person.id)
        existingFacts = ((try? await factsTask) ?? []).map(\.text)
        existingGiftNames = ((try? await giftsTask) ?? []).map(\.name)
    }

    // ─── Voice ────────────────────────────────────────────────────────────
    func startRecording() async {
        text = ""
        speech.transcript = ""
        mode = .recording
        await speech.start()
    }

    func stopRecording() {
        speech.stop()
        if !speech.transcript.isEmpty {
            text = speech.transcript
        }
        mode = .compose
    }

    // ─── Save + extract ───────────────────────────────────────────────────
    /// Persists the note (one row per attached person, sharing a note_group_id
    /// when there are multiple people) and asks Claude for new facts. Moves to
    /// `.facts` on success.
    func saveAndExtract() async {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }

        // Defensive teardown of the speech engine before any async work so the
        // audio session is released before we transition modes.
        speech.stop()

        isWorking = true
        mode = .extracting
        defer { isWorking = false }

        do {
            // Multi-person: stamp one shared id across rows. Single-person: nil.
            let groupId: UUID? = isMultiPerson ? UUID() : nil
            let createdAt = Date()

            var insertedByPerson: [UUID: UUID] = [:]
            for p in people {
                let note = Note(
                    id: UUID(),
                    personId: p.id,
                    interactionType: interactionType,
                    body: body,
                    createdAt: createdAt,
                    noteGroupId: groupId
                )
                let saved = try await SupabaseService.shared.createNote(note)
                insertedByPerson[p.id] = saved.id
                AppEvents.noteSaved(personId: p.id)
            }
            savedNoteIdsByPerson = insertedByPerson

            // Skip Claude calls when the user has AI off. The note itself is
            // already saved; we just don't surface candidates.
            if UserSettings.shared.aiFeaturesEnabled {
                async let factsTask = ClaudeService.shared.extractFacts(
                    noteBody: body,
                    personName: person.firstName,
                    existingFacts: existingFacts
                )
                async let followupsTask = ClaudeService.shared.extractFollowups(
                    noteBody: body,
                    personName: person.firstName,
                    today: Date()
                )
                async let giftsTask = ClaudeService.shared.extractGiftIdeas(
                    noteBody: body,
                    personName: person.firstName,
                    existingGifts: existingGiftNames
                )
                let facts = (try? await factsTask) ?? []
                let followups = (try? await followupsTask) ?? []
                let gifts = (try? await giftsTask) ?? []

                candidateFacts = facts.map { CandidateFact(text: $0) }
                candidateFollowups = followups.compactMap { f in
                    guard let due = ClaudeService.parseDueAt(f.dueAt) else { return nil }
                    return CandidateFollowup(title: f.title, dueAt: due)
                }
                candidateGifts = gifts.map { CandidateGift(name: $0.name, note: $0.note) }
            } else {
                candidateFacts = []
                candidateFollowups = []
                candidateGifts = []
            }
            mode = .facts
        } catch {
            errorMessage = error.localizedDescription
            mode = .compose
        }
    }

    /// Persists the kept facts and follow-up reminders (against the primary
    /// person only) and signals completion. Multi-person extraction is
    /// intentionally scoped to the primary person to avoid attributing
    /// facts/reminders about one attendee to others who happened to be at
    /// the same event.
    func confirmFacts() async {
        // Defensive: ensure speech engine is fully torn down before dismiss so
        // audio session / keyboard state doesn't leak into the parent UI.
        speech.stop()

        guard let noteId = savedNoteIdsByPerson[person.id] else {
            for p in people { AppEvents.noteSaved(personId: p.id) }
            return
        }
        let keptFacts = candidateFacts.filter(\.keep)
        for cf in keptFacts {
            let kf = KeyFact(
                id: UUID(),
                personId: person.id,
                text: cf.text,
                sourceNoteId: noteId,
                createdAt: Date()
            )
            _ = try? await SupabaseService.shared.createKeyFact(kf)
        }

        let keptFollowups = candidateFollowups.filter(\.keep)
        for cf in keptFollowups {
            let r = Reminder(
                id: UUID(),
                personId: person.id,
                title: cf.title,
                dueAt: cf.dueAt,
                completed: false,
                createdAt: Date()
            )
            _ = try? await SupabaseService.shared.createReminder(r)
        }

        let keptGifts = candidateGifts.filter(\.keep)
        for cg in keptGifts {
            let g = Gift(
                id: UUID(),
                personId: person.id,
                name: cg.name,
                note: cg.note.isEmpty ? nil : cg.note,
                status: .wishlist,
                occasion: nil,
                givenDate: nil,
                reaction: nil,
                createdAt: Date()
            )
            _ = try? await SupabaseService.shared.createGift(g)
        }

        for p in people { AppEvents.noteSaved(personId: p.id) }
    }

    func toggleFact(_ id: UUID) {
        guard let i = candidateFacts.firstIndex(where: { $0.id == id }) else { return }
        candidateFacts[i].keep.toggle()
    }

    func toggleFollowup(_ id: UUID) {
        guard let i = candidateFollowups.firstIndex(where: { $0.id == id }) else { return }
        candidateFollowups[i].keep.toggle()
    }

    func toggleGift(_ id: UUID) {
        guard let i = candidateGifts.firstIndex(where: { $0.id == id }) else { return }
        candidateGifts[i].keep.toggle()
    }
}
