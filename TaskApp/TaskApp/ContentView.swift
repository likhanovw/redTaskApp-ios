import SwiftUI
import CoreData

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TaskListView()
                .tabItem { Label("Задачи", systemImage: "list.bullet") }
                .tag(0)
            CompletedTasksView()
                .tabItem { Label("Архив", systemImage: "checkmark.circle.fill") }
                .tag(1)
            TagsView()
                .tabItem { Label("Теги", systemImage: "tag") }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(TaskStore(context: PersistenceController.shared.container.viewContext))
}
