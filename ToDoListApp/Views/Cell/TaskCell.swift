import UIKit

// MARK: - Protocol

protocol TaskCellDelegate: AnyObject {
    func didTapCheckmark(for task: ToDoTask)
    func didRequestEdit(for task: ToDoTask)
    func didRequestShare(for task: ToDoTask)
    func didRequestDelete(for task: ToDoTask)
}

// MARK: - TaskCell

final class TaskCell: UITableViewCell {

    weak var delegate: TaskCellDelegate?
    private var currentTask: ToDoTask?

    // MARK: - UI Elements

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 1
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        return label
    }()

    private let checkmarkView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .systemYellow
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
        setupConstraints()
        setupContextMenu()
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup UI

    private func setupView() {
        contentView.addSubview(checkmarkView)
        contentView.addSubview(stackView)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(dateLabel)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCheckmark))
        checkmarkView.addGestureRecognizer(tap)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            checkmarkView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            checkmarkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkView.heightAnchor.constraint(equalToConstant: 24),

            stackView.leadingAnchor.constraint(equalTo: checkmarkView.trailingAnchor, constant: 12),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    private func setupContextMenu() {
        let contextInteraction = UIContextMenuInteraction(delegate: self)
        contentView.addInteraction(contextInteraction)
    }

    // MARK: - Actions

    @objc private func didTapCheckmark() {
        guard let task = currentTask else { return }
        delegate?.didTapCheckmark(for: task)
    }

    // MARK: - Configure Cell

    func configure(with task: ToDoTask) {
        currentTask = task
        configureTitle(task)
        configureSubtitle(task)
        configureDate(task)
        configureCheckmark(task)
    }

    private func configureTitle(_ task: ToDoTask) {
        if task.isCompleted {
            let attributedText = NSAttributedString(
                string: task.title ?? "",
                attributes: [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: UIColor.secondaryLabel
                ])
            titleLabel.attributedText = attributedText
        } else {
            titleLabel.attributedText = NSAttributedString(string: task.title ?? "", attributes: [
                .foregroundColor: UIColor.label
            ])
        }
    }

    private func configureSubtitle(_ task: ToDoTask) {
        subtitleLabel.text = task.details
    }

    private func configureDate(_ task: ToDoTask) {
        if let date = task.createdAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yy"
            dateLabel.text = formatter.string(from: date)
        } else {
            dateLabel.text = nil
        }
    }

    private func configureCheckmark(_ task: ToDoTask) {
        checkmarkView.image = task.isCompleted
            ? UIImage(systemName: "checkmark.circle")
            : UIImage(systemName: "circle")
    }
}

// MARK: - UIContextMenuInteractionDelegate

extension TaskCell: UIContextMenuInteractionDelegate {

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let task = currentTask else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in

            let editAction = UIAction(title: "Редактировать", image: UIImage(systemName: "pencil")) { [weak self] _ in
                self?.delegate?.didRequestEdit(for: task)
            }
            let shareAction = UIAction(title: "Поделиться", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                self?.delegate?.didRequestShare(for: task)
            }
            let deleteAction = UIAction(title: "Удалить", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.delegate?.didRequestDelete(for: task)
            }

            return UIMenu(title: "", children: [editAction, shareAction, deleteAction])
        }
    }
}
