import SwiftUI
import CoreData

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var taskStore: TaskStore

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskEntity.order, ascending: true)],
        predicate: NSPredicate(format: "isCompleted == NO")
    ) private var tasks: FetchedResults<TaskEntity>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TagEntity.name, ascending: true)]
    ) private var allTags: FetchedResults<TagEntity>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \EpicEntity.order, ascending: true), NSSortDescriptor(keyPath: \EpicEntity.name, ascending: true)]
    ) private var allEpics: FetchedResults<EpicEntity>

    enum EpicFilter: Hashable {
        case all
        case withoutEpic
        case epic(UUID)

        var isAll: Bool { if case .all = self { return true }; return false }
        var isWithoutEpic: Bool { if case .withoutEpic = self { return true }; return false }
        func isEpic(_ id: UUID) -> Bool { if case .epic(let eid) = self { return eid == id }; return false }
    }

    @State private var showingAddTask = false
    @State private var selectedEpicFilter: EpicFilter = .all
    @State private var selectedFilterTagIds: Set<UUID> = []
    @State private var newTaskTitle = ""
    @State private var newTaskDescription = ""
    @State private var selectedTask: TaskEntity?
    /// При возврате с экрана детали принудительно перерисовываем строки (теги).
    @State private var listRefreshId = 0
    @State private var lastOpenedTaskId: UUID?
    @State private var scrollToTaskId: UUID?

    private var filteredTasks: [TaskEntity] {
        var result: [TaskEntity] = Array(tasks)
        switch selectedEpicFilter {
        case .all:
            break
        case .withoutEpic:
            result = result.filter { $0.epic == nil }
        case .epic(let epicId):
            result = result.filter { $0.epic?.id == epicId }
        }
        if !selectedFilterTagIds.isEmpty {
            let idSet = selectedFilterTagIds
            result = result.filter { idSet.isSubset(of: Set($0.tagsArray.map(\.id))) }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                epicFilterBar
                tagFilterBar
                listContent
            }
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
                .toolbarBackground(Color(.systemBackground), for: .navigationBar)
                .sheet(isPresented: $showingAddTask) {
                    addTaskSheet
                }
                .navigationDestination(item: $selectedTask) { task in
                    TaskDetailView(task: task)
                }
        }
        .onChange(of: taskStore.detailDismissedCounter) { _, _ in
            listRefreshId += 1
            if let id = lastOpenedTaskId {
                scrollToTaskId = id
                lastOpenedTaskId = nil
            }
        }
    }

    private var epicFilterBar: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        selectedEpicFilter = .all
                    } label: {
                        Text("Все")
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedEpicFilter.isAll ? Color.accentColor.opacity(0.25) : Color(.tertiarySystemFill))
                            .foregroundStyle(selectedEpicFilter.isAll ? .primary : .secondary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    Button {
                        selectedEpicFilter = .withoutEpic
                    } label: {
                        Text("Без эпика")
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedEpicFilter.isWithoutEpic ? Color.accentColor.opacity(0.25) : Color(.tertiarySystemFill))
                            .foregroundStyle(selectedEpicFilter.isWithoutEpic ? .primary : .secondary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    ForEach(allEpics) { epic in
                        let isSelected = selectedEpicFilter.isEpic(epic.id)
                        Button {
                            selectedEpicFilter = isSelected ? .all : .epic(epic.id)
                        } label: {
                            Text("#\(epic.name)")
                                .font(.subheadline)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(isSelected ? Color.accentColor.opacity(0.25) : Color(.tertiarySystemFill))
                                .foregroundStyle(isSelected ? .primary : .secondary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
            if selectedEpicFilter != .all {
                Button {
                    selectedEpicFilter = .all
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 12)
            }
        }
        .background(Color(.systemBackground))
    }

    private var tagFilterBar: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(allTags) { tag in
                        let isSelected = selectedFilterTagIds.contains(tag.id)
                        Button {
                            if isSelected {
                                selectedFilterTagIds.remove(tag.id)
                            } else {
                                selectedFilterTagIds.insert(tag.id)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(TagPalette.color(for: Int(tag.colorIndex), colorScheme: colorScheme))
                                    .frame(width: 12, height: 12)
                                Text(tag.name)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.accentColor.opacity(0.25) : Color(.tertiarySystemFill))
                            .foregroundStyle(isSelected ? .primary : .secondary)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
            if !selectedFilterTagIds.isEmpty {
                Button {
                    selectedFilterTagIds.removeAll()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 12)
            }
        }
        .background(Color(.systemBackground))
    }

    private var listContent: some View {
        Group {
            if filteredTasks.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    List {
                        ForEach(filteredTasks) { task in
                            taskRow(task)
                                .id(task.id)
                                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    lastOpenedTaskId = task.id
                                    selectedTask = task
                                }
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
                        .onMove(perform: moveFilteredTasks)
                        .id(listRefreshId)
                    }
                    .listStyle(.plain)
                    .onChange(of: scrollToTaskId) { _, newId in
                        guard let id = newId else { return }
                        DispatchQueue.main.async {
                            proxy.scrollTo(id, anchor: .center)
                            scrollToTaskId = nil
                        }
                    }
                }
            }
        }
        .frame(minHeight: 1)
    }

    private func taskRow(_ task: TaskEntity) -> some View {
        let items = task.checklistItemsArray
        let completedCount = items.filter(\.isCompleted).count
        let totalCount = items.count
        let isTimerActive = taskStore.activeTimerTaskId == task.id
        let totalSeconds = task.totalTimeSpent + (isTimerActive ? taskStore.currentSessionSeconds : 0)

        return HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if let epic = task.epic {
                    Text("#\(epic.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !task.tagsArray.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(task.tagsArray) { tag in
                            Text(tag.name)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(TagPalette.color(for: Int(tag.colorIndex), colorScheme: colorScheme))
                                .foregroundStyle(.primary)
                                .clipShape(Capsule())
                        }
                    }
                    .frame(height: 28)
                }
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

            Button {
                if isTimerActive {
                    taskStore.stopTimer()
                } else {
                    taskStore.startTimer(for: task)
                }
            } label: {
                Image(systemName: isTimerActive ? "stop.fill" : "play.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        isTimerActive
                            ? Color.red.opacity(colorScheme == .dark ? 0.65 : 0.32)
                            : (colorScheme == .dark ? Color(.secondarySystemFill) : Color.gray.opacity(0.28))
                    )
                    .clipShape(Circle())
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        Group {
            if selectedFilterTagIds.isEmpty {
                ContentUnavailableView(
                    "Нет активных задач",
                    systemImage: "tray",
                    description: Text("Нажмите + чтобы добавить задачу")
                )
            } else {
                ContentUnavailableView(
                    "Нет задач с выбранными тегами",
                    systemImage: "tag",
                    description: Text("Сбросьте фильтр или выберите другие теги")
                )
            }
        }
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

    private func moveFilteredTasks(from source: IndexSet, to destination: Int) {
        taskStore.moveTasks(from: source, to: destination, in: filteredTasks)
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
