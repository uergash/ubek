import Foundation
import UserNotifications
import Observation

/// Bridge between UNUserNotificationCenter delegate callbacks and SwiftUI.
/// MainTabView observes `pendingPersonId` and pushes the profile when set.
@MainActor
@Observable
final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationRouter()
    var pendingPersonId: UUID?

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    /// Show the alert even when the app is in the foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// User tapped a notification — extract the person_id and surface it to the UI.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let personIdString = userInfo["person_id"] as? String,
           let personId = UUID(uuidString: personIdString) {
            Task { @MainActor in
                self.pendingPersonId = personId
            }
        }
        completionHandler()
    }
}
