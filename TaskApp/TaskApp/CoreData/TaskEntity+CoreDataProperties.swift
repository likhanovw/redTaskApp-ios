import Foundation
import CoreData

extension TaskEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskEntity> {
        NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var taskDescription: String?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var order: Int32
    @NSManaged public var totalTimeSpent: Double
    @NSManaged public var createdAt: Date
    @NSManaged public var completedAt: Date?
    @NSManaged public var checklistItems: NSSet?
    @NSManaged public var tags: NSSet?
}

extension TaskEntity: Identifiable {
    public var tagsArray: [TagEntity] {
        let set = tags as? Set<TagEntity> ?? []
        return set.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public var checklistItemsArray: [ChecklistItemEntity] {
        let set = checklistItems as? Set<ChecklistItemEntity> ?? []
        return set.sorted { $0.order < $1.order }
    }
}
