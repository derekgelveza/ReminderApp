import Foundation
import UserNotifications
import SwiftData

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    private override init() { super.init() }

    func configureDelegate() { center.delegate = self }

    func requestAuthorizationIfNeeded() async -> Bool {
        do {
            let settings = await center.notificationSettings()
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral: return true
            case .denied: return false
            case .notDetermined: return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            @unknown default: return false
            }
        } catch { return false }
    }

    func schedule(plan: SmartReminderPlan) async throws -> Bool {
        let baseID = plan.taskID.uuidString
        center.removePendingNotificationRequests(withIdentifiers: [baseID, "due-\(baseID)", "prep-\(baseID)"])
        guard await requestAuthorizationIfNeeded() else { return false }
        let reminderDate = Calendar.current.date(byAdding: .day, value: -plan.leadDays, to: plan.dueDate) ?? plan.dueDate
        do {
            if plan.leadDays > 0 { try await addNotification(id: baseID, title: "Heads up", body: plan.message, date: reminderDate) }
            try await addNotification(id: "due-\(baseID)", title: plan.taskTitle, body: "It’s time for this task.", date: plan.dueDate)
            if let prepLeadDays = plan.prepLeadDays, let prepMessage = plan.prepMessage {
                let prepDate = Calendar.current.date(byAdding: .day, value: -prepLeadDays, to: plan.dueDate) ?? plan.dueDate
                try await addNotification(id: "prep-\(baseID)", title: "A little prep for \(plan.taskTitle)", body: prepMessage, date: prepDate)
            }
        } catch {
            cancel(id: plan.taskID)
            throw error
        }
        return true
    }

    func cancel(for task: TaskItem) { cancel(id: task.id) }
    func cancel(id: UUID) {
        let baseID = id.uuidString
        center.removePendingNotificationRequests(withIdentifiers: [baseID, "due-\(baseID)", "prep-\(baseID)"])
    }

    private func addNotification(id: String, title: String, body: String, date: Date) async throws {
        guard date > .now else { return }
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: id, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
        try await center.add(request)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions { [.banner, .sound] }
}

final class ReminderCoordinator {
    static let shared = ReminderCoordinator()
    private let smartReminderService: SmartReminderService

    init(smartReminderService: SmartReminderService = MockSmartReminderService()) {
        self.smartReminderService = smartReminderService
    }

    func preview(for snapshot: TaskSnapshot) async throws -> SmartReminderPlan {
        try await smartReminderService.makePlan(for: snapshot)
    }

    func schedule(for snapshot: TaskSnapshot) async -> ReminderScheduleResult {
        do {
            let plan = try await smartReminderService.makePlan(for: snapshot)
            return try await NotificationManager.shared.schedule(plan: plan) ? .scheduled : .permissionDenied
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    func complete(_ task: TaskItem, in context: ModelContext) async throws -> ReminderScheduleResult? {
        if let nextDate = task.recurrence.nextDate(after: task.dueDate) {
            task.dueDate = nextDate
            task.isComplete = false
            try context.save()
            return await schedule(for: TaskSnapshot(task: task))
        }
        task.isComplete = true
        try context.save()
        NotificationManager.shared.cancel(for: task)
        return nil
    }

    func moveOneDayLater(_ task: TaskItem, in context: ModelContext) async throws -> ReminderScheduleResult {
        let startingDate = max(task.dueDate, .now)
        guard let newDate = Calendar.current.date(byAdding: .day, value: 1, to: startingDate) else { return .failed("Couldn’t calculate a new due date.") }
        task.dueDate = newDate
        try context.save()
        return await schedule(for: TaskSnapshot(task: task))
    }
}

enum ReminderScheduleResult {
    case scheduled, permissionDenied, failed(String)
}
