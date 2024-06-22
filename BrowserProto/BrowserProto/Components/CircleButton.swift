import UIKit

/*
final class CircleButton: UIView {
    init(radius: CGFloat, systemImage: String) {
        let diameter = 2 * radius
        super.init(frame: .init(origin: .zero, size: .init(width: diameter, height: diameter)))

        isUserInteractionEnabled = true

        let button = UIButton()
        button.isUserInteractionEnabled = true
        button.frame = frame
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 0.5 * bounds.size.width
        button.clipsToBounds = true

        if let image = UIImage(systemName: systemImage) {
            button.setImage(image, for: .normal)
        }
        button.tintColor = .systemGray2

        button.isEnabled = true
        //addTarget(self, action: #selector(thumbsUpButtonPressed), for: .touchUpInside)
        addSubview(button)

        button.addTarget(self, action: #selector(onPressed), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func onPressed() {
        print(">>> onPressed")
    }
}
*/

final class CircleButton: UIButton {
    init(radius: CGFloat, systemImage: String) {
        let diameter = 2 * radius
        super.init(frame: .init(origin: .zero, size: .init(width: diameter, height: diameter)))

        print(">>> bounds: \(bounds)")

        backgroundColor = .systemBackground
        layer.cornerRadius = 0.5 * bounds.size.width
        clipsToBounds = true

        if let image = UIImage(systemName: systemImage) {
            setImage(image, for: .normal)
        }
        tintColor = .systemGray2

        isEnabled = true
        //addTarget(self, action: #selector(thumbsUpButtonPressed), for: .touchUpInside)
        //        addSubview(button)

        addTarget(self, action: #selector(onPressed), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func onPressed() {
        print(">>> onPressed")
    }
}
