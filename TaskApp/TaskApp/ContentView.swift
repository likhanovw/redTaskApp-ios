import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        TabView {
            TaskListView()
                .frame(minHeight: 1)
                .tabItem { Label("Задачи", systemImage: "list.bullet") }
            CompletedTasksView()
                .frame(minHeight: 1)
                .tabItem { Label("Архив", systemImage: "checkmark.circle.fill") }
            TagsView()
                .frame(minHeight: 1)
                .tabItem { Label("Теги", systemImage: "tag") }
            EpicsView()
                .frame(minHeight: 1)
                .tabItem { Label("Эпики", systemImage: "square.stack.3d.up") }
            StatisticsView()
                .tabItem { Label("Статистика", systemImage: "chart.bar.doc.horizontal") }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(TaskStore(context: PersistenceController.shared.container.viewContext))
}
