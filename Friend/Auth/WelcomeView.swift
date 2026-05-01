import SwiftUI

struct WelcomeView: View {
    var onGetStarted: () -> Void
    var onSignIn: () -> Void

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                logo
                Text("Bowline")
                    .font(.fraunces(size: 40))
                    .tracking(-0.2)
                    .foregroundStyle(Color.ink)
                    .padding(.top, 28)
                Text("Stay close to the people who matter.")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.inkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.top, 14)
                    .padding(.horizontal, 48)
                Spacer()
                buttons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                aiDisclosure
                    .padding(.horizontal, 32)
                    .padding(.bottom, 30)
            }
        }
    }

    private var logo: some View {
        Image("AppLogo")
            .resizable()
            .interpolation(.high)
            .frame(width: 88, height: 88)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.accent.opacity(0.35), radius: 24, x: 0, y: 12)
    }

    private var aiDisclosure: some View {
        Text("Bowline uses generative AI (Anthropic Claude) to summarize your notes and suggest reach-outs. AI output may be inaccurate — you can always edit or remove it.")
            .font(.system(size: 11))
            .foregroundStyle(Color.muted)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            Button("Get started", action: onGetStarted)
                .buttonStyle(AccentPrimaryLargeButton())

            Button(action: onSignIn) {
                Text("I have an account")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.muted)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
    }
}

#Preview {
    WelcomeView(onGetStarted: {}, onSignIn: {})
}
