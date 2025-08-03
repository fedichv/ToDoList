//
//  ToDoListAppTests.swift
//  ToDoListAppTests
//
//  Created by Владимир Федичев on 8/3/25.
//

import XCTest
@testable import ToDoListApp
import CoreData

final class TaskDetailViewModelTests: XCTestCase {
    
    var persistenceManager: PersistenceManager!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        persistenceManager = PersistenceManager.shared
        context = persistenceManager.mainContext
        clearAllTasks()
    }
    
    override func tearDown() {
        clearAllTasks()
        super.tearDown()
    }
    
    private func clearAllTasks() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ToDoTask.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            XCTFail("Failed to clear tasks: \(error)")
        }
    }
    
    func testInitWithExistingTask() {
        let task = ToDoTask(context: context)
        task.title = "Existing Task"
        task.details = "Details"
        task.createdAt = Date(timeIntervalSince1970: 0)
        
        let vm = TaskDetailViewModel(task: task)
        
        XCTAssertFalse(vm.isNewTask)
        XCTAssertEqual(vm.title, "Existing Task")
        XCTAssertEqual(vm.details, "Details")
        XCTAssertEqual(vm.createdAt, Date(timeIntervalSince1970: 0))
        XCTAssertEqual(vm.createdDateString, "01 January 1970, 03:00") // UTC+3 timezone example
    }
    
    func testInitWithNilTask() {
        let vm = TaskDetailViewModel(task: nil)
        
        XCTAssertTrue(vm.isNewTask)
        XCTAssertEqual(vm.title, "")
        XCTAssertNil(vm.details)
        XCTAssertNotNil(vm.createdAt)
    }
    
    func testSaveTaskCreatesNew() {
        let vm = TaskDetailViewModel(task: nil)
        vm.title = "New Task"
        vm.details = "Some details"
        vm.saveTask()
        
        let fetchRequest: NSFetchRequest<ToDoTask> = ToDoTask.fetchRequest()
        do {
            let tasks = try context.fetch(fetchRequest)
            XCTAssertEqual(tasks.count, 1)
            XCTAssertEqual(tasks.first?.title, "New Task")
            XCTAssertEqual(tasks.first?.details, "Some details")
            XCTAssertFalse(tasks.first!.isCompleted)
        } catch {
            XCTFail("Fetch failed: \(error)")
        }
    }
    
    func testSaveTaskUpdatesExisting() {
        let task = ToDoTask(context: context)
        task.title = "Old Title"
        task.details = "Old Details"
        task.createdAt = Date()
        
        try? context.save()
        
        let vm = TaskDetailViewModel(task: task)
        vm.title = "Updated Title"
        vm.details = "Updated Details"
        vm.saveTask()
        
        let fetchRequest: NSFetchRequest<ToDoTask> = ToDoTask.fetchRequest()
        do {
            let tasks = try context.fetch(fetchRequest)
            XCTAssertEqual(tasks.count, 1)
            XCTAssertEqual(tasks.first?.title, "Updated Title")
            XCTAssertEqual(tasks.first?.details, "Updated Details")
        } catch {
            XCTFail("Fetch failed: \(error)")
        }
    }
}

final class TaskListViewModelTests: XCTestCase {
    
    var viewModel: TaskListViewModel!
    let persistenceManager = PersistenceManager.shared
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        viewModel = TaskListViewModel()
        context = persistenceManager.mainContext
        clearAllTasks()
    }
    
    override func tearDown() {
        clearAllTasks()
        super.tearDown()
    }
    
    private func clearAllTasks() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ToDoTask.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            XCTFail("Failed to clear tasks: \(error)")
        }
    }
    
    func testCreateTask() {
        viewModel.createTask(title: "Test task", details: "Some details")
        viewModel.loadTasks()
        
        let createdTask = viewModel.tasks.first
        XCTAssertNotNil(createdTask)
        XCTAssertEqual(createdTask?.title, "Test task")
        XCTAssertEqual(createdTask?.details, "Some details")
        XCTAssertFalse(createdTask!.isCompleted)
    }
    
    func testDeleteTask() {
        viewModel.createTask(title: "To delete", details: nil)
        viewModel.loadTasks()
        
        guard let task = viewModel.tasks.first else {
            XCTFail("Task wasn't created")
            return
        }
        
        viewModel.deleteTask(task)
        viewModel.loadTasks()
        
        XCTAssertFalse(viewModel.tasks.contains(task))
    }
    
    func testToggleCompleted() {
        viewModel.createTask(title: "Complete me", details: nil)
        viewModel.loadTasks()
        
        guard let task = viewModel.tasks.first else {
            XCTFail("Task wasn't created")
            return
        }
        
        let initialStatus = task.isCompleted
        viewModel.toggleCompleted(task)
        
        XCTAssertNotEqual(task.isCompleted, initialStatus)
    }
    
    func testUpdateSearchResults() {
        viewModel.createTask(title: "Buy milk", details: nil)
        viewModel.createTask(title: "Walk dog", details: nil)
        viewModel.loadTasks()
        
        let expectation = self.expectation(description: "Search callback")
        
        viewModel.onTasksUpdated = {
            XCTAssertEqual(self.viewModel.filteredTasks.count, 1)
            XCTAssertEqual(self.viewModel.filteredTasks.first?.title, "Buy milk")
            expectation.fulfill()
        }
        
        viewModel.updateSearchResults(query: "milk")
        wait(for: [expectation], timeout: 2)
    }
    
    func testTaskAtIndexSafety() {
        viewModel.createTask(title: "Task 1", details: nil)
        viewModel.loadTasks()
        
        let validTask = viewModel.task(at: 0)
        XCTAssertNotNil(validTask)
        
        let invalidTask = viewModel.task(at: 10)
        XCTAssertNil(invalidTask)
    }
}
