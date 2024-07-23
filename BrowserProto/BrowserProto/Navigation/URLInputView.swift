import Combine
import SwiftUI
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

    lazy var suggestionsViewController = {
        UIHostingController(rootView: SuggestionsView(model: model, handler: { [weak self] action in
            guard let self else { return }
            switch action {
            case .suggestionAccepted(let suggestion):
                handler(.navigate(suggestion.text))
                model.visibility = .hidden
            }
        }))
    }()

    lazy var tapGestureRecognizer = {
        UITapGestureRecognizer(target: self, action: #selector(onDismiss))
    }()

    lazy var panGestureRecognizer = {
        UIPanGestureRecognizer(target: self, action: #selector(onPan))
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

        contentBox.contentView.addSubview(suggestionsViewController.view)

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
            textField.centerYAnchor.constraint(equalTo: textFieldContainer.centerYAnchor)
        ])

        suggestionsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            suggestionsViewController.view.topAnchor.constraint(equalTo: textFieldContainer.bottomAnchor, constant: Metrics.margin),
            suggestionsViewController.view.bottomAnchor.constraint(equalTo: contentBox.bottomAnchor, constant: -Metrics.margin),
            suggestionsViewController.view.leftAnchor.constraint(equalTo: contentBox.leftAnchor),
            suggestionsViewController.view.rightAnchor.constraint(equalTo: contentBox.rightAnchor)
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
                UIView.animate(withDuration: 0.2) { [self] in
                    self.contentBoxMinHeightConstraint.isActive = false
                    self.contentBoxFullHeightConstraint.isActive = true
                    self.layoutIfNeeded()
                }
            } else {
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

    @objc private func onPan() {
        let threshold: CGFloat = 25
        let translation = panGestureRecognizer.translation(in: contentBox)
        if translation.y > threshold {
            model.visibility = .hidden
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
