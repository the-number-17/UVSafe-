import Foundation
import UserNotifications

/// Handles requesting notification permission and scheduling sunburn reminder alerts.
@MainActor
final class NotificationManager: ObservableObject {

    static let shared = NotificationManager()

    @Published var authStatus: UNAuthorizationStatus = .notDetermined
    @Published var pendingReminder: Date? = nil  // fire date of any active reminder

    private let center = UNUserNotificationCenter.current()
    private let reminderID = "com.uvsafe.sunburnReminder"

    private init() {
        Task { await refreshStatus() }
    }

    // MARK: - Permission

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshStatus()
            return granted
        } catch {
            return false
        }
    }

    func refreshStatus() async {
        let settings = await center.notificationSettings()
        authStatus = settings.authorizationStatus
    }

    // MARK: - Schedule / Cancel

    /// Schedule a notification to fire `seconds` from now.
    /// Cancels any previously pending reminder first.
    func scheduleReminder(burnSeconds: Double, skinTypeName: String, spf: Double) async {
        guard burnSeconds.isFinite, burnSeconds > 0, burnSeconds < 86_400 else { return }

        // Ensure permission
        if authStatus != .authorized {
            guard await requestAuthorization() else { return }
        }

        cancel()

        let content = UNMutableNotificationContent()
        content.title = "☀️ Time to seek shade!"
        let spfText = spf >= 1 ? " (SPF \(Int(spf)) applied)" : ""
        content.body  = "You've reached your estimated sunburn threshold for \(skinTypeName)\(spfText). Head indoors or reapply sunscreen now."
        content.sound = .defaultCritical

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: burnSeconds, repeats: false)
        let request  = UNNotificationRequest(identifier: reminderID, content: content, trigger: trigger)

        do {
            try await center.add(request)
            pendingReminder = Date().addingTimeInterval(burnSeconds)
        } catch {
            pendingReminder = nil
        }
    }

    /// Cancel the active reminder.
    func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [reminderID])
        pendingReminder = nil
    }
}
