import SwiftUI
import CoreData

@main
struct TaskAppApp: App {
    let persistence = PersistenceController.shared
    @StateObject private var taskStore: TaskStore

    init() {
        _taskStore = StateObject(wrappedValue: TaskStore(context: PersistenceController.shared.container.viewContext))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .environmentObject(taskStore)
        }
    }
}
