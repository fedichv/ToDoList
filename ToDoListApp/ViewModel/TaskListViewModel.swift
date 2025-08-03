import Foundation
import CoreData

final class TaskListViewModel {
    
    // MARK: - Properties
    
    private(set) var tasks: [ToDoTask] = []
    private(set) var filteredTasks: [ToDoTask] = []
    
    private let persistenceManager = PersistenceManager.shared
    private let networkManager = NetworkManager.shared
    
    var isSearching: Bool = false
    var onTasksUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    
    // MARK: - Public Methods
    
    func loadTasks() {
        fetchTasksFromStorage()
    }
    
    func createTask(title: String, details: String?) {
        performTaskOperation {
            self.createTaskInContext(title: title, details: details)
        }
        loadTasks()
    }
    
    func deleteTask(_ task: ToDoTask) {
        performTaskOperation {
            self.deleteTaskFromContext(task)
        }
        loadTasks()
    }
    
    func toggleCompleted(_ task: ToDoTask) {
        performTaskOperation {
            self.toggleTaskCompletionInContext(task)
        }
        loadTasks()
    }
    
    func updateSearchResults(query: String) {
        guard !query.isEmpty else {
            filteredTasks = []
            isSearching = false
            onTasksUpdated?()
            return
        }
        
        isSearching = true
        searchTasks(with: query)
    }
    
    func loadAndSaveTodosFromNetwork() {
        networkManager.fetchTodos { [weak self] result in
            self?.handleNetworkResponse(result)
        }
    }
    
    func task(at index: Int) -> ToDoTask? {
        return isSearching ? filteredTasks[safe: index] : tasks[safe: index]
    }
    
    // MARK: - Private Methods
    
    private func fetchTasksFromStorage() {
        let context = persistenceManager.mainContext
        let request: NSFetchRequest<ToDoTask> = ToDoTask.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            tasks = try context.fetch(request)
            onTasksUpdated?()
        } catch {
            reportError("Ошибка загрузки задач: \(error.localizedDescription)")
        }
    }
    
    private func createTaskInContext(title: String, details: String?) {
        let context = persistenceManager.mainContext
        let task = ToDoTask(context: context)
        task.title = title
        task.details = details
        task.createdAt = Date()
        task.isCompleted = false
        persistenceManager.saveContext(context: context)
    }
    
    private func deleteTaskFromContext(_ task: ToDoTask) {
        let context = persistenceManager.mainContext
        context.delete(task)
        persistenceManager.saveContext(context: context)
    }
    
    private func toggleTaskCompletionInContext(_ task: ToDoTask) {
        task.isCompleted.toggle()
        persistenceManager.saveContext(context: persistenceManager.mainContext)
    }
    
    private func performTaskOperation(_ operation: () -> Void) {
        let context = persistenceManager.mainContext
        context.performAndWait {
            operation()
        }
    }
    
    private func searchTasks(with query: String) {
        let context = persistenceManager.mainContext
        let request: NSFetchRequest<ToDoTask> = ToDoTask.fetchRequest()
        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "title CONTAINS[cd] %@", query),
            NSPredicate(format: "details CONTAINS[cd] %@", query)
        ])
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let results = try context.fetch(request)
                DispatchQueue.main.async {
                    self?.filteredTasks = results
                    self?.onTasksUpdated?()
                }
            } catch {
                DispatchQueue.main.async {
                    self?.reportError("Ошибка поиска задач: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func handleNetworkResponse(_ result: Result<[TodoItem], Error>) {
        switch result {
        case .success(let todos):
            let context = persistenceManager.mainContext
            
            context.perform {
                do {
                    for item in todos {
                        let fetchRequest: NSFetchRequest<ToDoTask> = ToDoTask.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "title == %@", item.todo)
                        fetchRequest.fetchLimit = 1
                        
                        let existingTasks = try context.fetch(fetchRequest)
                        
                        if let existingTask = existingTasks.first {
                            existingTask.details = existingTask.details ?? nil
                            existingTask.createdAt = existingTask.createdAt ?? Date()
                        } else {
                            let task = ToDoTask(context: context)
                            task.title = item.todo
                            task.details = nil
                            task.isCompleted = item.completed
                            task.createdAt = Date()
                        }
                    }
                    
                    try context.save()
                    DispatchQueue.main.async {
                        self.loadTasks()
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.reportError("Ошибка сохранения задач: \(error.localizedDescription)")
                    }
                }
            }
            
        case .failure(let error):
            DispatchQueue.main.async {
                self.reportError("Ошибка загрузки задач: \(error.localizedDescription)")
            }
        }
    }
    
    private func reportError(_ message: String) {
        onError?(message)
    }
}

// MARK: - Safe Collection Access

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
