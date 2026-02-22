import Foundation
import CoreData
import SwiftUI
import UserNotifications
import Combine

/// ViewModel: бизнес-логика задач и чеклиста.
final class TaskStore: ObservableObject {
    private let viewContext: NSManagedObjectContext
    private let timerNotificationThreshold: TimeInterval = 2 * 60 * 60 // 2 часа

    @Published var activeTimerTaskId: UUID?
    @Published var currentSessionSeconds: TimeInterval = 0
    /// Увеличивается при закрытии экрана детали задачи; список подписан и обновляет теги.
    @Published var detailDismissedCounter: Int = 0
    private var sessionStartDate: Date?
    private var timerSubscription: AnyCancellable?

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
    }

    func createTask(title: String, description: String? = nil) -> TaskEntity {
        let task = TaskEntity(context: viewContext)
        task.id = UUID()
        task.title = title
        task.taskDescription = description
        task.isCompleted = false
        task.order = nextOrderForActiveTasks()
        task.totalTimeSpent = 0
        task.createdAt = Date()
        task.completedAt = nil
        save()
        return task
    }

    func updateTask(_ task: TaskEntity, title: String?, taskDescription: String?) {
        if let title = title { task.title = title }
        task.taskDescription = taskDescription
        save()
    }

    func deleteTask(_ task: TaskEntity) {
        if activeTimerTaskId == task.id {
            stopTimer()
        }
        viewContext.delete(task)
        save()
    }

    func markTaskCompleted(_ task: TaskEntity) {
        task.isCompleted = true
        task.completedAt = Date()
        if activeTimerTaskId == task.id {
            stopTimer()
        }
        save()
    }

    func restoreTask(_ task: TaskEntity) {
        task.isCompleted = false
        task.completedAt = nil
        task.order = nextOrderForActiveTasks()
        save()
    }

    func moveTasks(from source: IndexSet, to destination: Int, in tasks: [TaskEntity]) {
        var ordered = tasks
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, task) in ordered.enumerated() {
            task.order = Int32(index)
        }
        save()
    }

    private func nextOrderForActiveTasks() -> Int32 {
        let request = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.order, ascending: false)]
        request.fetchLimit = 1
        guard let last = try? viewContext.fetch(request).first else { return 0 }
        return last.order + 1
    }

    func addChecklistItem(to task: TaskEntity, title: String) {
        addChecklistItem(taskObjectID: task.objectID, title: title)
    }

    func addChecklistItem(taskObjectID: NSManagedObjectID, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let task = try? viewContext.existingObject(with: taskObjectID) as? TaskEntity else { return }
        let item = ChecklistItemEntity(context: viewContext)
        item.id = UUID()
        item.title = trimmed
        item.isCompleted = false
        item.order = Int32(task.checklistItemsArray.count)
        item.task = task
        save()
    }

    func toggleChecklistItem(_ item: ChecklistItemEntity) {
        item.isCompleted.toggle()
        save()
        item.task.objectWillChange.send()
    }

    /// Удаление по id и objectID задачи. Список оставшихся собираем до delete, чтобы не опираться на связь после удаления.
    func deleteChecklistItem(byId itemId: UUID, taskObjectID: NSManagedObjectID) {
        guard let task = try? viewContext.existingObject(with: taskObjectID) as? TaskEntity else { return }
        let request = ChecklistItemEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)
        request.fetchLimit = 1
        guard let item = try? viewContext.fetch(request).first as? ChecklistItemEntity else { return }
        guard item.task.objectID == taskObjectID else { return }
        let toDeleteObjectID = item.objectID
        let remainingOrder: [(NSManagedObjectID, Int)] = task.checklistItemsArray
            .filter { $0.objectID != toDeleteObjectID }
            .enumerated()
            .map { ($0.element.objectID, $0.offset) }
        viewContext.delete(item)
        for (oid, index) in remainingOrder {
            if let obj = try? viewContext.existingObject(with: oid) as? ChecklistItemEntity {
                obj.order = Int32(index)
            }
        }
        save()
    }

    func deleteChecklistItem(_ item: ChecklistItemEntity) {
        deleteChecklistItem(byId: item.id, taskObjectID: item.task.objectID)
    }

    func moveChecklistItems(from source: IndexSet, to destination: Int, in task: TaskEntity) {
        var items = task.checklistItemsArray
        items.move(fromOffsets: source, toOffset: destination)
        for (index, item) in items.enumerated() {
            item.order = Int32(index)
        }
        save()
    }

    func startTimer(for task: TaskEntity) {
        if activeTimerTaskId == task.id { return }
        stopTimer()
        activeTimerTaskId = task.id
        sessionStartDate = Date()
        currentSessionSeconds = 0
        scheduleTimerReminderIfNeeded()
        startTimerTick()
    }

    func stopTimer() {
        guard let taskId = activeTimerTaskId else { return }
        timerSubscription?.cancel()
        timerSubscription = nil
        if let start = sessionStartDate {
            let task = task(by: taskId)
            task?.totalTimeSpent += currentSessionSeconds
            save()
        }
        activeTimerTaskId = nil
        sessionStartDate = nil
        currentSessionSeconds = 0
        cancelTimerReminder()
    }

    private func startTimerTick() {
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let start = self.sessionStartDate else { return }
                self.currentSessionSeconds = Date().timeIntervalSince(start)
            }
    }

    func task(by id: UUID) -> TaskEntity? {
        let request = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }

    private func scheduleTimerReminderIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        let content = UNMutableNotificationContent()
        content.title = "Таймер"
        content.body = "Таймер работает уже больше 2 часов. Возможно, стоит сделать перерыв."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timerNotificationThreshold, repeats: false)
        let request = UNNotificationRequest(identifier: "timer.reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelTimerReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timer.reminder"])
    }

    // MARK: - Теги

    func createTag(name: String, colorIndex: Int32) -> TagEntity {
        let tag = TagEntity(context: viewContext)
        tag.id = UUID()
        tag.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        tag.colorIndex = max(0, min(Int32(TagPalette.count - 1), colorIndex))
        tag.order = nextOrderForTags()
        save()
        return tag
    }

    private func nextOrderForTags() -> Int32 {
        let request = TagEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TagEntity.order, ascending: false)]
        request.fetchLimit = 1
        guard let last = try? viewContext.fetch(request).first else { return 0 }
        return last.order + 1
    }

    func updateTag(_ tag: TagEntity, name: String?, colorIndex: Int32?) {
        if let name = name {
            tag.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let colorIndex = colorIndex {
            tag.colorIndex = max(0, min(Int32(TagPalette.count - 1), colorIndex))
        }
        save()
    }

    func deleteTag(_ tag: TagEntity) {
        viewContext.delete(tag)
        save()
    }

    func allTags() -> [TagEntity] {
        let request = TagEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TagEntity.order, ascending: false)]
        return (try? viewContext.fetch(request)) ?? []
    }

    func addTag(_ tag: TagEntity, to task: TaskEntity) {
        guard let taskInContext = try? viewContext.existingObject(with: task.objectID) as? TaskEntity else { return }
        guard let tagInContext = try? viewContext.existingObject(with: tag.objectID) as? TagEntity else { return }
        taskInContext.mutableSetValue(forKey: "tags").add(tagInContext)
        save()
    }

    func removeTag(_ tag: TagEntity, from task: TaskEntity) {
        guard let taskInContext = try? viewContext.existingObject(with: task.objectID) as? TaskEntity else { return }
        guard let tagInContext = try? viewContext.existingObject(with: tag.objectID) as? TagEntity else { return }
        taskInContext.mutableSetValue(forKey: "tags").remove(tagInContext)
        save()
    }

    func toggleTag(_ tag: TagEntity, on task: TaskEntity) {
        let tags = task.tagsArray
        if tags.contains(where: { $0.id == tag.id }) {
            removeTag(tag, from: task)
        } else {
            addTag(tag, to: task)
        }
    }

    // MARK: - Эпики

    func createEpic(name: String) -> EpicEntity {
        let epic = EpicEntity(context: viewContext)
        epic.id = UUID()
        epic.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        epic.order = nextOrderForEpics()
        save()
        return epic
    }

    func updateEpic(_ epic: EpicEntity, name: String) {
        epic.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        save()
    }

    func deleteEpic(_ epic: EpicEntity) {
        viewContext.delete(epic)
        save()
    }

    func setTaskEpic(_ task: TaskEntity, epic: EpicEntity?) {
        guard let taskInContext = try? viewContext.existingObject(with: task.objectID) as? TaskEntity else { return }
        if let epic = epic, let epicInContext = try? viewContext.existingObject(with: epic.objectID) as? EpicEntity {
            taskInContext.epic = epicInContext
        } else {
            taskInContext.epic = nil
        }
        save()
    }

    private func nextOrderForEpics() -> Int32 {
        let request = EpicEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \EpicEntity.order, ascending: false)]
        request.fetchLimit = 1
        guard let last = try? viewContext.fetch(request).first else { return 0 }
        return last.order + 1
    }

    func notifyDetailDismissed() {
        detailDismissedCounter += 1
    }

    private func save() {
        guard viewContext.hasChanges else { return }
        try? viewContext.save()
    }
}
