import SwiftUI
import SwiftData

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TaskEditorViewModel()
    let existingTask: TaskItem?
    init(existingTask: TaskItem? = nil) { self.existingTask = existingTask }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $viewModel.title)
                    Picker("Category", selection: $viewModel.categoryID) { ForEach(CategoryCatalog.all) { category in Text(category.name).tag(category.id) } }
                    DatePicker("Due date", selection: $viewModel.dueDate, in: .now..., displayedComponents: [.date, .hourAndMinute])
                }
                Section("Reminder") {
                    Picker("Remind me", selection: $viewModel.reminderLeadDays) { Text("On the due date").tag(0); Text("1 day before").tag(1); Text("3 days before").tag(3); Text("1 week before").tag(7) }
                    Text("Prep supplies are reminded earlier so there is time to gather them.").font(.footnote).foregroundStyle(.secondary)
                }
                Section("Prep checklist") {
                    HStack { TextField("Add supply or prep item", text: $viewModel.newPrepItem); Button("Add") { viewModel.addPrepItem() }.disabled(viewModel.newPrepItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
                    ForEach(viewModel.prepItems, id: \.self) { Text($0) }.onDelete { viewModel.prepItems.remove(atOffsets: $0) }
                }
            }
            .navigationTitle(existingTask == nil ? "New Reminder" : "Edit Reminder")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!viewModel.isValid) } }
            .onAppear { if let existingTask { viewModel.load(existingTask) } }
        }
    }

    private func save() {
        let task: TaskItem
        if let existingTask { viewModel.apply(to: existingTask); task = existingTask }
        else { task = TaskItem(title: viewModel.title, categoryID: viewModel.categoryID, dueDate: viewModel.dueDate, reminderLeadDays: viewModel.reminderLeadDays, prepItems: viewModel.prepItems); modelContext.insert(task) }
        try? modelContext.save()
        Task { await NotificationManager.shared.schedule(for: task) }
        dismiss()
    }
}
