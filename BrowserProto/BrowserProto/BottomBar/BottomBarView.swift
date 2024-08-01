import Combine
import UIKit

final class BottomBarView: UIVisualEffectView {
    enum Metrics {
        static let buttonRadius: CGFloat = 20
        static let buttonDiameter = 2 * buttonRadius
        static let margin: CGFloat = 12
        static let horizontalMargin: CGFloat = 1.5 * margin
        static let contentBoxHeight = buttonDiameter
    }

    enum Action {
        case goBack
        case goForward
        case showTabs
        case addTab
        case editURL
        case mainMenu(MainMenu.Action)
    }

    private let model: BottomBarViewModel
    private let handler: (Action) -> Void
    private var subscriptions: Set<AnyCancellable> = []

    private lazy var contentBox = {
        UIView()
    }()

    private lazy var centerButtonView = {
        CenterButtonView(cornerRadius: Metrics.buttonRadius) { [weak self] action in
            guard let self else { return }
            switch action {
            case .clicked:
                if model.configureForAllTabs {
                    handler(.addTab)
                } else {
                    handler(.editURL)
                }
            }
        }
    }()

    private lazy var centerButtonViewFullWidthConstraints = {[
        centerButtonView.leftAnchor.constraint(equalTo: tabsButton.rightAnchor, constant: Metrics.margin),
        centerButtonView.rightAnchor.constraint(equalTo: menuButton.leftAnchor, constant: -Metrics.margin)
    ]}()

    private lazy var centerButtonViewNarrowConstraints = {[
        centerButtonView.centerXAnchor.constraint(equalTo: contentBox.centerXAnchor),
        centerButtonView.widthAnchor.constraint(equalToConstant: 100)
    ]}()

    private lazy var tabsButton = {
        let button = CapsuleButton(cornerRadius: Metrics.buttonRadius, systemImage: "square.on.square") { [weak self] in
            self?.handler(.showTabs)
        }
        return button
    }()

    private lazy var menuButton = {
        let button = CapsuleButton(cornerRadius: 20, systemImage: "ellipsis")
        button.showsMenuAsPrimaryAction = true
        return button
    }()

    init(model: BottomBarViewModel, handler: @escaping (Action) -> Void) {
        self.model = model
        self.handler = handler
        super.init(effect: UIBlurEffect(style: .systemThinMaterial))

        DropShadow.apply(toLayer: layer)

        contentView.addSubview(contentBox)
        contentBox.addSubview(centerButtonView)
        contentBox.addSubview(tabsButton)
        contentBox.addSubview(menuButton)

        setupConstraints()
    }

    private func setupConstraints() {
        contentBox.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentBox.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.margin),
            contentBox.leftAnchor.constraint(equalTo: leftAnchor, constant: Metrics.horizontalMargin),
            contentBox.rightAnchor.constraint(equalTo: rightAnchor, constant: -Metrics.horizontalMargin),
            contentBox.heightAnchor.constraint(equalToConstant: Metrics.contentBoxHeight)
        ])

        centerButtonView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            centerButtonView.topAnchor.constraint(equalTo: contentBox.topAnchor),
            centerButtonView.heightAnchor.constraint(equalToConstant: Metrics.buttonDiameter)
        ])

        tabsButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tabsButton.bottomAnchor.constraint(equalTo: contentBox.bottomAnchor),
            tabsButton.leftAnchor.constraint(equalTo: contentBox.leftAnchor),
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
        model.$url.dropFirst().removeDuplicates().sink { [weak self] url in
            guard let self else { return }
            guard !model.configureForAllTabs else { return }
            centerButtonView.setDisplayText(url?.host() ?? "")
        }.store(in: &subscriptions)

        model.$progress.dropFirst().removeDuplicates().sink { [weak self] progress in
            guard let self else { return }
            guard !model.configureForAllTabs else { return }
            centerButtonView.setProgress(progress)
        }.store(in: &subscriptions)

        model.$mainMenuConfig.removeDuplicates().sink { [weak self] config in
            self?.rebuildMainMenu(with: config)
        }.store(in: &subscriptions)

        model.$configureForAllTabs.sink { [weak self] configureForAllTabs in
            guard let self else { return }
            if configureForAllTabs {
                centerButtonView.resetProgressWithoutAnimation()
                centerButtonView.setDisplayText("")
                centerButtonView.setImage(.init(systemName: "plus"))
                NSLayoutConstraint.deactivate(centerButtonViewFullWidthConstraints)
                NSLayoutConstraint.activate(centerButtonViewNarrowConstraints)
            } else {
                centerButtonView.setDisplayText(model.url?.host() ?? "")
                centerButtonView.setImage(nil)
                NSLayoutConstraint.deactivate(centerButtonViewNarrowConstraints)
                NSLayoutConstraint.activate(centerButtonViewFullWidthConstraints)
            }
        }.store(in: &subscriptions)
    }

    private func rebuildMainMenu(with config: MainMenuConfig) {
        print(">>> rebuildMainMenu")
        menuButton.menu = MainMenu.build(with: config) { [weak self] action in
            guard let self else { return }
            switch action {
            case .toggleIncognito(let incognitoEnabled):
                model.mainMenuConfig = .init(incognitoChecked: incognitoEnabled)
            }
            handler(.mainMenu(action))
        }
    }
}
