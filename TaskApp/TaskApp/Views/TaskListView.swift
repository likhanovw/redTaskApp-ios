import SwiftUI
import CoreData

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var taskStore: TaskStore

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskEntity.order, ascending: true)],
        predicate: NSPredicate(format: "isCompleted == NO")
    ) private var tasks: FetchedResults<TaskEntity>

    @State private var showingAddTask = false
    @State private var newTaskTitle = ""
    @State private var newTaskDescription = ""
    @State private var selectedTask: TaskEntity?

    var body: some View {
        NavigationStack {
            listContent
                .navigationTitle("Задачи")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            newTaskTitle = ""
                            newTaskDescription = ""
                            showingAddTask = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAddTask) {
                    addTaskSheet
                }
                .navigationDestination(item: $selectedTask) { task in
                    TaskDetailView(task: task)
                }
        }
    }

    private var listContent: some View {
        Group {
            if tasks.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(tasks) { task in
                        taskRow(task)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTask = task
                            }
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        taskStore.markTaskCompleted(task)
                                    }
                                } label: {
                                    Label("Выполнена", systemImage: "checkmark.circle.fill")
                                }
                                .tint(.green)
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
                    .onMove(perform: moveTasks)
                }
                .listStyle(.plain)
            }
        }
    }

    private func taskRow(_ task: TaskEntity) -> some View {
        let items = task.checklistItemsArray
        let completedCount = items.filter(\.isCompleted).count
        let totalCount = items.count
        let isTimerActive = taskStore.activeTimerTaskId == task.id
        let totalSeconds = task.totalTimeSpent + (isTimerActive ? taskStore.currentSessionSeconds : 0)

        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                if totalCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "checklist")
                            .font(.caption)
                        Text("\(completedCount)/\(totalCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if isTimerActive {
                    Text("Текущая сессия: \(formatTime(taskStore.currentSessionSeconds))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if totalSeconds > 0 {
                    Text("Общее время: \(formatTime(totalSeconds))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Нет активных задач",
            systemImage: "tray",
            description: Text("Нажмите + чтобы добавить задачу")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var addTaskSheet: some View {
        NavigationStack {
            Form {
                TextField("Название", text: $newTaskTitle)
                TextField("Описание (опционально)", text: $newTaskDescription, axis: .vertical)
                    .lineLimit(3...6)
            }
            .navigationTitle("Новая задача")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        showingAddTask = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        addTask()
                    }
                    .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let desc = newTaskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        withAnimation(.easeInOut(duration: 0.25)) {
            _ = taskStore.createTask(title: title, description: desc.isEmpty ? nil : desc)
        }
        showingAddTask = false
    }

    private func moveTasks(from source: IndexSet, to destination: Int) {
        taskStore.moveTasks(from: source, to: destination, in: Array(tasks))
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        if h > 0 {
            return "\(h) ч \(m) мин"
        } else if m > 0 {
            return "\(m) мин"
        } else {
            return "\(Int(seconds)) сек"
        }
    }
}

// TaskEntity уже соответствует Hashable через NSObject — расширение убрано, чтобы не конфликтовать с hash(into:).

#Preview {
    TaskListView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(TaskStore(context: PersistenceController.shared.container.viewContext))
}
