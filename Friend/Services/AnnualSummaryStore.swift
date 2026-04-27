import Foundation

/// Cache + computation helpers for birthday/anniversary takeover cards.
/// The summary is generated once per person+year+occasion via Claude and
/// stored in UserDefaults so revisiting Home/Profile on the same day doesn't
/// re-burn API calls. The dismissed state is also per-day-keyed.
enum AnnualSummaryStore {
    private static let defaults = UserDefaults.standard

    // ─── Summary cache ────────────────────────────────────────────────────
    private static func summaryKey(personId: UUID, year: Int, kind: DateKind) -> String {
        "annualSummary.\(personId.uuidString).\(year).\(kind.rawValue)"
    }

    struct CachedSummary: Codable {
        let headline: String
        let summary: String
    }

    static func cachedSummary(personId: UUID, year: Int, kind: DateKind) -> CachedSummary? {
        let key = summaryKey(personId: personId, year: year, kind: kind)
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(CachedSummary.self, from: data)
        else { return nil }
        return decoded
    }

    static func setCachedSummary(_ value: CachedSummary, personId: UUID, year: Int, kind: DateKind) {
        let key = summaryKey(personId: personId, year: year, kind: kind)
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    // ─── Dismissed state ──────────────────────────────────────────────────
    private static func dismissedKey(personId: UUID, year: Int, kind: DateKind) -> String {
        "annualSummaryDismissed.\(personId.uuidString).\(year).\(kind.rawValue)"
    }

    static func isDismissed(personId: UUID, year: Int, kind: DateKind) -> Bool {
        defaults.bool(forKey: dismissedKey(personId: personId, year: year, kind: kind))
    }

    static func setDismissed(_ dismissed: Bool, personId: UUID, year: Int, kind: DateKind) {
        defaults.set(dismissed, forKey: dismissedKey(personId: personId, year: year, kind: kind))
    }
}

