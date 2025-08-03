//
//  TaskListViewModel.swift
//  ToDoListApp
//
//  Created by Владимир Федичев on 8/3/25.
//

import Foundation
import CoreData

final class TaskListViewModel {
    
    private(set) var tasks: [ToDoTask] = []
    private(set) var filteredTasks: [ToDoTask] = []
    
    private let persistenceManager = PersistenceManager.shared
    private let networkManager = NetworkManager.shared
    
    var isSearching: Bool = false
    var onTasksUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    
    func loadTasks() {
        let context = persistenceManager.mainContext
        let request: NSFetchRequest<ToDoTask> = ToDoTask.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            tasks = try context.fetch(request)
            onTasksUpdated?()
        } catch {
            onError?("Ошибка загрузки задач: \(error.localizedDescription)")
        }
    }
    
    func createTask(title: String, details: String?) {
        let context = persistenceManager.mainContext
        context.performAndWait {
            let task = ToDoTask(context: context)
            task.title = title
            task.details = details
            task.createdAt = Date()
            task.isCompleted = false
            
            persistenceManager.saveContext(context: context)
        }
        loadTasks()
    }
    
    func deleteTask(_ task: ToDoTask) {
        let context = persistenceManager.mainContext
        context.performAndWait {
            context.delete(task)
            persistenceManager.saveContext(context: context)
        }
        loadTasks()
    }
    
    func toggleCompleted(_ task: ToDoTask) {
        let context = persistenceManager.mainContext
        context.performAndWait {
            task.isCompleted.toggle()
            persistenceManager.saveContext(context: context)
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
                    self?.onError?("Ошибка поиска задач: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func loadAndSaveTodosFromNetwork() {
        networkManager.fetchTodos { [weak self] result in
            switch result {
            case .success(let todos):
                guard let self = self else { return }
                let context = self.persistenceManager.mainContext
                
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
                            self.onError?("Ошибка сохранения задач: \(error.localizedDescription)")
                        }
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.onError?("Ошибка загрузки задач: \(error.localizedDescription)")
                }
            }
        }
    }

    func task(at index: Int) -> ToDoTask? {
        return isSearching ? filteredTasks[safe: index] : tasks[safe: index]
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
