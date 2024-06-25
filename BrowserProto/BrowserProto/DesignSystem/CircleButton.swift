import UIKit

final class CircleButton: UIButton {
    init(radius: CGFloat, systemImage: String) {
        let diameter = 2 * radius
        super.init(frame: .init(origin: .zero, size: .init(width: diameter, height: diameter)))

        backgroundColor = .systemBackground
        layer.cornerRadius = 0.5 * bounds.size.width
        clipsToBounds = true

        if let image = UIImage(systemName: systemImage) {
            setImage(image, for: .normal)
        }
        tintColor = Colors.foregroundText

        addTarget(self, action: #selector(onPressed), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func onPressed() {
        print(">>> onPressed")
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? .systemFill : .systemBackground
        }
    }
}
