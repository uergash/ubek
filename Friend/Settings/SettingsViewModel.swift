import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    var profile: UserProfile?
    var peopleCount: Int = 0
    var isLoading = false
    var errorMessage: String?

    nonisolated init() {}

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            profile = try await SupabaseService.shared.fetchProfile()
            if let profile { UserSettings.shared.setProfile(profile) }
            peopleCount = (try? await SupabaseService.shared.fetchPeople())?.count ?? 0
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateFrequency(days: Int) async {
        guard var p = profile else { return }
        p.defaultContactFrequencyDays = days
        do {
            try await SupabaseService.shared.updateProfile(p)
            profile = p
            UserSettings.shared.setProfile(p)
            AppEvents.profileChanged()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateQuietHours(start: Int, end: Int) async {
        guard var p = profile else { return }
        p.quietHoursStart = start
        p.quietHoursEnd = end
        do {
            try await SupabaseService.shared.updateProfile(p)
            profile = p
            UserSettings.shared.setProfile(p)
            AppEvents.profileChanged()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateAIEnabled(_ enabled: Bool) async {
        guard var p = profile else { return }
        p.aiFeaturesEnabled = enabled
        do {
            try await SupabaseService.shared.updateProfile(p)
            profile = p
            UserSettings.shared.setProfile(p)
            AppEvents.profileChanged()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateVoiceEnabled(_ enabled: Bool) async {
        guard var p = profile else { return }
        p.voiceEnabled = enabled
        do {
            try await SupabaseService.shared.updateProfile(p)
            profile = p
            UserSettings.shared.setProfile(p)
            AppEvents.profileChanged()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
