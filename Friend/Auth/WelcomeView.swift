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
                Text("Friend")
                    .font(.system(size: 36, weight: .bold))
                    .tracking(-0.9)
                    .padding(.top, 28)
                Text("Remember what matters to the people you love.")
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
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(
                    colors: [
                        Color(hue: 0.10, saturation: 0.30, brightness: 0.90),
                        Color.accent
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 88, height: 88)
                .shadow(color: Color.accent.opacity(0.35), radius: 24, x: 0, y: 12)
            Image(systemName: "heart.fill")
                .font(.system(size: 38, weight: .regular))
                .foregroundStyle(.white)
        }
    }

    private var aiDisclosure: some View {
        Text("Friend uses generative AI (Anthropic Claude) to summarize your notes and suggest reach-outs. AI output may be inaccurate — you can always edit or remove it.")
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
