import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.dueDate) private var tasks: [TaskItem]
    @State private var selectedCategoryID: String?
    @State private var showingEditor = false
    private var filteredTasks: [TaskItem] { guard let selectedCategoryID else { return tasks }; return tasks.filter { $0.categoryID == selectedCategoryID } }

    var body: some View {
        NavigationStack {
            List {
                if filteredTasks.isEmpty { ContentUnavailableView("No reminders", systemImage: "checklist", description: Text("Add a task to get started.")) }
                else {
                    ForEach(filteredTasks) { task in
                        NavigationLink { TaskDetailView(task: task) } label: { TaskRow(task: task) }
                            .swipeActions { Button(role: .destructive) { NotificationManager.shared.cancel(for: task); modelContext.delete(task) } label: { Label("Delete", systemImage: "trash") } }
                    }
                }
            }
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("All categories") { selectedCategoryID = nil }
                        ForEach(CategoryCatalog.all) { category in Button(category.name) { selectedCategoryID = category.id } }
                    } label: { Label("Filter", systemImage: "line.3.horizontal.decrease.circle") }
                }
                ToolbarItem(placement: .topBarTrailing) { Button { showingEditor = true } label: { Label("Add reminder", systemImage: "plus") } }
            }
            .sheet(isPresented: $showingEditor) { TaskEditorView() }
        }
    }
}

private struct TaskRow: View {
    let task: TaskItem
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: CategoryCatalog.category(for: task.categoryID).symbolName).foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title).font(.headline)
                Text(task.dueDate, format: .dateTime.month().day().year()).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            if !task.prepItems.isEmpty { Image(systemName: "shippingbox").foregroundStyle(.secondary) }
        }.padding(.vertical, 4)
    }
}
