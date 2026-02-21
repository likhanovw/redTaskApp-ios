import SwiftUI
import CoreData

struct CompletedTasksView: View {
    @EnvironmentObject private var taskStore: TaskStore

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskEntity.completedAt, ascending: false)],
        predicate: NSPredicate(format: "isCompleted == YES")
    ) private var completedTasks: FetchedResults<TaskEntity>

    var body: some View {
        NavigationStack {
            Group {
                if completedTasks.isEmpty {
                    ContentUnavailableView(
                        "Нет завершённых задач",
                        systemImage: "checkmark.circle",
                        description: Text("Выполненные задачи появятся здесь")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(completedTasks) { task in
                            completedTaskRow(task)
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            taskStore.restoreTask(task)
                                        }
                                    } label: {
                                        Label("Восстановить", systemImage: "arrow.uturn.backward")
                                    }
                                    .tint(.blue)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            taskStore.deleteTask(task)
                                        }
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Архив")
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        }
    }

    private func completedTaskRow(_ task: TaskEntity) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.title)
                .font(.headline)
                .foregroundStyle(.primary)
            if let completedAt = task.completedAt {
                Text("Завершено: \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    CompletedTasksView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(TaskStore(context: PersistenceController.shared.container.viewContext))
}
