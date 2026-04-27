import Foundation
import Supabase
import Observation

@MainActor
@Observable
final class AuthViewModel {
    enum State {
        case loading
        case signedOut
        case signedIn(User)
    }

    private(set) var state: State = .loading
    var errorMessage: String?
    var isWorking = false

    private let supabase = SupabaseService.shared
    private var sessionTask: Task<Void, Never>?

    nonisolated init() {
        Task { @MainActor in await self.bootstrap() }
    }

    // sessionTask lives the lifetime of the app; no explicit cancellation needed.

    /// Reads any persisted session and starts listening for changes.
    private func bootstrap() async {
        // Hydrate from disk if there's a saved session.
        if let session = try? await supabase.auth.session {
            state = .signedIn(session.user)
        } else {
            state = .signedOut
        }

        sessionTask = Task { [weak self] in
            guard let self else { return }
            for await (event, session) in supabase.auth.authStateChanges {
                await MainActor.run {
                    switch event {
                    case .signedIn, .tokenRefreshed, .userUpdated, .initialSession:
                        if let user = session?.user {
                            // Pre-warm currentUser so subsequent RLS queries succeed
                            // even before the caller awaits `auth.session`.
                            Task {
                                _ = await SupabaseService.shared.resolveCurrentUserId()
                                // Pre-load the profile so feature flags are
                                // available before any AI/voice gate fires.
                                await UserSettings.shared.refresh()
                            }
                            self.state = .signedIn(user)
                        } else {
                            self.state = .signedOut
                        }
                    case .signedOut, .userDeleted:
                        self.state = .signedOut
                    case .passwordRecovery, .mfaChallengeVerified:
                        break
                    }
                }
            }
        }
    }

    func signUp(name: String, email: String, password: String) async {
        await perform {
            try await self.supabase.auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(name)]
            )
        }
    }

    func signIn(email: String, password: String) async {
        await perform {
            try await self.supabase.auth.signIn(email: email, password: password)
        }
    }

    func signOut() async {
        // Try the supabase signOut, but force local state reset regardless of
        // whether the network call succeeds — corrupted/expired keychain
        // sessions can otherwise leave the user stuck.
        try? await supabase.auth.signOut()
        OnboardingState.shared.reset()
        state = .signedOut
        errorMessage = nil
    }

    /// Permanently deletes the signed-in user's account. The `delete-account`
    /// Edge Function uses the service role key to delete the auth.users row,
    /// which cascades to all owned data via FK constraints.
    func deleteAccount() async -> Bool {
        isWorking = true
        defer { isWorking = false }
        errorMessage = nil
        do {
            let _: EmptyResponse = try await SupabaseConfig.shared.functions.invoke("delete-account")
            try? await supabase.auth.signOut()
            OnboardingState.shared.reset()
            state = .signedOut
            return true
        } catch {
            errorMessage = humanReadable(error)
            return false
        }
    }

    private struct EmptyResponse: Decodable {}

    private func perform(_ action: @escaping () async throws -> Void) async {
        isWorking = true
        defer { isWorking = false }
        errorMessage = nil
        do {
            try await action()
        } catch {
            errorMessage = humanReadable(error)
        }
    }

    private func humanReadable(_ error: Error) -> String {
        let message = error.localizedDescription
        if message.contains("email") && message.contains("confirm") {
            return "Check your email to confirm your account, then come back to sign in."
        }
        if message.lowercased().contains("invalid login credentials") {
            return "That email and password don't match. Try again."
        }
        return message
    }
}
