import UIKit

// MARK: - Constants

extension TaskDetailViewController {
    enum Constants {
        static let titleFontSize: CGFloat = 24
        static let dateFontSize: CGFloat = 14
        static let descriptionFontSize: CGFloat = 18

        static let titleTopInset: CGFloat = 8
        static let titleSideInset: CGFloat = 16
        static let dateTopInset: CGFloat = 2
        static let dateHeight: CGFloat = 18
        static let descriptionTopInset: CGFloat = 8
        static let descriptionBottomInset: CGFloat = -12

        static let textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
    }
}

// MARK: - TaskDetailViewController

final class TaskDetailViewController: UIViewController {

    // MARK: - UI Elements

    private let titleTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: Constants.titleFontSize, weight: .bold)
        tv.isScrollEnabled = false
        tv.textContainerInset = .zero
        tv.textContainer.lineBreakMode = .byWordWrapping
        tv.textColor = .label
        tv.backgroundColor = .clear
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.dateFontSize)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let descriptionTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: Constants.descriptionFontSize)
        tv.isScrollEnabled = true
        tv.textContainerInset = Constants.textContainerInset
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // MARK: - Properties

    var onSave: ((String, String?) -> Void)?
    private let viewModel: TaskDetailViewModel
    private var originalTitle: String = ""
    private var originalDetails: String = ""

    // MARK: - Init

    init(task: ToDoTask?) {
        self.viewModel = TaskDetailViewModel(task: task)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        setupViews()
        setupConstraints()
        configureFields()
        setupDelegates()
    }

    // MARK: - Setup

    private func setupViews() {
        view.addSubview(titleTextView)
        view.addSubview(dateLabel)
        view.addSubview(descriptionTextView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.titleTopInset),
            titleTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.titleSideInset),
            titleTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.titleSideInset),

            dateLabel.topAnchor.constraint(equalTo: titleTextView.bottomAnchor, constant: Constants.dateTopInset),
            dateLabel.leadingAnchor.constraint(equalTo: titleTextView.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: titleTextView.trailingAnchor),
            dateLabel.heightAnchor.constraint(equalToConstant: Constants.dateHeight),

            descriptionTextView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: Constants.descriptionTopInset),
            descriptionTextView.leadingAnchor.constraint(equalTo: titleTextView.leadingAnchor),
            descriptionTextView.trailingAnchor.constraint(equalTo: titleTextView.trailingAnchor),
            descriptionTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: Constants.descriptionBottomInset)
        ])
    }

    private func configureFields() {
        titleTextView.text = viewModel.title
        descriptionTextView.text = viewModel.details
        dateLabel.text = viewModel.createdDateString

        originalTitle = viewModel.title
        originalDetails = viewModel.details ?? ""
    }

    private func setupDelegates() {
        titleTextView.delegate = self
        descriptionTextView.delegate = self
    }

    // MARK: - Actions

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveChangesIfNeeded()
    }

    private func saveChangesIfNeeded() {
        let currentTitle = titleTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let currentDetails = descriptionTextView.text

        guard !currentTitle.isEmpty else { return }

        if currentTitle != originalTitle || currentDetails != originalDetails {
            onSave?(currentTitle, currentDetails)
        }
    }
}

// MARK: - UITextViewDelegate

extension TaskDetailViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        
    }
}
