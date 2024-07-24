import Combine
import UIKit

final class URLInputView: UIView {
    private let model: URLInputViewModel
    private let handler: (Action) -> Void
    private var subscriptions: Set<AnyCancellable> = []

    enum Metrics {
        static let margin: CGFloat = 10
        static let textFieldContainerHeight: CGFloat = 40
        static let textFieldMargin: CGFloat = textFieldContainerHeight / 2
        static let contentBoxMinHeight: CGFloat = textFieldContainerHeight + 2 * margin
    }

    enum Action {
        case navigate(String)
    }

    lazy var contentBox = {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    }()

    lazy var contentBoxFullHeightConstraint = {
        contentBox.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor)
    }()

    lazy var contentBoxMinHeightConstraint = {
        contentBox.heightAnchor.constraint(equalToConstant: Metrics.contentBoxMinHeight)
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

    lazy var suggestionsView = {
        SuggestionsView(model: model.suggestionsViewModel) { [weak self] action in
            guard let self else { return }
            switch action {
            case .suggestionAccepted(let suggestion):
                handler(.navigate(suggestion.text))
                model.visibility = .hidden
            }
        }
    }()

    lazy var tapGestureRecognizer = {
        UITapGestureRecognizer(target: self, action: #selector(onDismiss))
    }()

    lazy var panGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(onPan))
        gesture.delegate = self
        return gesture
    }()

    init(model: URLInputViewModel, handler: @escaping (Action) -> Void) {
        self.model = model
        self.handler = handler
        super.init(frame: .zero)

        backgroundColor = .systemFill
        DropShadow.apply(toLayer: layer)
        layer.opacity = 0

        addGestureRecognizer(tapGestureRecognizer)
        contentBox.addGestureRecognizer(panGestureRecognizer)

        addSubview(contentBox)
        addSubview(filler)
        contentBox.contentView.addSubview(textFieldContainer)
        textFieldContainer.addSubview(textField)

        contentBox.contentView.addSubview(suggestionsView)

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
            contentBoxMinHeightConstraint,
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
            textFieldContainer.topAnchor.constraint(equalTo: contentBox.topAnchor, constant: Metrics.margin),
            textFieldContainer.heightAnchor.constraint(equalToConstant: Metrics.textFieldContainerHeight)
        ])

        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: textFieldContainer.leadingAnchor, constant: Metrics.textFieldMargin),
            textField.trailingAnchor.constraint(equalTo: textFieldContainer.trailingAnchor, constant: -Metrics.textFieldMargin),
            textField.topAnchor.constraint(equalTo: textFieldContainer.topAnchor, constant: Metrics.margin),
            textField.bottomAnchor.constraint(equalTo: textFieldContainer.bottomAnchor, constant: -Metrics.margin)
        ])

        suggestionsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            suggestionsView.topAnchor.constraint(equalTo: textFieldContainer.bottomAnchor, constant: Metrics.margin),
            suggestionsView.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor),
            suggestionsView.leftAnchor.constraint(equalTo: contentBox.leftAnchor),
            suggestionsView.rightAnchor.constraint(equalTo: contentBox.rightAnchor)
        ])
    }

    private func setupObservers() {
        model.$visibility.dropFirst().sink { [weak self] mode in
            guard let self else { return }
            switch mode {
            case .showing(let initialValue):
                superview?.bringSubviewToFront(self)
                UIView.animate(withDuration: 0.2) {
                    self.layer.opacity = 1
                }
                textField.text = initialValue
                textField.becomeFirstResponder()
                textField.selectAll(nil)
            case .hidden:
                textField.resignFirstResponder()
                UIView.animate(withDuration: 0.2) {
                    self.layer.opacity = 0
                }
                model.suggesting = false
            }
        }.store(in: &subscriptions)

        model.$suggesting.dropFirst().sink { [weak self] suggesting in
            guard let self else { return }
            if suggesting {
                removeGestureRecognizer(tapGestureRecognizer)
                UIView.animate(withDuration: 0.2) { [self] in
                    self.contentBoxMinHeightConstraint.isActive = false
                    self.contentBoxFullHeightConstraint.isActive = true
                    self.layoutIfNeeded()
                }
            } else {
                addGestureRecognizer(tapGestureRecognizer)
                self.contentBoxMinHeightConstraint.isActive = true
                self.contentBoxFullHeightConstraint.isActive = false
            }
        }.store(in: &subscriptions)

        NotificationCenter.default.publisher(
            for: UITextField.textDidChangeNotification,
            object: textField
        ).sink { [weak self] _ in
            guard let self else { return }
            model.suggesting = true
            model.updateSuggestions(for: textField.text ?? "")
        }.store(in: &subscriptions)
    }

    @objc private func onDismiss() {
        model.visibility = .hidden
    }

    @objc private func onPan(_ gesture: UIPanGestureRecognizer) {
        let threshold: CGFloat = model.suggesting ? 50 : 25
        let translation = panGestureRecognizer.translation(in: contentBox)
        contentBox.layer.setAffineTransform(.init(translationX: 0, y: abs(translation.y)))
        if gesture.state == .ended {
            if translation.y > threshold {
                model.visibility = .hidden
            }
            UIView.animate(withDuration: 0.2) { [contentBox] in
                contentBox.layer.setAffineTransform(.init(translationX: 0, y: 0))
            }
        }
    }
}

extension URLInputView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            handler(.navigate(text))
        }
        model.visibility = .hidden
        return true
    }
}

extension URLInputView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        print(">>> shouldRecognizeSimultaneouslyWith")
        if let gesture = otherGestureRecognizer as? UIPanGestureRecognizer {
            if suggestionsView.contentOffset.y == 0 {
                return true
            }
        }
        return false
    }
}
