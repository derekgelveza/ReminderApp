import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    private override init() { super.init() }

    func configureDelegate() {
        center.delegate = self
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        do {
            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .authorized { return true }
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func schedule(for task: TaskItem) async {
        guard await requestAuthorizationIfNeeded() else { return }
        let baseID = task.id.uuidString
        center.removePendingNotificationRequests(withIdentifiers: [baseID, "prep-\(baseID)"])

        let taskDate = Calendar.current.date(byAdding: .day, value: -task.reminderLeadDays, to: task.dueDate) ?? task.dueDate
        await addNotification(id: baseID, title: task.title, body: "Your reminder is due.", date: taskDate)

        guard !task.prepItems.isEmpty else { return }
        let prepDays = max(task.reminderLeadDays + 1, 7)
        let prepDate = Calendar.current.date(byAdding: .day, value: -prepDays, to: task.dueDate) ?? task.dueDate
        await addNotification(id: "prep-\(baseID)", title: "Prepare for \(task.title)", body: "Gather: \(task.prepItems.joined(separator: ", ")).", date: prepDate)
    }

    func cancel(for task: TaskItem) {
        center.removePendingNotificationRequests(withIdentifiers: [task.id.uuidString, "prep-\(task.id.uuidString)"])
    }

    private func addNotification(id: String, title: String, body: String, date: Date) async {
        guard date > .now else { return }
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let request = UNNotificationRequest(identifier: id, content: {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            return content
        }(), trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
        try? await center.add(request)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
