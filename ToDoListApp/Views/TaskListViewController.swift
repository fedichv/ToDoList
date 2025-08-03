import UIKit

final class TaskListViewController: UIViewController, UISearchResultsUpdating {

    private let viewModel = TaskListViewModel()

    // MARK: - UI Elements

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(TaskCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()

    private let floatingAddButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
        let image = UIImage(systemName: "square.and.pencil", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .systemYellow
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let searchController: UISearchController = {
        let search = UISearchController(searchResultsController: nil)
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Поиск задач"
        return search
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupNavigation()
        setupTableView()
        setupBindings()
        setupGestureRecognizers()

        viewModel.loadAndSaveTodosFromNetwork()
        updateCountLabel()
    }

    // MARK: - Setup Methods

    private func setupView() {
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)
        view.addSubview(countLabel)
        view.addSubview(floatingAddButton)

        setupConstraints()
        floatingAddButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
    }

    private func setupNavigation() {
        title = "Задачи"
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true

        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        definesPresentationContext = true
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func setupBindings() {
        viewModel.onTasksUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.updateCountLabel()
            }
        }

        viewModel.onError = { errorMessage in
            print(errorMessage)
        }
    }

    private func setupGestureRecognizers() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tableView.addGestureRecognizer(longPress)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: countLabel.topAnchor, constant: -8),

            countLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            countLabel.trailingAnchor.constraint(equalTo: floatingAddButton.leadingAnchor, constant: -8),
            countLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            countLabel.heightAnchor.constraint(equalToConstant: 20),

            floatingAddButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            floatingAddButton.centerYAnchor.constraint(equalTo: countLabel.centerYAnchor),
            floatingAddButton.widthAnchor.constraint(equalToConstant: 56),
            floatingAddButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    // MARK: - Helper Methods

    private func updateCountLabel() {
        let count = viewModel.isSearching ? viewModel.filteredTasks.count : viewModel.tasks.count
        countLabel.text = "\(count) Задач"
    }

    private func showEditDialog(for task: ToDoTask) {
        let alert = UIAlertController(title: "Редактировать", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.text = task.title }
        alert.addTextField { $0.text = task.details }

        alert.addAction(UIAlertAction(title: "Сохранить", style: .default) { [weak self] _ in
            guard let title = alert.textFields?[0].text, !title.isEmpty else { return }
            let details = alert.textFields?[1].text
            task.title = title
            task.details = details
            PersistenceManager.shared.saveContext(context: PersistenceManager.shared.mainContext)
            self?.viewModel.loadTasks()
        })

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Actions

    @objc private func didTapAdd() {
        let alert = UIAlertController(title: "Новая задача", message: "Введите название", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Название" }
        alert.addTextField { $0.placeholder = "Описание (необязательно)" }

        let createAction = UIAlertAction(title: "Создать", style: .default) { [weak self] _ in
            guard let title = alert.textFields?[0].text, !title.isEmpty else { return }
            let details = alert.textFields?[1].text
            self?.viewModel.createTask(title: title, details: details)
        }

        alert.addAction(createAction)
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: tableView)

        guard gesture.state == .began,
              let indexPath = tableView.indexPathForRow(at: location),
              let task = viewModel.task(at: indexPath.row)
        else { return }

        let alert = UIAlertController(title: task.title, message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Редактировать", style: .default) { [weak self] _ in
            self?.showEditDialog(for: task)
        })

        alert.addAction(UIAlertAction(title: "Поделиться", style: .default) { [weak self] _ in
            let text = "\(task.title ?? "")\n\n\(task.details ?? "")"
            let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            self?.present(activityVC, animated: true)
        })

        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteTask(task)
        })

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text else { return }
        viewModel.updateSearchResults(query: query)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension TaskListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.isSearching ? viewModel.filteredTasks.count : viewModel.tasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let task = viewModel.isSearching ? viewModel.filteredTasks[indexPath.row] : viewModel.tasks[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? TaskCell else {
            return UITableViewCell()
        }
        cell.configure(with: task)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = viewModel.isSearching ? viewModel.filteredTasks[indexPath.row] : viewModel.tasks[indexPath.row]
        viewModel.toggleCompleted(task)
    }
}
