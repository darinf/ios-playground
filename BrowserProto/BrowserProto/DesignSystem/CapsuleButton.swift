import UIKit

class CapsuleButton: UIButton {
    private let clicked: () -> Void

    init(cornerRadius: CGFloat, systemImage: String? = nil, clicked: @escaping () -> Void) {
        self.clicked = clicked
        super.init(frame: .zero)

        backgroundColor = .systemBackground
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
        self.clicked()
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? .systemFill : .systemBackground
        }
    }
}