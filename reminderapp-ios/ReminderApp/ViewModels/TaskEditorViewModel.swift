import Foundation
import Observation

@Observable
final class TaskEditorViewModel {
    var title = ""
    var categoryID = CategoryCatalog.defaultCategory.id
    var dueDate = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    var reminderLeadDays = 0
    var prepItems: [String] = []
    var newPrepItem = ""
    var isValid: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    func addPrepItem() { let item = newPrepItem.trimmingCharacters(in: .whitespacesAndNewlines); guard !item.isEmpty else { return }; prepItems.append(item); newPrepItem = "" }
    func load(_ task: TaskItem) { title = task.title; categoryID = task.categoryID; dueDate = task.dueDate; reminderLeadDays = task.reminderLeadDays; prepItems = task.prepItems }
    func apply(to task: TaskItem) { task.title = title.trimmingCharacters(in: .whitespacesAndNewlines); task.categoryID = categoryID; task.dueDate = dueDate; task.reminderLeadDays = reminderLeadDays; task.prepItems = prepItems }
}
