import Foundation
import Observation

/// Process-wide cache of the current user's `UserProfile` so view models can
/// check feature flags without each re-fetching. Refreshed on sign-in and
/// after edits via `SettingsViewModel`.
@MainActor
@Observable
final class UserSettings {
    static let shared = UserSettings()
    private init() {}

    private(set) var profile: UserProfile?

    var aiFeaturesEnabled: Bool { profile?.aiFeaturesEnabled ?? true }
    var voiceEnabled: Bool { profile?.voiceEnabled ?? true }

    /// Resolves the auth user, fetches their profile, and caches it.
    /// Safe to call repeatedly — each call refreshes the cache.
    func refresh() async {
        guard await SupabaseService.shared.resolveCurrentUserId() != nil else { return }
        profile = try? await SupabaseService.shared.fetchProfile()
    }

    /// Update the cached profile in-place after the Settings screen edits it,
    /// so other VMs pick up the new flag without a round-trip.
    func setProfile(_ profile: UserProfile) {
        self.profile = profile
    }
}
