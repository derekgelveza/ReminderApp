import SwiftUI
import SwiftData

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TaskEditorViewModel()
    @State private var plan: SmartReminderPlan?
    @State private var showingPlan = false
    @State private var isBusy = false
    @State private var alertMessage: String?
    @State private var dismissAfterAlert = false
    @State private var showingOptions = false
    @State private var acceptedInitialSuggestions = false
    let existingTask: TaskItem?

    init(existingTask: TaskItem? = nil) { self.existingTask = existingTask }

    var body: some View {
        NavigationStack {
            ZStack {
                AppPalette.canvas.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack(spacing: 14) {
                            MascotView(expression: showingPlan ? .reminding : .thinking, size: 74, showsCaption: false)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(showingPlan ? "Here’s your plan" : "Let’s get ahead of it")
                                    .font(.system(size: 27, weight: .bold, design: .rounded)).foregroundStyle(AppPalette.ink)
                                Text(showingPlan ? "Change anything before saving." : "Just two things to get started.")
                                    .font(.subheadline).foregroundStyle(AppPalette.muted)
                            }
                        }
                        if showingPlan { planContent }
                        else { entryContent }
                    }
                    .padding(20)
                    .padding(.bottom, 20)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button { if showingPlan { save() } else { preview() } } label: {
                    HStack { if isBusy { ProgressView().tint(.white) }; Text(showingPlan ? "Save reminder" : "Preview my plan"); Image(systemName: showingPlan ? "checkmark" : "arrow.right") }
                        .font(.headline).frame(maxWidth: .infinity).padding(16)
                        .background(AppPalette.ink, in: RoundedRectangle(cornerRadius: 18, style: .continuous)).foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.isValid || isBusy || (showingPlan && plan == nil))
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(AppPalette.canvas)
            }
            .navigationTitle(existingTask == nil ? "New reminder" : "Edit reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(showingPlan ? "Back" : "Cancel") {
                        if showingPlan { showingPlan = false; plan = nil } else { dismiss() }
                    }
                }
            }
            .alert("Heads Up", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
                Button("OK") { alertMessage = nil; if dismissAfterAlert { dismiss() } }
            } message: { Text(alertMessage ?? "") }
            .onAppear { if let existingTask { viewModel.load(existingTask) } }
        }
    }

    private var entryContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 9) {
                Text("What needs doing?").font(.headline).foregroundStyle(AppPalette.ink)
                TextField("e.g. Change the oil", text: $viewModel.title)
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppPalette.ink)
                    .padding(16)
                    .background(.white, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                    .submitLabel(.done)
                if existingTask == nil {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(CategoryCatalog.all.flatMap(\.templates).prefix(6)) { template in
                                Button(template.title) { viewModel.applyTemplate(template) }
                                    .font(.caption.weight(.semibold)).foregroundStyle(AppPalette.ink)
                                    .padding(.horizontal, 12).padding(.vertical, 9).background(.white, in: Capsule())
                            }
                        }
                    }
                }
            }
            SoftCard {
                DatePicker("When is it due?", selection: $viewModel.dueDate, in: .now..., displayedComponents: [.date, .hourAndMinute])
                    .font(.headline).foregroundStyle(AppPalette.ink).tint(AppPalette.coral)
            }
            DisclosureGroup(isExpanded: $showingOptions) {
                optionsContent.padding(.top, 14)
            } label: {
                Label("Personalize this reminder", systemImage: "slider.horizontal.3")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(AppPalette.ink)
            }
            .tint(AppPalette.coral)
            .padding(16)
            .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var optionsContent: some View {
        VStack(alignment: .leading, spacing: 15) {
            Picker("Category", selection: Binding(get: { viewModel.categoryID }, set: { viewModel.categoryID = $0; viewModel.categoryWasChosen = true })) {
                ForEach(CategoryCatalog.all) { category in Label(category.name, systemImage: category.symbolName).tag(category.id) }
            }
            Picker("How will you handle it?", selection: Binding(get: { viewModel.completionMode }, set: { viewModel.completionMode = $0; viewModel.modeWasChosen = true })) {
                ForEach(CompletionMode.allCases, id: \.self) { mode in Text(mode.title).tag(mode) }
            }
            Picker("Heads up", selection: $viewModel.reminderLeadDays) {
                Text("On the day").tag(0); Text("1 day before").tag(1); Text("3 days before").tag(3); Text("1 week before").tag(7)
            }
            Picker("Repeat", selection: $viewModel.recurrence) {
                ForEach(RecurrenceRule.allCases, id: \.self) { rule in Text(rule.title).tag(rule) }
            }
        }
        .tint(AppPalette.ink)
    }

    private var planContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let plan {
                SoftCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(viewModel.title).font(.title3.bold()).foregroundStyle(AppPalette.ink)
                        if let prepDays = plan.prepLeadDays, let prepMessage = plan.prepMessage {
                            planRow(symbol: "shippingbox.fill", date: dayBefore(prepDays), title: "Get ready", detail: prepMessage)
                        }
                        if plan.leadDays > 0 {
                            planRow(symbol: "bell.fill", date: dayBefore(plan.leadDays), title: "Heads up", detail: plan.message)
                        }
                        planRow(symbol: "checkmark.circle.fill", date: viewModel.dueDate, title: "Due", detail: viewModel.title)
                    }
                }
            }
            SoftCard {
                VStack(alignment: .leading, spacing: 14) {
                    Picker("Heads up", selection: $viewModel.reminderLeadDays) {
                        Text("On the day").tag(0); Text("1 day before").tag(1); Text("3 days before").tag(3); Text("1 week before").tag(7)
                    }.onChange(of: viewModel.reminderLeadDays) { _, _ in refreshPreview() }
                    Toggle("Send a prep nudge", isOn: $viewModel.prepReminderEnabled)
                        .tint(AppPalette.coral)
                        .onChange(of: viewModel.prepReminderEnabled) { _, _ in refreshPreview() }
                    if let plan, !plan.prepItems.isEmpty {
                        Text("Suggested supplies").font(.subheadline.weight(.semibold)).foregroundStyle(AppPalette.ink)
                        Text(plan.prepItems.joined(separator: " • ")).font(.subheadline).foregroundStyle(AppPalette.muted)
                    }
                    HStack {
                        TextField("Add a prep item", text: $viewModel.newPrepItem).foregroundStyle(AppPalette.ink)
                        Button { viewModel.addPrepItem(); refreshPreview() } label: { Image(systemName: "plus.circle.fill").font(.title2) }
                            .disabled(viewModel.newPrepItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    ForEach(viewModel.prepItems, id: \.self) { item in
                        HStack { Text(item); Spacer(); Button { viewModel.prepItems.removeAll { $0 == item }; if viewModel.prepItems.isEmpty { viewModel.prepReminderEnabled = false }; refreshPreview() } label: { Image(systemName: "xmark.circle") } }
                            .foregroundStyle(AppPalette.ink)
                    }
                }
                .tint(AppPalette.coral)
            }
            if viewModel.recurrence != .never { Label(viewModel.recurrence.title, systemImage: "repeat").font(.subheadline.weight(.semibold)).foregroundStyle(AppPalette.muted) }
        }
    }

    private func planRow(symbol: String, date: Date, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).font(.headline).foregroundStyle(AppPalette.coral).frame(width: 23)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(title) · \(date.formatted(.dateTime.month(.abbreviated).day()))").font(.subheadline.weight(.bold)).foregroundStyle(AppPalette.ink)
                Text(detail).font(.subheadline).foregroundStyle(AppPalette.muted)
                if date <= .now { Text("This date has passed, so no notification will be sent for it.").font(.caption).foregroundStyle(AppPalette.coral) }
            }
        }
    }

    private func dayBefore(_ days: Int) -> Date { Calendar.current.date(byAdding: .day, value: -days, to: viewModel.dueDate) ?? viewModel.dueDate }

    private func preview() {
        guard viewModel.isValid else { return }
        viewModel.inferDetailsIfNeeded()
        showingPlan = true
        refreshPreview()
    }

    private func refreshPreview() {
        isBusy = true
        let snapshot = viewModel.snapshot
        Task {
            do {
                let result = try await ReminderCoordinator.shared.preview(for: snapshot)
                if !acceptedInitialSuggestions && viewModel.prepItems.isEmpty && viewModel.prepReminderEnabled && !result.prepItems.isEmpty {
                    acceptedInitialSuggestions = true
                    viewModel.prepItems = result.prepItems
                }
                plan = result
            }
            catch { plan = nil; alertMessage = "Couldn’t build a plan: \(error.localizedDescription)" }
            isBusy = false
        }
    }

    private func save() {
        guard plan != nil else { return }
        isBusy = true
        let task: TaskItem
        if let existingTask { viewModel.apply(to: existingTask); task = existingTask }
        else {
            task = TaskItem(title: viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines), categoryID: viewModel.categoryID, dueDate: viewModel.dueDate, reminderLeadDays: viewModel.reminderLeadDays, prepItems: viewModel.prepItems, completionMode: viewModel.completionMode, recurrence: viewModel.recurrence, prepReminderEnabled: viewModel.prepReminderEnabled)
            modelContext.insert(task)
        }
        do { try modelContext.save() }
        catch { isBusy = false; alertMessage = "Couldn’t save this reminder: \(error.localizedDescription)"; return }
        let snapshot = TaskSnapshot(task: task)
        Task {
            let result = await ReminderCoordinator.shared.schedule(for: snapshot)
            isBusy = false
            switch result {
            case .scheduled: dismiss()
            case .permissionDenied: dismissAfterAlert = true; alertMessage = "Saved, but notifications are off. Allow them in Settings to receive your nudges."
            case .failed(let message): dismissAfterAlert = true; alertMessage = "Saved, but scheduling failed: \(message)"
            }
        }
    }
}
