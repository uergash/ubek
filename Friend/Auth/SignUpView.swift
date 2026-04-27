import SwiftUI

@MainActor
struct SignUpView: View {
    @Environment(AuthViewModel.self) private var auth
    var onBack: () -> Void
    var onSwitchToSignIn: () -> Void

    @State private var name = ""
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
            Text("Step 2 of 4")
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.96)
                .textCase(.uppercase)
                .foregroundStyle(Color.accent)
                .padding(.bottom, 10)

            Text("Create your account")
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.56)

            Text("So your people and notes follow you everywhere.")
                .font(.system(size: 15))
                .foregroundStyle(Color.inkSoft)
                .padding(.top, 10)
                .padding(.bottom, 28)

            field(label: "Name", text: $name, contentType: .name)
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
                    Text(auth.isWorking ? "Creating account…" : "Continue")
                }
            }
            .buttonStyle(AccentPrimaryLargeButton())
            .disabled(!canSubmit || auth.isWorking)
            .padding(.top, 18)

            HStack(spacing: 4) {
                Spacer()
                Text("Already have an account?")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.muted)
                Button("Sign in", action: onSwitchToSignIn)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accent)
                Spacer()
            }
            .padding(.top, 18)
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && email.contains("@")
            && password.count >= 6
    }

    private func submit() {
        Task { await auth.signUp(name: name, email: email, password: password) }
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
        }
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private func secureField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).sectionLabel()
            SecureField(label, text: text)
                .textContentType(.newPassword)
                .font(.system(size: 15.5))
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.card)
                )
        }
        .padding(.bottom, 14)
    }
}
