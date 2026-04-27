import SwiftUI

struct AvatarView: View {
    let initials: String
    let hue: Int
    let imageData: Data?
    var size: CGFloat = 44
    var ring: Bool = false

    init(person: Person, size: CGFloat = 44, ring: Bool = false) {
        self.initials = person.initials
        self.hue = person.avatarHue
        self.imageData = person.avatarImageDecoded()
        self.size = size
        self.ring = ring
    }

    init(initials: String, hue: Int, size: CGFloat = 44, ring: Bool = false) {
        self.initials = initials
        self.hue = hue
        self.imageData = nil
        self.size = size
        self.ring = ring
    }

    var body: some View {
        Group {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                gradientInitials
            }
        }
        .overlay(
            Circle()
                .stroke(Color.accent, lineWidth: ring ? 2 : 0)
                .padding(-3)
        )
    }

    private var gradientInitials: some View {
        let (top, bottom) = Color.avatarColors(hue: hue)
        return Text(initials)
            .font(.system(size: size * 0.36, weight: .semibold))
            .tracking(0.4)
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(
                    colors: [top, bottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Circle())
    }
}

#Preview {
    HStack(spacing: 12) {
        AvatarView(initials: "AR", hue: 22, size: 44)
        AvatarView(initials: "PS", hue: 320, size: 60)
        AvatarView(initials: "JT", hue: 150, size: 92)
    }
    .padding()
    .background(Color.appBackground)
}
