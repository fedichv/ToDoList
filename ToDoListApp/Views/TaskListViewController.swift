import UIKit

// MARK: - Constants

private extension TaskListViewController {
    enum Constants {
        static let countLabelFontSize: CGFloat = 14
        static let countLabelHeight: CGFloat = 20
        static let countLabelBottomInset: CGFloat = -20
        static let countLabelLeadingInset: CGFloat = 16
        static let countLabelTrailingSpacing: CGFloat = -8
        static let addButtonTrailingInset: CGFloat = -24
        static let addButtonSize: CGFloat = 56
        static let tableViewBottomSpacing: CGFloat = -8
        static let addButtonIconSize: CGFloat = 22
    }
}

// MARK: - TaskListViewController

final class TaskListViewController: UIViewController {

    private let viewModel = TaskListViewModel()

    // MARK: - UI Elements

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.countLabelFontSize)
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
        let config = UIImage.SymbolConfiguration(pointSize: Constants.addButtonIconSize, weight: .bold)
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

    // MARK: - Setup

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
            tableView.bottomAnchor.constraint(equalTo: countLabel.topAnchor, constant: Constants.tableViewBottomSpacing),

            countLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.countLabelLeadingInset),
            countLabel.trailingAnchor.constraint(equalTo: floatingAddButton.leadingAnchor, constant: Constants.countLabelTrailingSpacing),
            countLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: Constants.countLabelBottomInset),
            countLabel.heightAnchor.constraint(equalToConstant: Constants.countLabelHeight),

            floatingAddButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: Constants.addButtonTrailingInset),
            floatingAddButton.centerYAnchor.constraint(equalTo: countLabel.centerYAnchor),
            floatingAddButton.widthAnchor.constraint(equalToConstant: Constants.addButtonSize),
            floatingAddButton.heightAnchor.constraint(equalToConstant: Constants.addButtonSize)
        ])
    }

    // MARK: - Helpers

    private func updateCountLabel() {
        let count = viewModel.isSearching ? viewModel.filteredTasks.count : viewModel.tasks.count
        countLabel.text = "\(count) Задач"
    }

    // MARK: - Actions

    @objc private func didTapAdd() {
        let editorVC = TaskDetailViewController(task: nil)
        editorVC.onSave = { [weak self] title, details in
            self?.viewModel.createTask(title: title, details: details)
        }
        navigationController?.pushViewController(editorVC, animated: true)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: tableView)
        guard gesture.state == .began,
              let indexPath = tableView.indexPathForRow(at: location),
              let cell = tableView.cellForRow(at: indexPath),
              let task = viewModel.task(at: indexPath.row) else { return }
        cell.setSelected(false, animated: false)

        presentOptionsAlert(for: task)
    }

    private func presentOptionsAlert(for task: ToDoTask) {
        let alert = UIAlertController(title: task.title, message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Редактировать", style: .default) { [weak self] _ in
            self?.editTask(task)
        })

        alert.addAction(UIAlertAction(title: "Поделиться", style: .default) { [weak self] _ in
            self?.shareTask(task)
        })

        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteTask(task)
        })

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))

        present(alert, animated: true)
    }

    private func editTask(_ task: ToDoTask) {
        let editorVC = TaskDetailViewController(task: task)
        editorVC.onSave = { [weak self] title, details in
            task.title = title
            task.details = details
            PersistenceManager.shared.saveContext(context: PersistenceManager.shared.mainContext)
            self?.viewModel.loadTasks()
        }
        navigationController?.pushViewController(editorVC, animated: true)
    }

    private func shareTask(_ task: ToDoTask) {
        let text = "\(task.title ?? "")\n\n\(task.details ?? "")"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        present(activityVC, animated: true)
    }
}

// MARK: - UISearchResultsUpdating

extension TaskListViewController: UISearchResultsUpdating {
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
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = viewModel.isSearching ? viewModel.filteredTasks[indexPath.row] : viewModel.tasks[indexPath.row]
        editTask(task)
    }
}

// MARK: - TaskCellDelegate

extension TaskListViewController: TaskCellDelegate {
    func didTapCheckmark(for task: ToDoTask) {
        viewModel.toggleCompleted(task)
    }

    func didRequestEdit(for task: ToDoTask) {
        editTask(task)
    }

    func didRequestShare(for task: ToDoTask) {
        shareTask(task)
    }

    func didRequestDelete(for task: ToDoTask) {
        viewModel.deleteTask(task)
    }

    func didToggleComplete(for task: ToDoTask) {
        viewModel.toggleCompleted(task)
    }
}
