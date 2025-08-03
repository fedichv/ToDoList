import Foundation
import CoreData

final class TaskDetailViewModel {

    // MARK: - Properties

    private let persistenceManager = PersistenceManager.shared
    private let context: NSManagedObjectContext
    private var task: ToDoTask?

    var isNewTask: Bool { task == nil }

    var title: String
    var details: String?
    var createdAt: Date

    var createdDateString: String {
        dateFormatter.string(from: createdAt)
    }

    // MARK: - Init

    init(task: ToDoTask?) {
        self.task = task
        self.context = persistenceManager.mainContext
        self.title = task?.title ?? ""
        self.details = task?.details
        self.createdAt = task?.createdAt ?? Date()
    }

    // MARK: - Public Methods

    func saveTask() {
        context.performAndWait {
            if let task = task {
                update(task)
            } else {
                createNewTask()
            }
            persistenceManager.saveContext(context: context)
        }
    }

    // MARK: - Private Methods

    private func update(_ task: ToDoTask) {
        task.title = title
        task.details = details
    }

    private func createNewTask() {
        let newTask = ToDoTask(context: context)
        newTask.title = title
        newTask.details = details
        newTask.createdAt = Date()
        newTask.isCompleted = false
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy, HH:mm"
        return formatter
    }
}
