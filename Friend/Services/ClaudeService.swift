import Foundation
import Supabase

/// Wrapper around the three Supabase Edge Functions that proxy Claude.
/// All calls require an authenticated session — Supabase forwards the JWT.
@MainActor
final class ClaudeService {
    static let shared = ClaudeService()

    private let functions: FunctionsClient
    private init() { self.functions = SupabaseConfig.shared.functions }

    // ─── extract-facts ─────────────────────────────────────────────────────
    struct ExtractFactsRequest: Encodable {
        let noteBody: String
        let personName: String
        let existingFacts: [String]
    }
    struct ExtractFactsResponse: Decodable { let facts: [String] }

    func extractFacts(
        noteBody: String,
        personName: String,
        existingFacts: [String]
    ) async throws -> [String] {
        let response: ExtractFactsResponse = try await functions.invoke(
            "extract-facts",
            options: FunctionInvokeOptions(body: ExtractFactsRequest(
                noteBody: noteBody,
                personName: personName,
                existingFacts: existingFacts
            ))
        )
        return response.facts
    }

    // ─── extract-followups ─────────────────────────────────────────────────
    struct ExtractFollowupsRequest: Encodable {
        let noteBody: String
        let personName: String
        let today: String
    }
    /// Wire format — `dueAt` arrives as an ISO 8601 string, parsed by the
    /// caller. Avoids JSONDecoder date-strategy mismatches.
    struct FollowupCandidate: Decodable {
        let title: String
        let dueAt: String
    }
    struct ExtractFollowupsResponse: Decodable { let followups: [FollowupCandidate] }

    /// Surfaces time-bound events from a note as reminder candidates.
    /// Returns an empty array when nothing is worth following up on. Each
    /// candidate's dueAt is an ISO 8601 string — parse with `parseDueAt`
    /// before persisting.
    func extractFollowups(
        noteBody: String,
        personName: String,
        today: Date
    ) async throws -> [FollowupCandidate] {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        let response: ExtractFollowupsResponse = try await functions.invoke(
            "extract-followups",
            options: FunctionInvokeOptions(body: ExtractFollowupsRequest(
                noteBody: noteBody,
                personName: personName,
                today: dayFormatter.string(from: today)
            ))
        )
        return response.followups
    }

    /// Robust ISO 8601 parse — Claude sometimes returns full datetimes,
    /// sometimes date-only (yyyy-MM-dd). Try both; nil if neither parses.
    static func parseDueAt(_ s: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: s) { return d }
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: s) { return d }
        let dayOnly = DateFormatter()
        dayOnly.dateFormat = "yyyy-MM-dd"
        dayOnly.timeZone = TimeZone(identifier: "UTC")
        return dayOnly.date(from: s)
    }

    // ─── generate-summary ──────────────────────────────────────────────────
    struct SummaryNote: Encodable {
        let type: String
        let body: String
        let date: String
    }
    struct SummaryRequest: Encodable {
        let personName: String
        let notes: [SummaryNote]
    }
    struct SummaryResponse: Decodable { let summary: String }

    func generateSummary(personName: String, notes: [Note]) async throws -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let payloadNotes = notes.prefix(8).map { n in
            SummaryNote(
                type: n.interactionType.rawValue,
                body: n.body,
                date: formatter.string(from: n.createdAt)
            )
        }
        let response: SummaryResponse = try await functions.invoke(
            "generate-summary",
            options: FunctionInvokeOptions(body: SummaryRequest(
                personName: personName,
                notes: Array(payloadNotes)
            ))
        )
        return response.summary
    }

    // ─── generate-nudge ────────────────────────────────────────────────────
    struct NudgeRequest: Encodable {
        let personName: String
        let keyFacts: [String]
        let lastNotes: [SummaryNote]
        let daysSince: Int
    }
    struct NudgeResponse: Decodable { let suggestion: String }

    func generateNudge(
        personName: String,
        keyFacts: [String],
        lastNotes: [Note],
        daysSince: Int
    ) async throws -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let payloadNotes = lastNotes.prefix(5).map { n in
            SummaryNote(
                type: n.interactionType.rawValue,
                body: n.body,
                date: formatter.string(from: n.createdAt)
            )
        }
        let response: NudgeResponse = try await functions.invoke(
            "generate-nudge",
            options: FunctionInvokeOptions(body: NudgeRequest(
                personName: personName,
                keyFacts: keyFacts,
                lastNotes: Array(payloadNotes),
                daysSince: daysSince
            ))
        )
        return response.suggestion
    }

    // ─── generate-bond-line ────────────────────────────────────────────────
    struct BondLineRequest: Encodable {
        let personName: String
        let keyFacts: [String]
        let recentNotes: [SummaryNote]
    }
    struct BondLineResponse: Decodable { let line: String }

    // ─── generate-annual-summary ───────────────────────────────────────────
    struct AnnualGift: Encodable {
        let name: String
        let occasion: String?
        let reaction: String?
    }
    struct AnnualSummaryRequest: Encodable {
        let personName: String
        let occasionLabel: String
        let notes: [SummaryNote]
        let keyFacts: [String]
        let gifts: [AnnualGift]
    }
    struct AnnualSummaryResponse: Decodable {
        let headline: String
        let summary: String
    }

    /// Birthday / anniversary retrospective. Returns a celebratory headline
    /// + 4-5 sentence reflection on the past year with the person.
    func generateAnnualSummary(
        personName: String,
        occasionLabel: String,
        notes: [Note],
        keyFacts: [String],
        gifts: [Gift]
    ) async throws -> (headline: String, summary: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let payloadNotes = notes.prefix(20).map { n in
            SummaryNote(
                type: n.interactionType.rawValue,
                body: n.body,
                date: formatter.string(from: n.createdAt)
            )
        }
        let payloadGifts = gifts.map { g in
            AnnualGift(
                name: g.name,
                occasion: g.occasion,
                reaction: g.reaction?.rawValue
            )
        }
        let response: AnnualSummaryResponse = try await functions.invoke(
            "generate-annual-summary",
            options: FunctionInvokeOptions(body: AnnualSummaryRequest(
                personName: personName,
                occasionLabel: occasionLabel,
                notes: Array(payloadNotes),
                keyFacts: keyFacts,
                gifts: payloadGifts
            ))
        )
        return (response.headline, response.summary)
    }

    // ─── generate-year-review ──────────────────────────────────────────────
    struct YearReviewTopPerson: Encodable {
        let name: String
        let noteCount: Int
    }
    struct YearReviewNotableNote: Encodable {
        let personName: String
        let type: String
        let body: String
        let date: String
    }
    struct YearReviewGift: Encodable {
        let personName: String
        let name: String
        let reaction: String?
    }
    struct YearReviewRequest: Encodable {
        let year: Int
        let totalNotes: Int
        let totalGifts: Int
        let topPeople: [YearReviewTopPerson]
        let notableNotes: [YearReviewNotableNote]
        let giftsWithReactions: [YearReviewGift]
    }
    struct YearReviewResponse: Decodable {
        let headline: String
        let reflection: String
    }

    func generateYearReview(
        year: Int,
        totalNotes: Int,
        totalGifts: Int,
        topPeople: [(name: String, noteCount: Int)],
        notableNotes: [(personName: String, note: Note)],
        giftsWithReactions: [(personName: String, gift: Gift)]
    ) async throws -> (headline: String, reflection: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let payloadPeople = topPeople.map { YearReviewTopPerson(name: $0.name, noteCount: $0.noteCount) }
        let payloadNotes = notableNotes.map { entry in
            YearReviewNotableNote(
                personName: entry.personName,
                type: entry.note.interactionType.rawValue,
                body: entry.note.body,
                date: formatter.string(from: entry.note.createdAt)
            )
        }
        let payloadGifts = giftsWithReactions.map { entry in
            YearReviewGift(
                personName: entry.personName,
                name: entry.gift.name,
                reaction: entry.gift.reaction?.rawValue
            )
        }
        let response: YearReviewResponse = try await functions.invoke(
            "generate-year-review",
            options: FunctionInvokeOptions(body: YearReviewRequest(
                year: year,
                totalNotes: totalNotes,
                totalGifts: totalGifts,
                topPeople: payloadPeople,
                notableNotes: payloadNotes,
                giftsWithReactions: payloadGifts
            ))
        )
        return (response.headline, response.reflection)
    }

    /// One-sentence warm reminder of the user's bond with a person — used on
    /// the People page "Today's spotlight" card.
    func generateBondLine(
        personName: String,
        keyFacts: [String],
        recentNotes: [Note]
    ) async throws -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let payloadNotes = recentNotes.prefix(5).map { n in
            SummaryNote(
                type: n.interactionType.rawValue,
                body: n.body,
                date: formatter.string(from: n.createdAt)
            )
        }
        let response: BondLineResponse = try await functions.invoke(
            "generate-bond-line",
            options: FunctionInvokeOptions(body: BondLineRequest(
                personName: personName,
                keyFacts: keyFacts,
                recentNotes: Array(payloadNotes)
            ))
        )
        return response.line
    }
}
