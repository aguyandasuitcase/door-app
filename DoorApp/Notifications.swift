import SwiftUI
import UserNotifications

/// Local notifications. These need no push entitlement and no developer account.
/// They fire while the app is running or kept alive in the background.
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private let callCategory = "DOOR_CALL"
    private let openAction = "OPEN_DOOR"

    func setUp() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let open = UNNotificationAction(
            identifier: openAction, title: "Open door",
            options: [.authenticationRequired])
        let category = UNNotificationCategory(
            identifier: callCategory, actions: [open],
            intentIdentifiers: [], options: [])
        center.setNotificationCategories([category])
    }

    func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func postRing(station: String, after seconds: TimeInterval = 1) {
        let content = UNMutableNotificationContent()
        content.title = "\(station) is calling"
        content.body = "Someone is at the door."
        content.sound = .default
        content.categoryIdentifier = callCategory
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger))
    }

    /// Returns an error text when the test could not be scheduled.
    func sendTest(station: String) async -> String? {
        let center = UNUserNotificationCenter.current()
        var status = await center.notificationSettings().authorizationStatus
        if status == .notDetermined {
            _ = await requestPermission()
            status = await center.notificationSettings().authorizationStatus
        }
        guard status == .authorized || status == .provisional || status == .ephemeral else {
            return "Notifications are not allowed. Turn them on for this app in iOS Settings."
        }
        postRing(station: station, after: 5)
        return nil
    }

    func postMissed(station: String) {
        let content = UNMutableNotificationContent()
        content.title = "Missed call"
        content.body = "\(station) rang and nobody answered."
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    // Show banners even while the app is open.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    // The "Open door" button on a notification. Face ID or passcode is required first.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        if response.actionIdentifier == openAction {
            _ = try? await UnlockDoorIntent().perform()
        }
    }
}
