import Foundation
import SwiftData

enum SeedDataService {
    static func seedIfNeeded(in context: ModelContext) {
        guard (try? context.fetchCount(FetchDescriptor<TaskItem>())) == 0 else { return }
        let calendar = Calendar.current
        let oil = CategoryCatalog.cars.templates[0]
        let air = CategoryCatalog.cars.templates[1]
        context.insert(TaskItem(title: oil.title, categoryID: oil.categoryID, dueDate: calendar.date(byAdding: .day, value: 14, to: .now)!, reminderLeadDays: oil.suggestedLeadDays, prepItems: oil.prepItems))
        context.insert(TaskItem(title: air.title, categoryID: air.categoryID, dueDate: calendar.date(byAdding: .day, value: 30, to: .now)!, reminderLeadDays: air.suggestedLeadDays, prepItems: air.prepItems))
        try? context.save()
    }
}
