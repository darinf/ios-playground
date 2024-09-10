import UIKit

class CapsuleButton: UIButton {
    private let clicked: (() -> Void)?
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let hitAreaInset: CGFloat

    init(cornerRadius: CGFloat, hitAreaInset: CGFloat = .zero, systemImage: String? = nil, clicked: (() -> Void)? = nil) {
        self.clicked = clicked
        self.hitAreaInset = hitAreaInset
        super.init(frame: .zero)

        backgroundColor = .systemBackground
        layer.cornerRadius = cornerRadius
        DropShadow.apply(toLayer: layer)

        if let systemImage, let image = UIImage(systemName: systemImage) {
            setImage(image, for: .normal)
        }
        tintColor = Colors.foregroundText
        setTitleColor(Colors.foregroundText, for: .normal)

        if clicked != nil {
            addTarget(self, action: #selector(onPressed), for: .touchUpInside)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func onPressed() {
        feedbackGenerator.impactOccurred(intensity: 0.7)
        self.clicked?()
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? .systemFill : .systemBackground
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let extendedBounds = bounds.insetBy(dx: -hitAreaInset, dy: -hitAreaInset)
        return extendedBounds.contains(point) ? self : nil
    }
}
