import SwiftUI
import CoreData

struct CompletedTasksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var taskStore: TaskStore

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskEntity.completedAt, ascending: false)],
        predicate: NSPredicate(format: "isCompleted == YES")
    ) private var completedTasks: FetchedResults<TaskEntity>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \EpicEntity.order, ascending: true), NSSortDescriptor(keyPath: \EpicEntity.name, ascending: true)]
    ) private var allEpics: FetchedResults<EpicEntity>

    enum ArchiveEpicFilter: Hashable {
        case all
        case withoutEpic
        case epic(UUID)

        var isAll: Bool { if case .all = self { return true }; return false }
        var isWithoutEpic: Bool { if case .withoutEpic = self { return true }; return false }
        func isEpic(_ id: UUID) -> Bool { if case .epic(let eid) = self { return eid == id }; return false }
    }
    @State private var selectedEpicFilter: ArchiveEpicFilter = .all

    private var filteredCompletedTasks: [TaskEntity] {
        switch selectedEpicFilter {
        case .all:
            return Array(completedTasks)
        case .withoutEpic:
            return completedTasks.filter { $0.epic == nil }
        case .epic(let epicId):
            return completedTasks.filter { $0.epic?.id == epicId }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                archiveFilterBar
                Group {
                    if filteredCompletedTasks.isEmpty {
                        ContentUnavailableView(
                            "Нет завершённых задач",
                            systemImage: "checkmark.circle",
                            description: Text("Выполненные задачи появятся здесь")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filteredCompletedTasks) { task in
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
                        .refreshable {
                            await MainActor.run {
                                viewContext.refreshAllObjects()
                            }
                        }
                    }
                }
                .frame(minHeight: 1)
            }
            .navigationTitle("Архив")
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        }
    }

    private var archiveFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    selectedEpicFilter = .all
                } label: {
                    Text("Все")
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selectedEpicFilter.isAll ? Color(.systemFill) : Color(.tertiarySystemFill))
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
                        .background(selectedEpicFilter.isWithoutEpic ? Color(.systemFill) : Color(.tertiarySystemFill))
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
                            .background(isSelected ? Color(.systemFill) : Color(.tertiarySystemFill))
                            .foregroundStyle(isSelected ? .primary : .secondary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }

    private func completedTaskRow(_ task: TaskEntity) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let epic = task.epic {
                Text("#\(epic.name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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
