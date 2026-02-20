import Foundation
import CoreData

extension ChecklistItemEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChecklistItemEntity> {
        NSFetchRequest<ChecklistItemEntity>(entityName: "ChecklistItemEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var isCompleted: Bool
    @NSManaged public var order: Int32
    @NSManaged public var task: TaskEntity
}

extension ChecklistItemEntity: Identifiable {}
