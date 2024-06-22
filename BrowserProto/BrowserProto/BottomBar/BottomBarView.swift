import UIKit

enum BottomBarViewConstants {
    static let baseHeight: CGFloat = 50.0
}

final class BottomBarView: UIVisualEffectView {
    private let onPanUp: (CGFloat) -> Void

    private lazy var backButton = {
        let button = CircleButton(radius: 20, systemImage: "arrowtriangle.backward")
        return button
    }()

    private lazy var urlBarView = {
        URLBarView(cornerRadius: 20, onPanUp: onPanUp)
    }()

    private lazy var menuButton = {
        let button = CircleButton(radius: 20, systemImage: "square")
        return button
    }()

    init(onPanUp: @escaping (CGFloat) -> Void) {
        self.onPanUp = onPanUp
        super.init(effect: UIBlurEffect(style: .systemMaterial))

        contentView.addSubview(backButton)
        contentView.addSubview(urlBarView)
        contentView.addSubview(menuButton)

        let margin: CGFloat = 12

        backButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: topAnchor, constant: margin),
            backButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 1.5 * margin),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        urlBarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            urlBarView.topAnchor.constraint(equalTo: topAnchor, constant: margin),
            urlBarView.leftAnchor.constraint(equalTo: backButton.rightAnchor, constant: margin),
            urlBarView.rightAnchor.constraint(equalTo: menuButton.leftAnchor, constant: -margin),
            urlBarView.heightAnchor.constraint(equalToConstant: 40)
        ])

        menuButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            menuButton.topAnchor.constraint(equalTo: topAnchor, constant: margin),
            menuButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -1.5 * margin),
            menuButton.widthAnchor.constraint(equalToConstant: 40),
            menuButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
