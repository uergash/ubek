import SwiftUI

@main
struct FriendApp: App {
    init() {
        // Wire the notification router so taps deep-link into profiles.
        _ = NotificationRouter.shared
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .preferredColorScheme(.light)
        }
    }
}
