import Foundation

struct HowToGuide: Identifiable, Hashable {
    let id = UUID()
    let summary: String
    let steps: [String]
    let toolsAndSupplies: [String]
    let safetyNotes: [String]
}

struct SmartReminderPlan: Sendable {
    let taskID: UUID
    let taskTitle: String
    let dueDate: Date
    let leadDays: Int
    let prepLeadDays: Int?
    let prepItems: [String]
    let message: String
    let prepMessage: String?
}

protocol SmartReminderService {
    func makePlan(for task: TaskSnapshot) async throws -> SmartReminderPlan
}

protocol AIStepsService {
    func generateGuide(for task: TaskSnapshot) async throws -> HowToGuide
}

struct MockAIStepsService: AIStepsService {
    func generateGuide(for task: TaskSnapshot) async throws -> HowToGuide {
        if task.title.lowercased().contains("oil") {
            return HowToGuide(summary: "A practical oil-change walkthrough for a typical passenger vehicle.", steps: [
                "Confirm the correct oil grade and filter for your vehicle.",
                "Warm the engine briefly, park on level ground, set the parking brake, and let hot parts cool enough to handle.",
                "Place a drain pan under the drain plug, remove the plug, and let the old oil drain completely.",
                "Replace the drain-plug washer if required, install the new filter with a light film of oil on its gasket, and tighten it by hand.",
                "Reinstall the plug, add the specified amount of new oil, check the dipstick, and inspect for leaks."
            ], toolsAndSupplies: task.prepItems.isEmpty ? ["Motor oil", "Oil filter", "Drain pan", "Funnel", "Gloves"] : task.prepItems, safetyNotes: ["Never work under a car supported only by a jack.", "Recycle used oil at an approved collection point."])
        }
        return HowToGuide(summary: "A concise starting point for completing this task safely.", steps: ["Gather the listed supplies and read the product or vehicle instructions.", "Set up a clean, well-lit work area.", "Complete the task one step at a time and verify the result before putting tools away."], toolsAndSupplies: task.prepItems, safetyNotes: ["Stop and consult the manufacturer's instructions if anything is unclear."])
    }
}

struct MockSmartReminderService: SmartReminderService {
    func makePlan(for task: TaskSnapshot) async throws -> SmartReminderPlan {
        let normalized = task.title.lowercased()
        let inferredItems: [String]
        if normalized.contains("oil") { inferredItems = ["Motor oil", "Oil filter"] }
        else if normalized.contains("filter") { inferredItems = ["Replacement filter"] }
        else if normalized.contains("vet") { inferredItems = ["Pet records", "Pet carrier"] }
        else { inferredItems = task.prepItems }

        let items = task.prepItems.isEmpty && task.completionMode == .diy ? inferredItems : task.prepItems
        let leadDays = task.reminderLeadDays
        let availableDays = max(0, Int(task.dueDate.timeIntervalSinceNow / 86_400))
        let prepLeadDays = task.prepReminderEnabled && task.completionMode == .diy && !items.isEmpty && availableDays > 0
            ? min(max(leadDays + 1, 7), availableDays) : nil
        let message: String
        if task.completionMode == .professional {
            message = "Would you like help planning \(task.title.lowercased()) this week?"
        } else {
            message = "Heads up: \(task.title.lowercased()) is coming up. You’ve got this!"
        }
        let prepMessage = prepLeadDays == nil ? nil : "Gather what you need: \(items.joined(separator: ", "))."
        return SmartReminderPlan(taskID: task.id, taskTitle: task.title, dueDate: task.dueDate, leadDays: leadDays, prepLeadDays: prepLeadDays, prepItems: items, message: message, prepMessage: prepMessage)
    }
}

// Swap this type for a real backend-backed implementation. Keep provider secrets off-device.
struct LiveAIStepsServiceStub: AIStepsService {
    let endpoint: URL
    func generateGuide(for task: TaskSnapshot) async throws -> HowToGuide {
        throw NSError(domain: "LiveAIStepsServiceStub", code: 501, userInfo: [NSLocalizedDescriptionKey: "Configure a secure server endpoint before enabling live AI."])
    }
}
