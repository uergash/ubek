import SwiftUI

@MainActor
struct AppRootView: View {
    @State private var auth = AuthViewModel()
    private let onboarding = OnboardingState.shared
    /// While we check whether the signed-in user already has account data
    /// (in which case we skip onboarding), keep the loading screen up so
    /// the user doesn't see Step 3 of 4 flash before being routed to Home.
    @State private var isReconcilingAccountState = false

    var body: some View {
        Group {
            switch auth.state {
            case .loading:
                LoadingScreen()
            case .signedOut:
                OnboardingFlow().id("flow-signedOut")
            case .signedIn:
                if isReconcilingAccountState {
                    LoadingScreen()
                } else if onboarding.isCompleted {
                    MainTabView()
                } else {
                    // Account exists but contacts/notifications haven't been done yet
                    OnboardingFlow(start: .importContacts).id("flow-postSignup")
                }
            }
        }
        .environment(auth)
        .animation(.easeInOut(duration: 0.2), value: stateKey)
        .task(id: isSignedIn) {
            await reconcileOnboardingFromAccount()
        }
    }

    /// If the user is signed in but the local "onboarding completed" flag is
    /// false (e.g. fresh install on a second device), check whether their
    /// account already has people. If yes, mark onboarding complete so we
    /// skip Step 3 of 4 and route straight to MainTabView.
    private func reconcileOnboardingFromAccount() async {
        guard isSignedIn, !onboarding.isCompleted else { return }
        isReconcilingAccountState = true
        defer { isReconcilingAccountState = false }
        let people = (try? await SupabaseService.shared.fetchPeople()) ?? []
        if !people.isEmpty {
            onboarding.markCompleted()
        }
    }

    private var isSignedIn: Bool {
        if case .signedIn = auth.state { return true }
        return false
    }

    /// A simple key derived from `state` so SwiftUI animates the transition.
    private var stateKey: String {
        switch auth.state {
        case .loading: return "loading"
        case .signedOut: return "signedOut"
        case .signedIn: return onboarding.isCompleted ? "main" : "onboarding"
        }
    }
}

private struct LoadingScreen: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ProgressView().tint(Color.muted)
        }
    }
}
