import Foundation
import Observation

@Observable
final class TaskEditorViewModel {
    var title = ""
    var categoryID = CategoryCatalog.personal.id
    var dueDate = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    var reminderLeadDays = 0
    var prepItems: [String] = []
    var completionMode: CompletionMode = .diy
    var recurrence: RecurrenceRule = .never
    var prepReminderEnabled = true
    var newPrepItem = ""
    var categoryWasChosen = false
    var modeWasChosen = false
    var isValid: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    func addPrepItem() { let item = newPrepItem.trimmingCharacters(in: .whitespacesAndNewlines); guard !item.isEmpty else { return }; prepItems.append(item); newPrepItem = "" }
    func load(_ task: TaskItem) { title = task.title; categoryID = task.categoryID; categoryWasChosen = true; dueDate = task.dueDate; reminderLeadDays = task.reminderLeadDays; prepItems = task.prepItems; completionMode = task.completionMode; modeWasChosen = true; recurrence = task.recurrence; prepReminderEnabled = task.shouldSendPrepReminder }
    func applyTemplate(_ template: TaskTemplate) { title = template.title; categoryID = template.categoryID; categoryWasChosen = true; reminderLeadDays = template.suggestedLeadDays; prepItems = template.prepItems }
    func inferDetailsIfNeeded() {
        if !categoryWasChosen { categoryID = CategoryCatalog.suggestedCategoryID(for: title) }
        if !modeWasChosen {
            let value = title.lowercased()
            if value.contains("book ") || value.contains("schedule ") || value.contains("appointment") { completionMode = .professional }
        }
    }
    func apply(to task: TaskItem) { task.title = title.trimmingCharacters(in: .whitespacesAndNewlines); task.categoryID = categoryID; task.dueDate = dueDate; task.reminderLeadDays = reminderLeadDays; task.prepItems = prepItems; task.completionMode = completionMode; task.recurrence = recurrence; task.prepReminderEnabled = prepReminderEnabled }

    var snapshot: TaskSnapshot {
        TaskSnapshot(title: title.trimmingCharacters(in: .whitespacesAndNewlines), categoryID: categoryID, dueDate: dueDate, prepItems: prepItems, completionMode: completionMode, reminderLeadDays: reminderLeadDays, prepReminderEnabled: prepReminderEnabled)
    }
}
