import UIKit

enum DropShadow {
    static func apply(toLayer layer: CALayer) {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 4
        layer.shadowOffset = .init(width: 1, height: 1)
    }
}
