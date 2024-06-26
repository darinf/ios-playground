import UIKit

enum DropShadow {
    static func apply(toLayer layer: CALayer) {
        // TODO: According to https://www.hackingwithswift.com/example-code/uikit/how-to-add-a-shadow-to-a-uiview
        // there are ways we can optimize this.
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 4
        layer.shadowOffset = .init(width: 1, height: 1)
    }
}
