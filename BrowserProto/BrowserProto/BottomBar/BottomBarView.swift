import UIKit

enum BottomBarViewConstants {
    static let baseHeight: CGFloat = 44.0
}

final class BottomBarView: UIVisualEffectView {
    private lazy var backButton = {
        let button = CircleButton(radius: 20, systemImage: "arrowtriangle.backward")
        return button
    }()

    private lazy var menuButton = {
        let button = CircleButton(radius: 20, systemImage: "square")
        return button
    }()

    init() {
        super.init(effect: UIBlurEffect(style: .systemMaterial))

        contentView.addSubview(backButton)
        contentView.addSubview(menuButton)

        backButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            backButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 8),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        menuButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            menuButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            menuButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -8),
            menuButton.widthAnchor.constraint(equalToConstant: 40),
            menuButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
