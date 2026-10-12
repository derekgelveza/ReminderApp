//
//  ReminderAppApp.swift
//  ReminderApp
//
//  Created by Jeffrey Fuhriman on 10/1/26.
//

import SwiftUI
import SwiftData

@main
struct ReminderAppApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: TaskItem.self)
            NotificationManager.shared.configureDelegate()
            SeedDataService.seedIfNeeded(in: modelContainer.mainContext)
        } catch {
            fatalError("Unable to create the app's data container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            TaskListView()
        }
        .modelContainer(modelContainer)
    }
}
