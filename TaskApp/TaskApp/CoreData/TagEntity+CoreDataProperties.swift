import Foundation
import CoreData

extension TagEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TagEntity> {
        NSFetchRequest<TagEntity>(entityName: "TagEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var colorIndex: Int32
    @NSManaged public var order: Int32
    @NSManaged public var tasks: NSSet?
}

extension TagEntity: Identifiable {}
