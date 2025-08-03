//
//  TaskListViewController.swift
//  ToDoListApp
//
//  Created by Владимир Федичев on 8/3/25.
//

import UIKit
import CoreData

final class TaskListViewController: UIViewController {

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()

    private var tasks: [ToDoTask] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ToDo List"
        view.backgroundColor = .systemBackground

        setupTableView()
        setupNavigationBar()
        fetchTasks()

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tableView.addGestureRecognizer(longPress)
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(didTapAdd)
        )
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: tableView)

        guard gesture.state == .began,
              let indexPath = tableView.indexPathForRow(at: location)
        else { return }

        let task = tasks[indexPath.row]

        let alert = UIAlertController(title: task.title, message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Редактировать", style: .default, handler: { [weak self] _ in
            self?.showEditDialog(for: task)
        }))

        alert.addAction(UIAlertAction(title: "Поделиться", style: .default, handler: { _ in
            let text = "\(task.title ?? "")\n\n\(task.details ?? "")"
            let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            self.present(activityVC, animated: true)
        }))

        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive, handler: { [weak self] _ in
            self?.deleteTask(task)
        }))

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))

        present(alert, animated: true)
    }
    
    private func showEditDialog(for task: ToDoTask) {
        let alert = UIAlertController(title: "Редактировать", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.text = task.title }
        alert.addTextField { $0.text = task.details }

        alert.addAction(UIAlertAction(title: "Сохранить", style: .default, handler: { [weak self] _ in
            guard let title = alert.textFields?[0].text, !title.isEmpty else { return }
            let details = alert.textFields?[1].text

            task.title = title
            task.details = details
            PersistenceManager.shared.saveContext(context: PersistenceManager.shared.mainContext)
            self?.fetchTasks()
        }))

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    private func deleteTask(_ task: ToDoTask) {
        let context = PersistenceManager.shared.mainContext
        context.delete(task)
        PersistenceManager.shared.saveContext(context: context)
        fetchTasks()
    }
    
    @objc private func didTapAdd() {
        let alert = UIAlertController(title: "Новая задача", message: "Введите название", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Название" }
        alert.addTextField { $0.placeholder = "Описание (необязательно)" }

        let createAction = UIAlertAction(title: "Создать", style: .default) { [weak self] _ in
            guard let title = alert.textFields?[0].text, !title.isEmpty else { return }
            let details = alert.textFields?[1].text
            self?.createTask(title: title, details: details)
        }

        alert.addAction(createAction)
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    private func createTask(title: String, details: String?) {
        let context = PersistenceManager.shared.mainContext
        let task = ToDoTask(context: context)
        task.title = title
        task.details = details
        task.createdAt = Date()
        task.isCompleted = false

        PersistenceManager.shared.saveContext(context: context)
        fetchTasks()
    }

    private func fetchTasks() {
        let context = PersistenceManager.shared.mainContext
        let request: NSFetchRequest<ToDoTask> = ToDoTask.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            tasks = try context.fetch(request)
            tableView.reloadData()
        } catch {
            print("Ошибка при загрузке задач: \(error)")
        }
    }
}

extension TaskListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let task = tasks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = task.title
        config.secondaryText = task.details
        cell.contentConfiguration = config
        cell.accessoryType = task.isCompleted ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = tasks[indexPath.row]
        task.isCompleted.toggle()
        PersistenceManager.shared.saveContext(context: PersistenceManager.shared.mainContext)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
