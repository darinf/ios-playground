import Combine
import UIKit

final class BottomBarView: UIVisualEffectView {
    enum Metrics {
        static let baseHeight: CGFloat = 50.0
        static let buttonRadius: CGFloat = 20
        static let buttonDiameter = 2 * buttonRadius
        static let margin: CGFloat = 12
        static let horizontalMargin: CGFloat = 1.5 * margin
        static let urlBarViewCompactRightOffset = -(2 * (buttonDiameter + margin) + horizontalMargin)
        static let urlBarViewExpandedRightOffset = -horizontalMargin
    }

    let model = BottomBarViewModel()
    private var subscriptions: Set<AnyCancellable> = []

    private lazy var urlBarViewRightConstraint = {
        urlBarView.rightAnchor.constraint(equalTo: rightAnchor, constant: Metrics.urlBarViewCompactRightOffset)
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

        contentView.addSubview(urlBarView)
        contentView.addSubview(tabsButton)
        contentView.addSubview(menuButton)

        urlBarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            urlBarView.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.margin),
            urlBarView.leftAnchor.constraint(equalTo: leftAnchor, constant: Metrics.horizontalMargin),
            urlBarViewRightConstraint,
            urlBarView.heightAnchor.constraint(equalToConstant: Metrics.buttonDiameter)
        ])

        tabsButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tabsButton.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.margin),
            tabsButton.rightAnchor.constraint(equalTo: menuButton.leftAnchor, constant: -Metrics.margin),
            tabsButton.widthAnchor.constraint(equalToConstant: Metrics.buttonDiameter),
            tabsButton.heightAnchor.constraint(equalToConstant: Metrics.buttonDiameter)
        ])

        menuButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            menuButton.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.margin),
            menuButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -Metrics.horizontalMargin),
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
            urlBarViewRightConstraint.constant = Metrics.urlBarViewExpandedRightOffset
        } else {
            urlBarViewRightConstraint.constant = Metrics.urlBarViewCompactRightOffset
        }
        UIView.animate(withDuration: 0.2, delay: 0) { [self] in
            if expanded {
                tabsButton.layer.opacity = 0.0
                menuButton.layer.opacity = 0.0
            } else {
                tabsButton.layer.opacity = 1.0
                menuButton.layer.opacity = 1.0
            }
            layoutIfNeeded()
        }
    }
}
