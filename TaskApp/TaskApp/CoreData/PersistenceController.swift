import CoreData

/// Программно созданная Core Data модель и контейнер.
final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TaskAppModel", managedObjectModel: Self.buildModel())
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            container.persistentStoreDescriptions.first?.shouldMigrateStoreAutomatically = true
            container.persistentStoreDescriptions.first?.shouldInferMappingModelAutomatically = true
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data load error: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    static func buildModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // ——— TaskEntity ———
        let taskEntity = NSEntityDescription()
        taskEntity.name = "TaskEntity"
        taskEntity.managedObjectClassName = NSStringFromClass(TaskEntity.self)

        let taskId = NSAttributeDescription()
        taskId.name = "id"
        taskId.attributeType = .UUIDAttributeType
        taskId.isOptional = false

        let taskTitle = NSAttributeDescription()
        taskTitle.name = "title"
        taskTitle.attributeType = .stringAttributeType
        taskTitle.isOptional = false

        let taskTaskDescription = NSAttributeDescription()
        taskTaskDescription.name = "taskDescription"
        taskTaskDescription.attributeType = .stringAttributeType
        taskTaskDescription.isOptional = true

        let taskIsCompleted = NSAttributeDescription()
        taskIsCompleted.name = "isCompleted"
        taskIsCompleted.attributeType = .booleanAttributeType
        taskIsCompleted.defaultValue = false

        let taskOrder = NSAttributeDescription()
        taskOrder.name = "order"
        taskOrder.attributeType = .integer32AttributeType
        taskOrder.defaultValue = 0

        let taskTotalTimeSpent = NSAttributeDescription()
        taskTotalTimeSpent.name = "totalTimeSpent"
        taskTotalTimeSpent.attributeType = .doubleAttributeType
        taskTotalTimeSpent.defaultValue = 0

        let taskCreatedAt = NSAttributeDescription()
        taskCreatedAt.name = "createdAt"
        taskCreatedAt.attributeType = .dateAttributeType
        taskCreatedAt.isOptional = false

        let taskCompletedAt = NSAttributeDescription()
        taskCompletedAt.name = "completedAt"
        taskCompletedAt.attributeType = .dateAttributeType
        taskCompletedAt.isOptional = true

        taskEntity.properties = [taskId, taskTitle, taskTaskDescription, taskIsCompleted, taskOrder, taskTotalTimeSpent, taskCreatedAt, taskCompletedAt]

        // ——— TagEntity ———
        let tagEntity = NSEntityDescription()
        tagEntity.name = "TagEntity"
        tagEntity.managedObjectClassName = NSStringFromClass(TagEntity.self)

        let tagId = NSAttributeDescription()
        tagId.name = "id"
        tagId.attributeType = .UUIDAttributeType
        tagId.isOptional = false

        let tagName = NSAttributeDescription()
        tagName.name = "name"
        tagName.attributeType = .stringAttributeType
        tagName.isOptional = false

        let tagColorIndex = NSAttributeDescription()
        tagColorIndex.name = "colorIndex"
        tagColorIndex.attributeType = .integer32AttributeType
        tagColorIndex.defaultValue = 0

        let tagOrder = NSAttributeDescription()
        tagOrder.name = "order"
        tagOrder.attributeType = .integer32AttributeType
        tagOrder.defaultValue = 0

        // Связь Task ↔ Tag (многие-ко-многим)
        let taskToTags = NSRelationshipDescription()
        taskToTags.name = "tags"
        taskToTags.destinationEntity = tagEntity
        taskToTags.isOptional = true
        taskToTags.deleteRule = .nullifyDeleteRule

        let tagToTasks = NSRelationshipDescription()
        tagToTasks.name = "tasks"
        tagToTasks.destinationEntity = taskEntity
        tagToTasks.isOptional = true
        tagToTasks.deleteRule = .nullifyDeleteRule

        taskToTags.inverseRelationship = tagToTasks
        tagToTasks.inverseRelationship = taskToTags

        taskEntity.properties.append(taskToTags)
        tagEntity.properties = [tagId, tagName, tagColorIndex, tagOrder, tagToTasks]

        // ——— EpicEntity ———
        let epicEntity = NSEntityDescription()
        epicEntity.name = "EpicEntity"
        epicEntity.managedObjectClassName = NSStringFromClass(EpicEntity.self)

        let epicId = NSAttributeDescription()
        epicId.name = "id"
        epicId.attributeType = .UUIDAttributeType
        epicId.isOptional = false

        let epicName = NSAttributeDescription()
        epicName.name = "name"
        epicName.attributeType = .stringAttributeType
        epicName.isOptional = false

        let epicOrder = NSAttributeDescription()
        epicOrder.name = "order"
        epicOrder.attributeType = .integer32AttributeType
        epicOrder.defaultValue = 0

        let taskToEpic = NSRelationshipDescription()
        taskToEpic.name = "epic"
        taskToEpic.destinationEntity = epicEntity
        taskToEpic.isOptional = true
        taskToEpic.maxCount = 1
        taskToEpic.deleteRule = .nullifyDeleteRule

        let epicToTasks = NSRelationshipDescription()
        epicToTasks.name = "tasks"
        epicToTasks.destinationEntity = taskEntity
        epicToTasks.isOptional = true
        epicToTasks.deleteRule = .nullifyDeleteRule

        taskToEpic.inverseRelationship = epicToTasks
        epicToTasks.inverseRelationship = taskToEpic

        taskEntity.properties.append(taskToEpic)
        epicEntity.properties = [epicId, epicName, epicOrder, epicToTasks]

        // ——— ChecklistItemEntity ———
        let itemEntity = NSEntityDescription()
        itemEntity.name = "ChecklistItemEntity"
        itemEntity.managedObjectClassName = NSStringFromClass(ChecklistItemEntity.self)

        let itemId = NSAttributeDescription()
        itemId.name = "id"
        itemId.attributeType = .UUIDAttributeType
        itemId.isOptional = false

        let itemTitle = NSAttributeDescription()
        itemTitle.name = "title"
        itemTitle.attributeType = .stringAttributeType
        itemTitle.isOptional = false

        let itemIsCompleted = NSAttributeDescription()
        itemIsCompleted.name = "isCompleted"
        itemIsCompleted.attributeType = .booleanAttributeType
        itemIsCompleted.defaultValue = false

        let itemOrder = NSAttributeDescription()
        itemOrder.name = "order"
        itemOrder.attributeType = .integer32AttributeType
        itemOrder.defaultValue = 0

        let taskRelation = NSRelationshipDescription()
        taskRelation.name = "task"
        taskRelation.destinationEntity = taskEntity
        taskRelation.maxCount = 1
        taskRelation.minCount = 1
        taskRelation.deleteRule = .nullifyDeleteRule

        let itemsRelation = NSRelationshipDescription()
        itemsRelation.name = "checklistItems"
        itemsRelation.destinationEntity = itemEntity
        itemsRelation.isOptional = true
        itemsRelation.deleteRule = .cascadeDeleteRule

        taskRelation.inverseRelationship = itemsRelation
        itemsRelation.inverseRelationship = taskRelation

        taskEntity.properties.append(itemsRelation)
        itemEntity.properties = [itemId, itemTitle, itemIsCompleted, itemOrder, taskRelation]

        model.entities = [taskEntity, tagEntity, epicEntity, itemEntity]
        return model
    }

    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Core Data save error: \(error)")
        }
    }
}
