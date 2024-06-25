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

    let model = BottomBarViewModel()
    private var subscriptions: Set<AnyCancellable> = []

    private lazy var urlBarViewRightConstraint = {
        urlBarView.rightAnchor.constraint(equalTo: contentBox.rightAnchor, constant: Metrics.urlBarViewCompactRightOffset)
    }()

    private lazy var contentBoxHeightConstraint = {
        contentBox.heightAnchor.constraint(equalToConstant: Metrics.contentBoxCompactHeight)
    }()

    lazy var contentBox = {
        UIView()
    }()

    private lazy var backButton = {
        let button = CircleButton(radius: Metrics.buttonRadius, systemImage: "arrowtriangle.backward")
        return button
    }()

    lazy var urlBarView = {
        URLBarView(cornerRadius: Metrics.buttonRadius, onPanGesture: onPanGesture)
    }()

    private lazy var tabsButton = {
        let button = CircleButton(radius: Metrics.buttonRadius, systemImage: "square.on.square")
        return button
    }()

    private lazy var menuButton = {
        let button = CircleButton(radius: 20, systemImage: "ellipsis")
        return button
    }()

    init() {
        super.init(effect: UIBlurEffect(style: .systemMaterial))

        contentView.addSubview(contentBox)
        contentBox.addSubview(urlBarView)
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
            contentBoxHeightConstraint
        ])

        urlBarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            urlBarView.topAnchor.constraint(equalTo: contentBox.topAnchor),
            urlBarView.leftAnchor.constraint(equalTo: contentBox.leftAnchor),
            urlBarViewRightConstraint,
            urlBarView.heightAnchor.constraint(equalToConstant: Metrics.buttonDiameter)
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
        model.$expanded.dropFirst().sink { [weak self] expanded in
            self?.onUpdateLayout(expanded: expanded)
        }.store(in: &subscriptions)
    }

    private func onPanGesture(translation: CGFloat) {
        if translation < 50 {
            if !model.expanded {
                model.expanded = true
            }
        } else if translation > 50 {
            if model.expanded {
                model.expanded = false
            }
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
//            if expanded {
//                tabsButton.layer.opacity = 0.0
//                menuButton.layer.opacity = 0.0
//            } else {
//                tabsButton.layer.opacity = 1.0
//                menuButton.layer.opacity = 1.0
//            }
            layoutIfNeeded()
        }
    }
}
