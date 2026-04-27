import SwiftUI

@MainActor
struct NotificationsPermissionView: View {
    var onFinish: () -> Void

    @State private var isWorking = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 24)
                content
                Spacer()
                footer
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Step 4 of 4")
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.96)
                .textCase(.uppercase)
                .foregroundStyle(Color.accent)
                .padding(.bottom, 12)

            Text("We'll nudge you\nat the right moments")
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.56)
                .lineSpacing(2)
                .padding(.bottom, 12)

            Text("A reminder a day before your sister's birthday. A heads-up when it's been three weeks since you've heard from a close friend. Nothing more.")
                .font(.system(size: 15))
                .foregroundStyle(Color.inkSoft)
                .lineSpacing(3)
                .padding(.bottom, 24)

            VStack(alignment: .leading, spacing: 0) {
                row(icon: "birthday.cake.fill",
                    title: "Birthdays & important dates",
                    detail: "A day in advance, with what to say")
                row(icon: "bubble.left.fill",
                    title: "Reach-out nudges",
                    detail: "When it's been too long")
                row(icon: "sparkles",
                    title: "Annual recaps",
                    detail: "A year of memories before each birthday")
            }
        }
        .padding(.horizontal, 28)
    }

    private func row(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.accentSoft)
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.accentDeep)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .semibold))
                Text(detail).font(.system(size: 13.5)).foregroundStyle(Color.muted)
            }
            Spacer()
        }
        .padding(.vertical, 12)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Button(action: enable) {
                HStack {
                    if isWorking { ProgressView().tint(.white) }
                    Text(isWorking ? "Requesting…" : "Turn on notifications")
                        .font(.system(size: 15.5, weight: .semibold))
                }
                .foregroundStyle(Color.appBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.ink)
                )
            }
            .buttonStyle(.plain)
            .disabled(isWorking)

            Button("Maybe later", action: finish)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.muted)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 32)
    }

    private func enable() {
        isWorking = true
        Task {
            _ = await NotificationService.shared.requestPermission()
            isWorking = false
            finish()
        }
    }

    private func finish() {
        OnboardingState.shared.markCompleted()
        onFinish()
    }
}

#Preview {
    NotificationsPermissionView(onFinish: {})
}
