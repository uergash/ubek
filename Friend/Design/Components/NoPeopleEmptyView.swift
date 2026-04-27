import SwiftUI

/// Shown on Home and People when the user has zero people. Frames the
/// product's value briefly and offers the two productive next steps.
@MainActor
struct NoPeopleEmptyView: View {
    var onImportFromContacts: () -> Void
    var onAddManually: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.accentSoft)
                    .frame(width: 96, height: 96)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.accent)
            }
            .padding(.bottom, 22)

            Text("Start with your people")
                .font(.system(size: 22, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(Color.ink)
                .padding(.bottom, 8)

            Text("Friend helps you remember what matters about the people in your life. Bring a few in to get started.")
                .font(.system(size: 14.5))
                .foregroundStyle(Color.inkSoft)
                .lineSpacing(3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.bottom, 28)

            VStack(spacing: 10) {
                Button(action: onImportFromContacts) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Import from Contacts")
                    }
                }
                .buttonStyle(AccentPrimaryLargeButton())

                Button(action: onAddManually) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Add someone manually")
                    }
                }
                .buttonStyle(AccentSecondaryLargeButton())
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
        .padding(.bottom, 60)
    }
}
