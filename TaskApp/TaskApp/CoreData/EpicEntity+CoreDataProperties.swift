import Foundation
import CoreData

extension EpicEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<EpicEntity> {
        NSFetchRequest<EpicEntity>(entityName: "EpicEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var order: Int32
    @NSManaged public var tasks: NSSet?
}

extension EpicEntity: Identifiable {
    public var tasksArray: [TaskEntity] {
        let set = tasks as? Set<TaskEntity> ?? []
        return set.sorted { $0.order < $1.order }
    }
}
