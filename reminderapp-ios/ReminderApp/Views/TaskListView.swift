import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.dueDate) private var tasks: [TaskItem]
    @State private var selectedCategoryID: String?
    @State private var showingEditor = false
    @State private var errorMessage: String?

    private var visibleTasks: [TaskItem] {
        tasks.filter { !$0.isComplete && (selectedCategoryID == nil || $0.categoryID == selectedCategoryID) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppPalette.canvas.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        quickAdd
                        categoryStrip
                        if visibleTasks.isEmpty { emptyState }
                        else {
                            taskSection("Needs attention", tasks: visibleTasks.filter { $0.dueDate < attentionCutoff }, accent: AppPalette.coral)
                            taskSection("Coming up", tasks: visibleTasks.filter { $0.dueDate >= attentionCutoff && $0.dueDate < weekCutoff }, accent: Color(hex: "#8B5CF6"))
                            taskSection("Later", tasks: visibleTasks.filter { $0.dueDate >= weekCutoff }, accent: Color(hex: "#3B82F6"))
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingEditor) { TaskEditorView() }
            .alert("Heads Up", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private var attentionCutoff: Date { Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now)) ?? .now }
    private var weekCutoff: Date { Calendar.current.date(byAdding: .day, value: 7, to: Calendar.current.startOfDay(for: .now)) ?? .now }

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting).font(.subheadline.weight(.semibold)).foregroundStyle(AppPalette.coral)
                Text("Heads up,\nfuture you.").font(.system(size: 34, weight: .bold, design: .rounded)).foregroundStyle(AppPalette.ink).lineSpacing(-3)
            }
            Spacer(minLength: 0)
            MascotView(expression: visibleTasks.isEmpty ? .celebrating : .encouraging, size: 102, showsCaption: false)
                .frame(width: 102, height: 105)
        }.padding(.top, 18)
    }

    private var quickAdd: some View {
        Button { showingEditor = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "plus").font(.title3.weight(.bold)).foregroundStyle(AppPalette.ink).frame(width: 48, height: 48).background(AppPalette.yellow, in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text("What needs doing?").font(.headline).foregroundStyle(.white)
                    Text("A task and a date—that’s all.").font(.subheadline).foregroundStyle(.white.opacity(0.75))
                }
                Spacer(); Image(systemName: "arrow.up.right").foregroundStyle(AppPalette.yellow)
            }
            .padding(16).background(AppPalette.ink, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }.buttonStyle(.plain)
    }

    private var categoryStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("Your spaces")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    categoryChip(nil, title: "All", symbol: "square.grid.2x2.fill", color: AppPalette.coral, tint: "#FFF0ED")
                    ForEach(CategoryCatalog.all) { category in
                        categoryChip(category.id, title: category.name, symbol: category.symbolName, color: Color(hex: category.colorHex), tint: category.tintHex)
                    }
                }
            }
        }
    }

    private func categoryChip(_ id: String?, title: String, symbol: String, color: Color, tint: String) -> some View {
        Button { selectedCategoryID = id } label: {
            VStack(spacing: 7) {
                Image(systemName: symbol).font(.headline.weight(.bold)).foregroundStyle(color).frame(width: 54, height: 54)
                    .background(Color(hex: tint), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(selectedCategoryID == id ? color : .clear, lineWidth: 2))
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(AppPalette.ink)
            }.frame(width: 62)
        }.buttonStyle(.plain)
    }

    @ViewBuilder private func taskSection(_ title: String, tasks: [TaskItem], accent: Color) -> some View {
        if !tasks.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) { Circle().fill(accent).frame(width: 9, height: 9); SectionTitle(title) }
                LazyVStack(spacing: 12) { ForEach(tasks) { task in taskCard(task) } }
            }
        }
    }

    private var emptyState: some View {
        SoftCard {
            HStack(spacing: 14) {
                MascotView(expression: .happy, size: 72, showsCaption: false).frame(width: 72, height: 72)
                VStack(alignment: .leading, spacing: 5) {
                    Text("A clear slate!").font(.headline).foregroundStyle(AppPalette.ink)
                    Text("Add one small thing. I’ll help you plan the rest.").font(.subheadline).foregroundStyle(AppPalette.muted)
                }
            }
        }
    }

    private func taskCard(_ task: TaskItem) -> some View {
        SoftCard {
            HStack(spacing: 12) {
                Button { complete(task) } label: {
                    Image(systemName: "circle").font(.title2).foregroundStyle(AppPalette.coral).frame(width: 44, height: 44)
                }.buttonStyle(.plain).accessibilityLabel("Complete \(task.title)")
                NavigationLink { TaskDetailView(task: task) } label: {
                    HStack(spacing: 12) {
                        CategoryArtView(category: CategoryCatalog.category(for: task.categoryID), size: 44)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title).font(.headline).foregroundStyle(AppPalette.ink).multilineTextAlignment(.leading)
                            HStack(spacing: 5) {
                                Text(dueLabel(for: task)).foregroundStyle(task.dueDate < .now ? AppPalette.coral : AppPalette.muted)
                                if task.recurrence != .never { Image(systemName: "repeat").foregroundStyle(AppPalette.muted) }
                            }.font(.caption.weight(.semibold))
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(AppPalette.muted)
                    }
                }.buttonStyle(.plain)
            }
        }
        .contextMenu {
            Button("Complete", systemImage: "checkmark.circle") { complete(task) }
            Button("Move one day later", systemImage: "clock.arrow.circlepath") { moveOneDayLater(task) }
            Button("Delete", systemImage: "trash", role: .destructive) {
                NotificationManager.shared.cancel(for: task)
                modelContext.delete(task)
                do { try modelContext.save() } catch { errorMessage = "Couldn’t delete the reminder: \(error.localizedDescription)" }
            }
        }
    }

    private func dueLabel(for task: TaskItem) -> String {
        if task.dueDate < Calendar.current.startOfDay(for: .now) { return "Overdue · \(task.dueDate.formatted(.dateTime.month(.abbreviated).day()))" }
        if Calendar.current.isDateInToday(task.dueDate) { return "Today · \(task.dueDate.formatted(.dateTime.hour().minute()))" }
        return task.dueDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private func complete(_ task: TaskItem) {
        Task {
            do { showScheduleIssue(try await ReminderCoordinator.shared.complete(task, in: modelContext)) }
            catch { errorMessage = "Couldn’t complete this reminder: \(error.localizedDescription)" }
        }
    }

    private func moveOneDayLater(_ task: TaskItem) {
        Task {
            do { showScheduleIssue(try await ReminderCoordinator.shared.moveOneDayLater(task, in: modelContext)) }
            catch { errorMessage = "Couldn’t move this reminder: \(error.localizedDescription)" }
        }
    }

    private func showScheduleIssue(_ result: ReminderScheduleResult?) {
        switch result {
        case .permissionDenied: errorMessage = "This task was updated, but notifications are off. Allow them in Settings to get future reminders."
        case .failed(let message): errorMessage = "This task was updated, but its notification could not be scheduled: \(message)"
        case .scheduled, .none: break
        }
    }

    private var greeting: String { let hour = Calendar.current.component(.hour, from: .now); return hour < 12 ? "GOOD MORNING" : hour < 18 ? "GOOD AFTERNOON" : "GOOD EVENING" }
}
