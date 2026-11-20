import Foundation
import SwiftData

@Model
final class TaskItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var categoryID: String
    var dueDate: Date
    var reminderLeadDays: Int
    var prepItems: [String]
    // Optional so stores created before completion mode was added can migrate in place.
    var completionModeRaw: String?
    var recurrenceRaw: String?
    var prepReminderEnabled: Bool?
    var isComplete: Bool
    var createdAt: Date

    init(id: UUID = UUID(), title: String, categoryID: String, dueDate: Date, reminderLeadDays: Int = 0, prepItems: [String] = [], completionMode: CompletionMode = .diy, recurrence: RecurrenceRule = .never, prepReminderEnabled: Bool = true, isComplete: Bool = false, createdAt: Date = .now) {
        self.id = id
        self.title = title
        self.categoryID = categoryID
        self.dueDate = dueDate
        self.reminderLeadDays = reminderLeadDays
        self.prepItems = prepItems
        self.completionModeRaw = completionMode.rawValue
        self.recurrenceRaw = recurrence.rawValue
        self.prepReminderEnabled = prepReminderEnabled
        self.isComplete = isComplete
        self.createdAt = createdAt
    }

    var completionMode: CompletionMode {
        get { completionModeRaw.flatMap(CompletionMode.init(rawValue:)) ?? .diy }
        set { completionModeRaw = newValue.rawValue }
    }

    var recurrence: RecurrenceRule {
        get { recurrenceRaw.flatMap(RecurrenceRule.init(rawValue:)) ?? .never }
        set { recurrenceRaw = newValue.rawValue }
    }

    var shouldSendPrepReminder: Bool { prepReminderEnabled ?? true }
}

enum RecurrenceRule: String, CaseIterable, Sendable {
    case never, daily, weekly, monthly, yearly

    var title: String {
        switch self {
        case .never: "Does not repeat"
        case .daily: "Every day"
        case .weekly: "Every week"
        case .monthly: "Every month"
        case .yearly: "Every year"
        }
    }

    func nextDate(after date: Date, now: Date = .now) -> Date? {
        guard self != .never else { return nil }
        let component: Calendar.Component
        switch self {
        case .never: return nil
        case .daily: component = .day
        case .weekly: component = .weekOfYear
        case .monthly: component = .month
        case .yearly: component = .year
        }
        var result = date
        repeat {
            guard let next = Calendar.current.date(byAdding: component, value: 1, to: result) else { return nil }
            result = next
        } while result <= now
        return result
    }
}

enum CompletionMode: String, CaseIterable, Codable, Sendable {
    case diy
    case professional

    var title: String { self == .diy ? "I'll do it" : "I'd like help" }
    var subtitle: String { self == .diy ? "Give me a prep checklist" : "Help me plan or book it" }
    var symbolName: String { self == .diy ? "wrench.and.screwdriver.fill" : "person.crop.circle.badge.checkmark" }
}

/// Immutable data passed across async service boundaries instead of the SwiftData model itself.
struct TaskSnapshot: Sendable {
    let id: UUID
    let title: String
    let categoryID: String
    let dueDate: Date
    let prepItems: [String]
    let completionMode: CompletionMode
    let reminderLeadDays: Int
    let prepReminderEnabled: Bool

    init(task: TaskItem) {
        id = task.id
        title = task.title
        categoryID = task.categoryID
        dueDate = task.dueDate
        prepItems = task.prepItems
        completionMode = task.completionMode
        reminderLeadDays = task.reminderLeadDays
        prepReminderEnabled = task.shouldSendPrepReminder
    }

    init(id: UUID = UUID(), title: String, categoryID: String, dueDate: Date, prepItems: [String], completionMode: CompletionMode, reminderLeadDays: Int, prepReminderEnabled: Bool) {
        self.id = id
        self.title = title
        self.categoryID = categoryID
        self.dueDate = dueDate
        self.prepItems = prepItems
        self.completionMode = completionMode
        self.reminderLeadDays = reminderLeadDays
        self.prepReminderEnabled = prepReminderEnabled
    }
}
