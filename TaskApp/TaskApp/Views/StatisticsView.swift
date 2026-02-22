import SwiftUI
import CoreData

struct StatisticsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var taskStore: TaskStore

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \EpicEntity.order, ascending: false)]
    ) private var epics: FetchedResults<EpicEntity>

    @State private var expandedEpicId: UUID?
    @State private var selectedTagIdsByEpic: [UUID: Set<UUID>] = [:]

    /// Все задачи эпика (активные и завершённые) по предикату — для корректного подсчёта времени.
    private func tasksForEpic(_ epic: EpicEntity) -> [TaskEntity] {
        let request = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "epic == %@", epic)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.order, ascending: true)]
        return (try? viewContext.fetch(request)) ?? []
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(epics) { epic in
                    epicRow(epic)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Статистика")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func epicRow(_ epic: EpicEntity) -> some View {
        let tasks = tasksForEpic(epic)
        let savedTime = tasks.reduce(0) { $0 + $1.totalTimeSpent }
        let currentSession = (taskStore.activeTimerTaskId.flatMap { id in tasks.contains(where: { $0.id == id }) ? taskStore.currentSessionSeconds : nil } ?? 0)
        let totalTime = savedTime + currentSession
        let selectedTags = selectedTagIdsByEpic[epic.id] ?? []
        let binding = Binding(
            get: { expandedEpicId == epic.id },
            set: { newValue in
                if newValue {
                    expandedEpicId = epic.id
                } else {
                    expandedEpicId = nil
                    selectedTagIdsByEpic.removeValue(forKey: epic.id)
                }
            }
        )

        return DisclosureGroup(isExpanded: binding) {
            expandedContent(epic: epic, tasks: tasks, selectedTagIds: selectedTags)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text("#\(epic.name)")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Общее время: \(formatTime(totalTime))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private func expandedContent(epic: EpicEntity, tasks: [TaskEntity], selectedTagIds: Set<UUID>) -> some View {
        let uniqueTags = uniqueTagsFromTasks(tasks)
        let filteredTasks = filteredTasksByTags(tasks, selectedTagIds: selectedTagIds)
        let savedDisplayedTime = filteredTasks.reduce(0) { $0 + $1.totalTimeSpent }
        let currentSession = (taskStore.activeTimerTaskId.flatMap { id in filteredTasks.contains(where: { $0.id == id }) ? taskStore.currentSessionSeconds : nil } ?? 0)
        let displayedTime = savedDisplayedTime + currentSession

        return VStack(alignment: .leading, spacing: 12) {
            if !uniqueTags.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Фильтр по тегам")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(uniqueTags) { tag in
                                let isSelected = selectedTagIds.contains(tag.id)
                                Button {
                                    var next = selectedTagIdsByEpic[epic.id] ?? []
                                    if isSelected {
                                        next.remove(tag.id)
                                    } else {
                                        next.insert(tag.id)
                                    }
                                    selectedTagIdsByEpic[epic.id] = next.isEmpty ? nil : next
                                } label: {
                                    HStack(spacing: 4) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(TagPalette.color(for: Int(tag.colorIndex), colorScheme: colorScheme))
                                            .frame(width: 10, height: 10)
                                        Text(tag.name)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? Color(.systemFill) : Color(.tertiarySystemFill))
                                    .foregroundStyle(isSelected ? .primary : .secondary)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    if !selectedTagIds.isEmpty {
                        Text("Время по выбранным тегам: \(formatTime(displayedTime))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Задачи (\(filteredTasks.count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(filteredTasks) { task in
                    let taskTime = task.totalTimeSpent + (taskStore.activeTimerTaskId == task.id ? taskStore.currentSessionSeconds : 0)
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text(task.title)
                                .font(.subheadline)
                                .lineLimit(1)
                            if !task.tagsArray.isEmpty {
                                HStack(spacing: 3) {
                                    ForEach(task.tagsArray) { tag in
                                        Circle()
                                            .fill(TagPalette.color(for: Int(tag.colorIndex), colorScheme: colorScheme))
                                            .frame(width: 5, height: 5)
                                    }
                                }
                            }
                        }
                        Spacer(minLength: 8)
                        Text(formatTime(taskTime))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.top, 4)
    }

    private func uniqueTagsFromTasks(_ tasks: [TaskEntity]) -> [TagEntity] {
        var seen: Set<UUID> = []
        var result: [TagEntity] = []
        for task in tasks {
            for tag in task.tagsArray where seen.insert(tag.id).inserted {
                result.append(tag)
            }
        }
        return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func filteredTasksByTags(_ tasks: [TaskEntity], selectedTagIds: Set<UUID>) -> [TaskEntity] {
        guard !selectedTagIds.isEmpty else { return tasks }
        return tasks.filter { task in
            let taskTagIds = Set(task.tagsArray.map(\.id))
            return selectedTagIds.isSubset(of: taskTagIds)
        }
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

#Preview {
    StatisticsView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(TaskStore(context: PersistenceController.shared.container.viewContext))
}
