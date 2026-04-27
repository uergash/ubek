import Foundation
import Observation

/// Tracks whether the post-signup onboarding (contacts import + notifications)
/// has been completed for the current device.
@MainActor
@Observable
final class OnboardingState {
    static let shared = OnboardingState()

    private static let key = "friend.onboarding.completed"

    var isCompleted: Bool = UserDefaults.standard.bool(forKey: OnboardingState.key)

    nonisolated init() {}

    func markCompleted() {
        UserDefaults.standard.set(true, forKey: Self.key)
        isCompleted = true
    }

    func reset() {
        UserDefaults.standard.removeObject(forKey: Self.key)
        isCompleted = false
    }
}
