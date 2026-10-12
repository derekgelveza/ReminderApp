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
    var isComplete: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        categoryID: String,
        dueDate: Date,
        reminderLeadDays: Int = 0,
        prepItems: [String] = [],
        isComplete: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.categoryID = categoryID
        self.dueDate = dueDate
        self.reminderLeadDays = reminderLeadDays
        self.prepItems = prepItems
        self.isComplete = isComplete
        self.createdAt = createdAt
    }
}
