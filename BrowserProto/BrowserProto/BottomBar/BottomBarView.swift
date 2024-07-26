import Combine
import UIKit

final class BottomBarView: UIVisualEffectView {
    enum Metrics {
        static let buttonRadius: CGFloat = 20
        static let buttonDiameter = 2 * buttonRadius
        static let margin: CGFloat = 12
        static let horizontalMargin: CGFloat = 1.5 * margin
        static let urlBarViewCompactRightOffset = -2 * (buttonDiameter + margin)
        static let urlBarViewExpandedRightOffset: CGFloat = 0
        static let contentBoxCompactHeight = buttonDiameter
        static let contentBoxExpandedHeight = 2 * buttonDiameter + margin
    }

    enum Action {
        case goBack
        case goForward
        case showTabs
        case showMenu
        case editURL
    }

    private let model: BottomBarViewModel
    private let handler: (Action) -> Void
    private var subscriptions: Set<AnyCancellable> = []

    private lazy var urlBarViewRightConstraint = {
        urlBarView.rightAnchor.constraint(equalTo: contentBox.rightAnchor, constant: Metrics.urlBarViewCompactRightOffset)
    }()

    private lazy var contentBoxHeightConstraint = {
        contentBox.heightAnchor.constraint(equalToConstant: Metrics.contentBoxCompactHeight)
    }()

    private lazy var contentBox = {
        UIView()
    }()

    private lazy var backButton = {
        let button = CapsuleButton(cornerRadius: Metrics.buttonRadius, systemImage: "chevron.left") { [weak self] in
            self?.handler(.goBack)
        }
        button.isEnabled = false
        return button
    }()

    private lazy var forwardButton = {
        let button = CapsuleButton(cornerRadius: Metrics.buttonRadius, systemImage: "chevron.right") { [weak self] in
            self?.handler(.goForward)
        }
        button.isEnabled = false
        return button
    }()

    private lazy var urlBarView = {
        URLBarView(cornerRadius: Metrics.buttonRadius) { [weak self] action in
            guard let self else { return }
            switch action {
            case .clicked:
                handler(.editURL)
            }
        }
    }()

    private lazy var tabsButton = {
        let button = CapsuleButton(cornerRadius: Metrics.buttonRadius, systemImage: "square.on.square") { [weak self] in
            self?.handler(.showTabs)
        }
        return button
    }()

    private lazy var mainMenu = {
        MainMenu(model: model.mainMenuModel)
    }()

    private lazy var menuButton = {
        let button = CapsuleButton(cornerRadius: 20, systemImage: "ellipsis")
//        let toggleIncognito = UIAction(title: "Incognito", image: UIImage(systemName: "square")) { _ in
//            print(">>> toggleIncognito action")
//        }
//        button.menu = UIMenu(children: [toggleIncognito])
        button.menu = mainMenu.menu
        button.showsMenuAsPrimaryAction = true
        return button
    }()

    private lazy var panGestureRecognizer = {
        UIPanGestureRecognizer(target: self, action: #selector(onPan))
    }()

    init(model: BottomBarViewModel, handler: @escaping (Action) -> Void) {
        self.model = model
        self.handler = handler
        super.init(effect: UIBlurEffect(style: .systemThinMaterial))

        DropShadow.apply(toLayer: layer)

        contentView.addSubview(contentBox)
        contentBox.addSubview(urlBarView)
        contentBox.addSubview(backButton)
        contentBox.addSubview(forwardButton)
        contentBox.addSubview(tabsButton)
        contentBox.addSubview(menuButton)

        backButton.layer.opacity = 0.0
        forwardButton.layer.opacity = 0.0

        addGestureRecognizer(panGestureRecognizer)

        setupConstraints()
    }

    private func setupConstraints() {
        contentBox.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentBox.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.margin),
            contentBox.leftAnchor.constraint(equalTo: leftAnchor, constant: Metrics.horizontalMargin),
            contentBox.rightAnchor.constraint(equalTo: rightAnchor, constant: -Metrics.horizontalMargin),
            contentBoxHeightConstraint
        ])

        urlBarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            urlBarView.topAnchor.constraint(equalTo: contentBox.topAnchor),
            urlBarView.leftAnchor.constraint(equalTo: contentBox.leftAnchor),
            urlBarViewRightConstraint,
            urlBarView.heightAnchor.constraint(equalToConstant: Metrics.buttonDiameter)
        ])

        backButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.bottomAnchor.constraint(equalTo: contentBox.bottomAnchor),
            backButton.leftAnchor.constraint(equalTo: contentBox.leftAnchor),
            backButton.widthAnchor.constraint(equalToConstant: Metrics.buttonDiameter),
            backButton.heightAnchor.constraint(equalToConstant: Metrics.buttonDiameter)
        ])

        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            forwardButton.bottomAnchor.constraint(equalTo: contentBox.bottomAnchor),
            forwardButton.leftAnchor.constraint(equalTo: backButton.rightAnchor, constant: Metrics.margin),
            forwardButton.widthAnchor.constraint(equalToConstant: Metrics.buttonDiameter),
            forwardButton.heightAnchor.constraint(equalToConstant: Metrics.buttonDiameter)
        ])

        tabsButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tabsButton.bottomAnchor.constraint(equalTo: contentBox.bottomAnchor),
            tabsButton.rightAnchor.constraint(equalTo: menuButton.leftAnchor, constant: -Metrics.margin),
            tabsButton.widthAnchor.constraint(equalToConstant: Metrics.buttonDiameter),
            tabsButton.heightAnchor.constraint(equalToConstant: Metrics.buttonDiameter)
        ])

        menuButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            menuButton.bottomAnchor.constraint(equalTo: contentBox.bottomAnchor),
            menuButton.rightAnchor.constraint(equalTo: contentBox.rightAnchor),
            menuButton.widthAnchor.constraint(equalToConstant: Metrics.buttonDiameter),
            menuButton.heightAnchor.constraint(equalToConstant: Metrics.buttonDiameter)
        ])

        setupObservers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupObservers() {
        model.$expanded.dropFirst().removeDuplicates().sink { [weak self] expanded in
            self?.onUpdateLayout(expanded: expanded)
        }.store(in: &subscriptions)

        model.$canGoBack.dropFirst().removeDuplicates().sink { [weak self] canGoBack in
            self?.backButton.isEnabled = canGoBack
        }.store(in: &subscriptions)

        model.$canGoForward.dropFirst().removeDuplicates().sink { [weak self] canGoForward in
            self?.forwardButton.isEnabled = canGoForward
        }.store(in: &subscriptions)

        model.$url.dropFirst().removeDuplicates().sink { [weak self] url in
            self?.urlBarView.setDisplayText(url?.host() ?? "")
        }.store(in: &subscriptions)

        model.$progress.dropFirst().removeDuplicates().sink { [weak self] progress in
            self?.urlBarView.setProgress(progress)
        }.store(in: &subscriptions)
    }

    private func onPanGesture(translation: CGFloat) {
        let threshold: CGFloat = 25

        if translation < threshold {
            model.expanded = true
        } else if translation > threshold {
            model.expanded = false
        }
    }

    private func onUpdateLayout(expanded: Bool) {
        if expanded {
            contentBoxHeightConstraint.constant = Metrics.contentBoxExpandedHeight
            urlBarViewRightConstraint.constant = Metrics.urlBarViewExpandedRightOffset
        } else {
            contentBoxHeightConstraint.constant = Metrics.contentBoxCompactHeight
            urlBarViewRightConstraint.constant = Metrics.urlBarViewCompactRightOffset
        }
        UIView.animate(withDuration: 0.2, delay: 0) { [self] in
            if expanded {
                backButton.layer.opacity = 1.0
                forwardButton.layer.opacity = 1.0
            } else {
                backButton.layer.opacity = 0.0
                forwardButton.layer.opacity = 0.0
            }
            layoutIfNeeded()
        }
    }

    @objc private func onPan() {
        onPanGesture(translation: panGestureRecognizer.translation(in: self).y)
    }
}
