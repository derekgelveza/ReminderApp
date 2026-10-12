import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TaskDetailViewModel()
    @State private var showingEditor = false
    let task: TaskItem

    var body: some View {
        List {
            Section {
                Label(task.dueDate.formatted(date: .long, time: .shortened), systemImage: "calendar")
                Label(CategoryCatalog.category(for: task.categoryID).name, systemImage: CategoryCatalog.category(for: task.categoryID).symbolName)
            }
            if !task.prepItems.isEmpty {
                Section("Prep checklist") {
                    ForEach(task.prepItems, id: \.self) { item in Label(item, systemImage: "circle") }
                }
            }
            Section("AI how-to") {
                if viewModel.isLoading { ProgressView("Generating a practical guide…") }
                if let guide = viewModel.guide {
                    Text(guide.summary).font(.subheadline)
                    ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                        Label(step, systemImage: "(index + 1).circle")
                    }
                    if !guide.toolsAndSupplies.isEmpty { LabeledContent("Tools & supplies", value: guide.toolsAndSupplies.joined(separator: ", ")) }
                    ForEach(guide.safetyNotes, id: \.self) { Text("Safety: \($0)").foregroundStyle(.orange) }
                } else if let errorMessage = viewModel.errorMessage { Text(errorMessage).foregroundStyle(.secondary) }
            }
            Section("Recommended videos") {
                ForEach(viewModel.videos) { video in
                    Link(destination: video.url) { Label(video.title, systemImage: "play.rectangle") }
                }
            }
        }
        .navigationTitle(task.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Edit") { showingEditor = true } }
        }
        .sheet(isPresented: $showingEditor) { TaskEditorView(existingTask: task) }
        .task(id: task.id) { await viewModel.load(for: task) }
    }
}
