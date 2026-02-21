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

extension EpicEntity: Identifiable {}
