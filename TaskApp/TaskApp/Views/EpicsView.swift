import SwiftUI
import CoreData

struct EpicsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var taskStore: TaskStore

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \EpicEntity.order, ascending: false), NSSortDescriptor(keyPath: \EpicEntity.name, ascending: false)]
    ) private var epics: FetchedResults<EpicEntity>

    @State private var showingAddEpic = false
    @State private var newEpicName = ""
    @State private var epicToEdit: EpicEntity?

    var body: some View {
        NavigationStack {
            Group {
                if epics.isEmpty {
                    ContentUnavailableView(
                        "Нет эпиков",
                        systemImage: "square.stack.3d.up",
                        description: Text("Создайте эпик и привяжите его к задачам в деталях задачи")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(epics) { epic in
                            HStack(spacing: 12) {
                                Text("#\(epic.name)")
                                    .font(.body)
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                            .onTapGesture { epicToEdit = epic }
                        }
                        .onDelete(perform: deleteEpics)
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await MainActor.run {
                            viewContext.refreshAllObjects()
                        }
                    }
                }
            }
            .navigationTitle("Эпики")
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        newEpicName = ""
                        showingAddEpic = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEpic) {
                addEpicSheet
            }
            .sheet(item: $epicToEdit) { epic in
                EpicDetailSheet(epic: epic) {
                    epicToEdit = nil
                }
                .environmentObject(taskStore)
            }
        }
    }

    private var addEpicSheet: some View {
        NavigationStack {
            Form {
                TextField("Название эпика", text: $newEpicName)
            }
            .navigationTitle("Новый эпик")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        showingAddEpic = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        addEpic()
                    }
                    .disabled(newEpicName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func addEpic() {
        let name = newEpicName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            _ = taskStore.createEpic(name: name)
        }
        showingAddEpic = false
    }

    private func deleteEpics(at offsets: IndexSet) {
        withAnimation(.easeInOut(duration: 0.2)) {
            for index in offsets where index < epics.count {
                taskStore.deleteEpic(epics[index])
            }
        }
    }
}

// MARK: - Редактирование эпика и выбор задач (sheet)

struct EpicDetailSheet: View {
    let epic: EpicEntity
    let onDismiss: () -> Void

    @EnvironmentObject private var taskStore: TaskStore
    @State private var name: String = ""
    /// Локальный выбор задач; сохраняется в Core Data только по «Готово».
    @State private var selectedTaskIds: Set<UUID> = []

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskEntity.order, ascending: true)],
        predicate: NSPredicate(format: "isCompleted == NO")
    ) private var activeTasks: FetchedResults<TaskEntity>

    var body: some View {
        NavigationStack {
            Form {
                Section("Название эпика") {
                    TextField("Название", text: $name)
                }
                Section("Задачи в эпике") {
                    if activeTasks.isEmpty {
                        Text("Нет активных задач")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(activeTasks) { task in
                            let isInEpic = selectedTaskIds.contains(task.id)
                            Button {
                                if selectedTaskIds.contains(task.id) {
                                    selectedTaskIds.remove(task.id)
                                } else {
                                    selectedTaskIds.insert(task.id)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Text(task.title)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if isInEpic {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Эпик")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        saveAndDismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                name = epic.name
                selectedTaskIds = Set(activeTasks.filter { $0.epic?.id == epic.id }.map(\.id))
            }
        }
    }

    private func saveAndDismiss() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        taskStore.updateEpic(epic, name: trimmed)
        let epicId = epic.id
        for task in activeTasks {
            let selected = selectedTaskIds.contains(task.id)
            let wasInThisEpic = task.epic?.id == epicId
            if selected {
                taskStore.setTaskEpic(task, epic: epic)
            } else if wasInThisEpic {
                taskStore.setTaskEpic(task, epic: nil)
            }
            // Иначе задача в другом эпике — не трогаем
        }
        onDismiss()
    }
}

#Preview {
    EpicsView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(TaskStore(context: PersistenceController.shared.container.viewContext))
}
