import SwiftUI

/// Coordinates the four onboarding screens. State machine over an enum so
/// we don't have to deal with NavigationStack back gestures during onboarding.
struct OnboardingFlow: View {
    @Environment(AuthViewModel.self) private var auth

    enum Step: Hashable {
        case welcome
        case signUp
        case signIn
        case importContacts
        case notifications
    }

    @State private var step: Step

    init(start: Step = .welcome) { _step = State(initialValue: start) }

    var body: some View {
        ZStack {
            switch step {
            case .welcome:
                WelcomeView(
                    onGetStarted: { step = .signUp },
                    onSignIn: { step = .signIn }
                )
                .transition(.opacity)
            case .signUp:
                SignUpView(
                    onBack: { step = .welcome },
                    onSwitchToSignIn: { step = .signIn }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            case .signIn:
                SignInView(
                    onBack: { step = .welcome },
                    onSwitchToSignUp: { step = .signUp }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            case .importContacts:
                ImportContactsView(onFinish: { step = .notifications })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .notifications:
                NotificationsPermissionView(onFinish: {
                    // AppRootView re-evaluates and routes us to MainTabView.
                })
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: step)
        .onChange(of: auth.state) { _, newState in
            // After successful sign-up/sign-in, advance to the contacts step.
            if case .signedIn = newState, (step == .signUp || step == .signIn) {
                step = .importContacts
            }
        }
    }
}

extension AuthViewModel.State: Equatable {
    static func == (lhs: AuthViewModel.State, rhs: AuthViewModel.State) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading), (.signedOut, .signedOut): return true
        case let (.signedIn(a), .signedIn(b)): return a.id == b.id
        default: return false
        }
    }
}
