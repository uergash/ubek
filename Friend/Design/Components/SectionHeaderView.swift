import SwiftUI

struct SectionHeaderView: View {
    let title: String
    var action: String? = nil
    var onActionTap: () -> Void = {}

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).sectionLabel()
            Spacer(minLength: 8)
            if let action {
                Button(action: onActionTap) {
                    Text(action)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 10)
    }
}

#Preview {
    VStack(alignment: .leading) {
        SectionHeaderView(title: "Upcoming")
        SectionHeaderView(title: "Reach out", action: "2 new")
    }
    .padding()
    .background(Color.appBackground)
}
