import UIKit

final class URLInputView: UIView {
    private let completion: (String?) -> Void

    enum Metrics {
        static let margin: CGFloat = 10
        static let textFieldContainerHeight: CGFloat = 30
        static let textFieldMargin: CGFloat = textFieldContainerHeight / 2
        static let contentBoxHeight: CGFloat = textFieldContainerHeight + 2 * margin
    }

    lazy var contentBox = {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    }()

    lazy var filler = {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    }()

    lazy var textFieldContainer = {
        let container = UIView()
        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = Metrics.textFieldContainerHeight / 2
        return container
    }()

    lazy var textField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()

    lazy var tapGestureRecognizer = {
        UITapGestureRecognizer(target: self, action: #selector(onDismiss))
    }()

    init(completion: @escaping (String?) -> Void) {
        self.completion = completion
        super.init(frame: .zero)

        addGestureRecognizer(tapGestureRecognizer)

        addSubview(contentBox)
        addSubview(filler)
        contentBox.contentView.addSubview(textFieldContainer)
        textFieldContainer.addSubview(textField)

        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        contentBox.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentBox.widthAnchor.constraint(equalTo: widthAnchor),
            contentBox.heightAnchor.constraint(equalToConstant: Metrics.contentBoxHeight),
            contentBox.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor)
        ])

        filler.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            filler.widthAnchor.constraint(equalTo: widthAnchor),
            filler.topAnchor.constraint(equalTo: contentBox.bottomAnchor),
            filler.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        textFieldContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textFieldContainer.leadingAnchor.constraint(equalTo: contentBox.leadingAnchor, constant: Metrics.margin),
            textFieldContainer.trailingAnchor.constraint(equalTo: contentBox.trailingAnchor, constant: -Metrics.margin),
            textFieldContainer.heightAnchor.constraint(equalToConstant: Metrics.textFieldContainerHeight),
            textFieldContainer.centerYAnchor.constraint(equalTo: contentBox.centerYAnchor)
        ])

        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: textFieldContainer.leadingAnchor, constant: Metrics.textFieldMargin),
            textField.trailingAnchor.constraint(equalTo: textFieldContainer.trailingAnchor, constant: -Metrics.textFieldMargin),
            textField.centerYAnchor.constraint(equalTo: textFieldContainer.centerYAnchor)
        ])
    }

    @objc private func onDismiss() {
        completion(nil)
    }
}
