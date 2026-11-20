import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TaskDetailViewModel()
    @State private var showingEditor = false
    @State private var errorMessage: String?
    let task: TaskItem

    var body: some View {
        ZStack {
            AppPalette.canvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero
                    if let plan = viewModel.smartPlan { smartNudge(plan) }
                    prepCard
                    guideCard
                    videoCard
                    Button { complete() } label: { Label(task.recurrence == .never ? "Mark it done" : "Complete this occurrence", systemImage: "checkmark.circle.fill").font(.headline).frame(maxWidth: .infinity).padding(16).background(AppPalette.ink, in: RoundedRectangle(cornerRadius: 18, style: .continuous)).foregroundStyle(.white) }.buttonStyle(.plain)
                }.padding(20).padding(.bottom, 30)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Edit") { showingEditor = true }.fontWeight(.semibold) } }
        .sheet(isPresented: $showingEditor) { TaskEditorView(existingTask: task) }
        .task(id: task.id) { await viewModel.load(for: task) }
        .alert("Heads Up", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) { Button("OK") { errorMessage = nil } } message: { Text(errorMessage ?? "") }
    }

    private var hero: some View {
        HStack(alignment: .top, spacing: 16) {
            CategoryArtView(category: CategoryCatalog.category(for: task.categoryID), size: 66)
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title).font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(AppPalette.ink)
                Text(task.dueDate, format: .dateTime.weekday(.wide).month(.wide).day()).font(.subheadline.weight(.semibold)).foregroundStyle(AppPalette.muted)
                Label(task.completionMode.title, systemImage: task.completionMode.symbolName).font(.caption.weight(.semibold)).foregroundStyle(AppPalette.coral)
                if task.recurrence != .never { Label(task.recurrence.title, systemImage: "repeat").font(.caption.weight(.semibold)).foregroundStyle(AppPalette.muted) }
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private func smartNudge(_ plan: SmartReminderPlan) -> some View {
        SoftCard {
            HStack(alignment: .top, spacing: 14) { MascotView(expression: .reminding, size: 54).scaleEffect(0.72).frame(width: 65, height: 78); VStack(alignment: .leading, spacing: 7) { Text("Your smart nudge").font(.headline).foregroundStyle(AppPalette.ink); Text(plan.message).font(.subheadline).foregroundStyle(AppPalette.muted); if let prepMessage = plan.prepMessage { Text(prepMessage).font(.caption.weight(.semibold)).foregroundStyle(AppPalette.coral) } } }
        }
    }

    private var prepCard: some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 12) { HStack { Text("Prep checklist").font(.headline).foregroundStyle(AppPalette.ink); Spacer(); Image(systemName: "shippingbox.fill").foregroundStyle(AppPalette.coral) }; if task.prepItems.isEmpty { Text("No prep items yet. Edit this reminder to add anything future you should have ready.").font(.subheadline).foregroundStyle(AppPalette.muted) } else { ForEach(task.prepItems, id: \.self) { item in Label(item, systemImage: "circle").foregroundStyle(AppPalette.ink) } } }
        }
    }

    private var guideCard: some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 14) { HStack { Text("How to do it").font(.headline).foregroundStyle(AppPalette.ink); Spacer(); Image(systemName: "wand.and.stars").foregroundStyle(AppPalette.coral) }; if viewModel.isLoading { ProgressView("Making a simple plan…") } else if let guide = viewModel.guide { Text(guide.summary).font(.subheadline).foregroundStyle(AppPalette.muted); ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in HStack(alignment: .top, spacing: 10) { Text("\(index + 1)").font(.caption.bold()).foregroundStyle(.white).frame(width: 24, height: 24).background(AppPalette.coral, in: Circle()); Text(step).font(.subheadline).foregroundStyle(AppPalette.ink) } }; if !guide.safetyNotes.isEmpty { Text(guide.safetyNotes.joined(separator: " ")).font(.caption).foregroundStyle(.orange) } } }
        }
    }

    private var videoCard: some View {
        SoftCard { VStack(alignment: .leading, spacing: 12) { HStack { Text("Helpful videos").font(.headline).foregroundStyle(AppPalette.ink); Spacer(); Image(systemName: "play.rectangle.fill").foregroundStyle(AppPalette.coral) }; ForEach(viewModel.videos) { video in Link(destination: video.url) { HStack { Image(systemName: "play.circle.fill").foregroundStyle(AppPalette.coral); Text(video.title).font(.subheadline.weight(.medium)).foregroundStyle(AppPalette.ink); Spacer(); Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(AppPalette.muted) } } } } }
    }

    private func complete() {
        Task {
            do {
                let result = try await ReminderCoordinator.shared.complete(task, in: modelContext)
                if case .permissionDenied = result { errorMessage = "This task was updated, but notifications are off in Settings." }
                else if case .failed(let message) = result { errorMessage = "This task was updated, but its next notification failed: \(message)" }
                else { dismiss() }
            }
            catch { errorMessage = "Couldn’t complete this reminder: \(error.localizedDescription)" }
        }
    }
}
