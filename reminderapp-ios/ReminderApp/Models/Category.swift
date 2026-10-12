import Foundation

struct CategoryDefinition: Identifiable, Hashable {
    let id: String
    let name: String
    let symbolName: String
    let colorName: String
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
    static let all: [CategoryDefinition] = [cars]

    static let cars = CategoryDefinition(
        id: "cars", name: "Cars", symbolName: "car.fill", colorName: "blue",
        templates: [
            TaskTemplate(id: "oil-change", title: "Change the oil", categoryID: "cars", suggestedLeadDays: 7, prepItems: ["Motor oil", "Oil filter", "Funnel", "Drain pan"]),
            TaskTemplate(id: "air-filter", title: "Replace the air filter", categoryID: "cars", suggestedLeadDays: 3, prepItems: ["Replacement air filter", "Screwdriver"]),
            TaskTemplate(id: "tire-rotation", title: "Rotate the tires", categoryID: "cars", suggestedLeadDays: 7, prepItems: ["Torque wrench", "Jack", "Jack stands"]),
            TaskTemplate(id: "wiper-blades", title: "Replace wiper blades", categoryID: "cars", suggestedLeadDays: 3, prepItems: ["Replacement wiper blades"])
        ]
    )

    static var defaultCategory: CategoryDefinition { cars }
    static func category(for id: String) -> CategoryDefinition { all.first(where: { $0.id == id }) ?? defaultCategory }
}
