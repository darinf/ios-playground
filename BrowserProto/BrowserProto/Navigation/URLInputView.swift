import Combine
import UIKit

final class URLInputView: UIView {
    let model = URLInputViewModel()

    private var subscriptions: Set<AnyCancellable> = []

    enum Metrics {
        static let margin: CGFloat = 10
        static let textFieldContainerHeight: CGFloat = 40
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
        textField.delegate = self
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = .webSearch
        return textField
    }()

    lazy var tapGestureRecognizer = {
        UITapGestureRecognizer(target: self, action: #selector(onDismiss))
    }()

    init() {
        super.init(frame: .zero)

        backgroundColor = .systemFill
        DropShadow.apply(toLayer: layer)
        layer.opacity = 0

        addGestureRecognizer(tapGestureRecognizer)

        addSubview(contentBox)
        addSubview(filler)
        contentBox.contentView.addSubview(textFieldContainer)
        textFieldContainer.addSubview(textField)

        setupConstraints()
        setupObservers()
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

    private func setupObservers() {
        model.$showing.dropFirst().sink { [weak self] showing in
            guard let self else { return }
            if showing {
                UIView.animate(withDuration: 0.2) {
                    self.layer.opacity = 1
                }
                textField.becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
                UIView.animate(withDuration: 0.2) {
                    self.layer.opacity = 0
                }
            }
        }.store(in: &subscriptions)
    }

    @objc private func onDismiss() {
        model.showing = false
    }
}

extension URLInputView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        model.showing = false
        if let text = textField.text {
            model.text = text
        }
        return true
    }
}
