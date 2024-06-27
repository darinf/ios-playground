import UIKit

enum DropShadow {
    static func apply(toLayer layer: CALayer) {
        // TODO: According to https://www.hackingwithswift.com/example-code/uikit/how-to-add-a-shadow-to-a-uiview
        // there are ways we can optimize this.
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 2
        layer.shadowOffset = .init(width: 0.5, height: 0.5)
    }
}
