import SwiftUI

@MainActor
struct SignInView: View {
    @Environment(AuthViewModel.self) private var auth
    var onBack: () -> Void
    var onSwitchToSignUp: () -> Void

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        @Bindable var auth = auth
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                topBar
                content
                Spacer()
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.ink)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Welcome back")
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.56)

            Text("Sign in to pick up where you left off.")
                .font(.system(size: 15))
                .foregroundStyle(Color.inkSoft)
                .padding(.top, 10)
                .padding(.bottom, 28)

            field(label: "Email", text: $email, contentType: .emailAddress, keyboard: .emailAddress)
            secureField(label: "Password", text: $password)

            if let message = auth.errorMessage {
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.healthRed)
                    .padding(.top, 4)
            }

            Button(action: submit) {
                HStack {
                    if auth.isWorking { ProgressView().tint(Color.appBackground) }
                    Text(auth.isWorking ? "Signing in…" : "Sign in")
                }
            }
            .buttonStyle(AccentPrimaryLargeButton())
            .disabled(!canSubmit || auth.isWorking)
            .padding(.top, 18)
            .accessibilityIdentifier("signin_submit")

            HStack(spacing: 4) {
                Spacer()
                Text("Don't have an account?")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.muted)
                Button("Create one", action: onSwitchToSignUp)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accent)
                Spacer()
            }
            .padding(.top, 18)
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
    }

    private var canSubmit: Bool {
        email.contains("@") && password.count >= 6
    }

    private func submit() {
        Task { await auth.signIn(email: email, password: password) }
    }

    @ViewBuilder
    private func field(
        label: String,
        text: Binding<String>,
        contentType: UITextContentType? = nil,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).sectionLabel()
            TextField(label, text: text)
                .textContentType(contentType)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .font(.system(size: 15.5))
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.card)
                )
                .accessibilityIdentifier("signin_\(label.lowercased())")
        }
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private func secureField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).sectionLabel()
            SecureField(label, text: text)
                .textContentType(.password)
                .font(.system(size: 15.5))
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.card)
                )
                .accessibilityIdentifier("signin_\(label.lowercased())")
        }
        .padding(.bottom, 14)
    }
}
