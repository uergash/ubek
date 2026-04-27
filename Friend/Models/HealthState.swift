import Foundation

enum HealthState {
    case green
    case yellow
    case red

    /// Computes the relationship-health state from days since last interaction
    /// against the user's desired contact frequency for this person.
    /// `lastInteractionDays == nil` means we've never logged anything → red.
    /// Mirrors the design's `healthFor()` helper:
    ///   ratio < 0.85 → green, < 1.25 → yellow, else red.
    static func compute(lastInteractionDays: Int?, frequencyDays: Int) -> HealthState {
        guard let days = lastInteractionDays else { return .red }
        guard frequencyDays > 0 else { return .green }
        let ratio = Double(days) / Double(frequencyDays)
        if ratio < 0.85 { return .green }
        if ratio < 1.25 { return .yellow }
        return .red
    }
}

extension Person {
    /// Days since last interaction, or `nil` if no interaction has ever been
    /// logged. Callers decide how to render the absence.
    func daysSinceLastInteraction(now: Date = Date()) -> Int? {
        guard let last = lastInteractionAt else { return nil }
        let calendar = Calendar.current
        let from = calendar.startOfDay(for: last)
        let to = calendar.startOfDay(for: now)
        return calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }

    /// Effective frequency for this person — falls back to the profile default.
    func effectiveFrequencyDays(profileDefault: Int) -> Int {
        contactFrequencyDays ?? profileDefault
    }

    func healthState(profileDefault: Int) -> HealthState {
        HealthState.compute(
            lastInteractionDays: daysSinceLastInteraction(),
            frequencyDays: effectiveFrequencyDays(profileDefault: profileDefault)
        )
    }
}
