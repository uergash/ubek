import Foundation
import Supabase

/// Thin wrapper around the Supabase client. One method per CRUD operation.
/// Throws so callers can decide how to surface errors.
@MainActor
final class SupabaseService {
    static let shared = SupabaseService()

    private let client: SupabaseClient
    private init() { self.client = SupabaseConfig.shared }

    // ─── Auth ──────────────────────────────────────────────────────────────
    var auth: AuthClient { client.auth }
    var currentUserId: UUID? { client.auth.currentUser?.id }

    /// Forces the auth client to resolve the persisted session if it hasn't
    /// already, then returns the user id. Use this before any RLS-gated query
    /// to avoid race conditions where `currentUser` is nil even though a
    /// session exists on disk.
    func resolveCurrentUserId() async -> UUID? {
        if let id = client.auth.currentUser?.id { return id }
        do {
            let session = try await client.auth.session
            return session.user.id
        } catch {
            return nil
        }
    }

    // ─── Profile ───────────────────────────────────────────────────────────
    func fetchProfile() async throws -> UserProfile? {
        guard let uid = await resolveCurrentUserId() else { return nil }
        return try await client.from("profiles")
            .select()
            .eq("id", value: uid)
            .single()
            .execute()
            .value
    }

    func updateProfile(_ profile: UserProfile) async throws {
        try await client.from("profiles")
            .update(profile)
            .eq("id", value: profile.id)
            .execute()
    }

    // ─── People ────────────────────────────────────────────────────────────
    func fetchPeople() async throws -> [Person] {
        try await client.from("people")
            .select()
            .order("name")
            .execute()
            .value
    }

    func createPerson(_ person: Person) async throws -> Person {
        try await client.from("people")
            .insert(person)
            .select()
            .single()
            .execute()
            .value
    }

    func updatePerson(_ person: Person) async throws {
        try await client.from("people")
            .update(person)
            .eq("id", value: person.id)
            .execute()
    }

    func deletePerson(id: UUID) async throws {
        try await client.from("people").delete().eq("id", value: id).execute()
    }

    // ─── Notes ─────────────────────────────────────────────────────────────
    func fetchNotes(personId: UUID) async throws -> [Note] {
        try await client.from("notes")
            .select()
            .eq("person_id", value: personId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func createNote(_ note: Note) async throws -> Note {
        try await client.from("notes")
            .insert(note)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteNote(id: UUID) async throws {
        try await client.from("notes").delete().eq("id", value: id).execute()
    }

    /// Returns rows from `notes` matching any of `groupIds`, projected to the
    /// (note_group_id, person_id) pairs used to resolve co-attendees.
    private struct GroupPeerRow: Decodable {
        let noteGroupId: UUID
        let personId: UUID
        enum CodingKeys: String, CodingKey {
            case noteGroupId = "note_group_id"
            case personId = "person_id"
        }
    }

    func fetchNoteGroupPeers(groupIds: [UUID]) async throws -> [(groupId: UUID, personId: UUID)] {
        guard !groupIds.isEmpty else { return [] }
        let rows: [GroupPeerRow] = try await client.from("notes")
            .select("note_group_id, person_id")
            .in("note_group_id", values: groupIds)
            .execute()
            .value
        return rows.map { ($0.noteGroupId, $0.personId) }
    }

    // ─── Key Facts ─────────────────────────────────────────────────────────
    func fetchKeyFacts(personId: UUID) async throws -> [KeyFact] {
        try await client.from("key_facts")
            .select()
            .eq("person_id", value: personId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func createKeyFact(_ fact: KeyFact) async throws -> KeyFact {
        try await client.from("key_facts")
            .insert(fact)
            .select()
            .single()
            .execute()
            .value
    }

    func updateKeyFact(_ fact: KeyFact) async throws {
        try await client.from("key_facts")
            .update(fact)
            .eq("id", value: fact.id)
            .execute()
    }

    func deleteKeyFact(id: UUID) async throws {
        try await client.from("key_facts").delete().eq("id", value: id).execute()
    }

    // ─── Gifts ─────────────────────────────────────────────────────────────
    func fetchGifts(personId: UUID) async throws -> [Gift] {
        try await client.from("gifts")
            .select()
            .eq("person_id", value: personId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func createGift(_ gift: Gift) async throws -> Gift {
        try await client.from("gifts")
            .insert(gift)
            .select()
            .single()
            .execute()
            .value
    }

    func updateGift(_ gift: Gift) async throws {
        try await client.from("gifts")
            .update(gift)
            .eq("id", value: gift.id)
            .execute()
    }

    func deleteGift(id: UUID) async throws {
        try await client.from("gifts").delete().eq("id", value: id).execute()
    }

    // ─── Important Dates ───────────────────────────────────────────────────
    func fetchDates(personId: UUID) async throws -> [ImportantDate] {
        try await client.from("important_dates")
            .select()
            .eq("person_id", value: personId)
            .execute()
            .value
    }

    func createDate(_ date: ImportantDate) async throws -> ImportantDate {
        try await client.from("important_dates")
            .insert(date)
            .select()
            .single()
            .execute()
            .value
    }

    func updateDate(_ date: ImportantDate) async throws {
        try await client.from("important_dates")
            .update(date)
            .eq("id", value: date.id)
            .execute()
    }

    func deleteDate(id: UUID) async throws {
        try await client.from("important_dates").delete().eq("id", value: id).execute()
    }

    // ─── Reminders ─────────────────────────────────────────────────────────
    func fetchReminders(personId: UUID) async throws -> [Reminder] {
        try await client.from("reminders")
            .select()
            .eq("person_id", value: personId)
            .order("due_at", ascending: true)
            .execute()
            .value
    }

    /// Pulls every uncompleted reminder for the current user, due within
    /// `daysAhead` days. Used by Home to surface upcoming reminders.
    func fetchUpcomingReminders(daysAhead: Int = 14) async throws -> [Reminder] {
        let cutoff = Calendar.current.date(byAdding: .day, value: daysAhead, to: Date()) ?? Date()
        return try await client.from("reminders")
            .select()
            .eq("completed", value: false)
            .lte("due_at", value: cutoff)
            .order("due_at", ascending: true)
            .execute()
            .value
    }

    func createReminder(_ reminder: Reminder) async throws -> Reminder {
        try await client.from("reminders")
            .insert(reminder)
            .select()
            .single()
            .execute()
            .value
    }

    func updateReminder(_ reminder: Reminder) async throws {
        try await client.from("reminders")
            .update(reminder)
            .eq("id", value: reminder.id)
            .execute()
    }

    func deleteReminder(id: UUID) async throws {
        try await client.from("reminders").delete().eq("id", value: id).execute()
    }

    // ─── Groups ────────────────────────────────────────────────────────────
    func fetchGroups() async throws -> [FriendGroup] {
        try await client.from("groups").select().order("name").execute().value
    }

    func createGroup(_ group: FriendGroup) async throws -> FriendGroup {
        try await client.from("groups")
            .insert(group)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteGroup(id: UUID) async throws {
        try await client.from("groups").delete().eq("id", value: id).execute()
    }

    func fetchGroupMembers(groupId: UUID) async throws -> [GroupMember] {
        try await client.from("group_members")
            .select()
            .eq("group_id", value: groupId)
            .execute()
            .value
    }

    func addGroupMember(_ member: GroupMember) async throws {
        try await client.from("group_members").insert(member).execute()
    }

    func removeGroupMember(_ member: GroupMember) async throws {
        try await client.from("group_members")
            .delete()
            .eq("group_id", value: member.groupId)
            .eq("person_id", value: member.personId)
            .execute()
    }

    // ─── Stories ───────────────────────────────────────────────────────────
    /// Fetches all stories for the current user (RLS-scoped) ordered newest
    /// first. Archived/active filtering is done client-side — story counts
    /// are bounded to a single user's hand-jotted history.
    func fetchAllStories() async throws -> [Story] {
        try await client.from("stories")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func createStory(_ story: Story) async throws -> Story {
        try await client.from("stories")
            .insert(story)
            .select()
            .single()
            .execute()
            .value
    }

    func archiveStory(id: UUID) async throws {
        struct ArchivePatch: Encodable { let archived_at: Date }
        try await client.from("stories")
            .update(ArchivePatch(archived_at: Date()))
            .eq("id", value: id)
            .execute()
    }

    func unarchiveStory(id: UUID) async throws {
        struct UnarchivePatch: Encodable { let archived_at: Date? }
        try await client.from("stories")
            .update(UnarchivePatch(archived_at: nil))
            .eq("id", value: id)
            .execute()
    }

    func deleteStory(id: UUID) async throws {
        try await client.from("stories").delete().eq("id", value: id).execute()
    }

    // ─── Self facts ────────────────────────────────────────────────────────
    func fetchSelfFacts() async throws -> [SelfFact] {
        try await client.from("self_facts")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func createSelfFact(_ fact: SelfFact) async throws -> SelfFact {
        try await client.from("self_facts")
            .insert(fact)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteSelfFact(id: UUID) async throws {
        try await client.from("self_facts").delete().eq("id", value: id).execute()
    }

    // ─── AI reports ────────────────────────────────────────────────────────
    enum AIReportKind: String { case summary, nudge, fact }

    func reportAIContent(
        kind: AIReportKind,
        content: String,
        reason: String?,
        personId: UUID?
    ) async throws {
        guard let userId = currentUserId else { return }
        struct Row: Encodable {
            let user_id: UUID
            let kind: String
            let content: String
            let reason: String?
            let person_id: UUID?
        }
        try await client.from("ai_reports").insert(Row(
            user_id: userId,
            kind: kind.rawValue,
            content: content,
            reason: reason,
            person_id: personId
        )).execute()
    }
}
