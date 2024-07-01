import UIKit

class CapsuleButton: UIButton {
    private let clicked: () -> Void
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)

    var defaultBackgroundColor: UIColor = .systemBackground {
        didSet {
            backgroundColor = defaultBackgroundColor
        }
    }

    init(cornerRadius: CGFloat, systemImage: String? = nil, clicked: @escaping () -> Void) {
        self.clicked = clicked
        super.init(frame: .zero)

        backgroundColor = defaultBackgroundColor
        layer.cornerRadius = cornerRadius
        DropShadow.apply(toLayer: layer)

        if let systemImage, let image = UIImage(systemName: systemImage) {
            setImage(image, for: .normal)
        }
        tintColor = Colors.foregroundText
        setTitleColor(Colors.foregroundText, for: .normal)

        addTarget(self, action: #selector(onPressed), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func onPressed() {
        feedbackGenerator.impactOccurred(intensity: 0.7)
        self.clicked()
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? .systemFill : defaultBackgroundColor
        }
    }
}
