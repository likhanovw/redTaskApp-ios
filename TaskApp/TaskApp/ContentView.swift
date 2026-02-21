import SwiftUI
import CoreData

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TaskListView()
                .frame(minHeight: 1)
                .tabItem { Label("Задачи", systemImage: "list.bullet") }
                .tag(0)
            CompletedTasksView()
                .frame(minHeight: 1)
                .tabItem { Label("Архив", systemImage: "checkmark.circle.fill") }
                .tag(1)
            TagsView()
                .frame(minHeight: 1)
                .tabItem { Label("Теги", systemImage: "tag") }
                .tag(2)
            EpicsView()
                .frame(minHeight: 1)
                .tabItem { Label("Эпики", systemImage: "square.stack.3d.up") }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(TaskStore(context: PersistenceController.shared.container.viewContext))
}
