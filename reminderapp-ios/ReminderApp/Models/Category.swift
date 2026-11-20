import Foundation

struct CategoryDefinition: Identifiable, Hashable {
    let id: String
    let name: String
    let symbolName: String
    let colorHex: String
    let tintHex: String
    let shortDescription: String
    let templates: [TaskTemplate]
}

struct TaskTemplate: Identifiable, Hashable {
    let id: String
    let title: String
    let categoryID: String
    let suggestedLeadDays: Int
    let prepItems: [String]
}

enum CategoryCatalog {
    static let all: [CategoryDefinition] = [cars, house, yard, personal, health, pets, work, finance]

    static let cars = CategoryDefinition(
        id: "cars", name: "Cars", symbolName: "car.fill", colorHex: "#3B82F6", tintHex: "#E8F1FF", shortDescription: "Keep your ride ready",
        templates: [
            TaskTemplate(id: "oil-change", title: "Change the oil", categoryID: "cars", suggestedLeadDays: 7, prepItems: ["Motor oil", "Oil filter", "Funnel", "Drain pan"]),
            TaskTemplate(id: "air-filter", title: "Replace the air filter", categoryID: "cars", suggestedLeadDays: 3, prepItems: ["Replacement air filter", "Screwdriver"]),
            TaskTemplate(id: "tire-rotation", title: "Rotate the tires", categoryID: "cars", suggestedLeadDays: 7, prepItems: ["Torque wrench", "Jack", "Jack stands"]),
            TaskTemplate(id: "wiper-blades", title: "Replace wiper blades", categoryID: "cars", suggestedLeadDays: 3, prepItems: ["Replacement wiper blades"])
        ]
    )

    static let house = CategoryDefinition(id: "house", name: "House", symbolName: "house.fill", colorHex: "#8B5CF6", tintHex: "#F0EBFF", shortDescription: "Make home feel easy", templates: [
        TaskTemplate(id: "change-filter", title: "Change the air filter", categoryID: "house", suggestedLeadDays: 7, prepItems: ["Replacement filter", "Step stool"]),
        TaskTemplate(id: "deep-clean", title: "Deep clean the kitchen", categoryID: "house", suggestedLeadDays: 1, prepItems: ["Cleaner", "Microfiber cloths"])
    ])

    static let yard = CategoryDefinition(id: "yard", name: "Yard", symbolName: "leaf.fill", colorHex: "#16A34A", tintHex: "#E7F8ED", shortDescription: "Help your outside space thrive", templates: [
        TaskTemplate(id: "mow-lawn", title: "Mow the lawn", categoryID: "yard", suggestedLeadDays: 1, prepItems: ["Mower", "Water"]),
        TaskTemplate(id: "water-plants", title: "Water the plants", categoryID: "yard", suggestedLeadDays: 0, prepItems: ["Hose or watering can"])
    ])

    static let personal = CategoryDefinition(id: "personal", name: "Personal", symbolName: "sparkles", colorHex: "#EC4899", tintHex: "#FDEAF4", shortDescription: "Make space for yourself", templates: [
        TaskTemplate(id: "haircut", title: "Book a haircut", categoryID: "personal", suggestedLeadDays: 3, prepItems: [])
    ])

    static let health = CategoryDefinition(id: "health", name: "Health", symbolName: "heart.fill", colorHex: "#EF4444", tintHex: "#FDECEC", shortDescription: "Take care of future you", templates: [
        TaskTemplate(id: "annual-checkup", title: "Book an annual checkup", categoryID: "health", suggestedLeadDays: 7, prepItems: ["Insurance card", "Questions for doctor"])
    ])

    static let pets = CategoryDefinition(id: "pets", name: "Pets", symbolName: "pawprint.fill", colorHex: "#F59E0B", tintHex: "#FFF6DC", shortDescription: "Keep tails wagging", templates: [
        TaskTemplate(id: "pet-vet", title: "Schedule a vet visit", categoryID: "pets", suggestedLeadDays: 7, prepItems: ["Pet carrier", "Pet records"])
    ])

    static let work = CategoryDefinition(id: "work", name: "Work", symbolName: "briefcase.fill", colorHex: "#0F766E", tintHex: "#E3F7F4", shortDescription: "Stay one step ahead", templates: [
        TaskTemplate(id: "weekly-review", title: "Plan next week", categoryID: "work", suggestedLeadDays: 1, prepItems: ["Calendar", "Task list"])
    ])

    static let finance = CategoryDefinition(id: "finance", name: "Finance", symbolName: "creditcard.fill", colorHex: "#64748B", tintHex: "#EEF2F6", shortDescription: "Give your money a moment", templates: [
        TaskTemplate(id: "pay-bill", title: "Pay a bill", categoryID: "finance", suggestedLeadDays: 3, prepItems: ["Account details"])
    ])

    static var defaultCategory: CategoryDefinition { cars }
    static func category(for id: String) -> CategoryDefinition { all.first(where: { $0.id == id }) ?? defaultCategory }

    static func suggestedCategoryID(for title: String) -> String {
        let value = title.lowercased()
        if ["car", "oil", "tire", "brake", "wiper", "vehicle"].contains(where: value.contains) { return cars.id }
        if ["lawn", "garden", "yard", "plant", "mow"].contains(where: value.contains) { return yard.id }
        if ["vet", "pet", "dog", "cat"].contains(where: value.contains) { return pets.id }
        if ["doctor", "dentist", "medicine", "checkup"].contains(where: value.contains) { return health.id }
        if ["bill", "bank", "tax", "budget"].contains(where: value.contains) { return finance.id }
        if ["meeting", "project", "office", "work"].contains(where: value.contains) { return work.id }
        if ["house", "home", "filter", "kitchen", "clean"].contains(where: value.contains) { return house.id }
        return personal.id
    }
}
