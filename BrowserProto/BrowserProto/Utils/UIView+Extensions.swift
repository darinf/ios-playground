import UIKit

extension UIView {
    func activateContainmentConstraints(inside parent: UIView, withInsets insets: UIEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leftAnchor.constraint(equalTo: parent.leftAnchor, constant: insets.left),
            rightAnchor.constraint(equalTo: parent.rightAnchor, constant: -insets.right),
            topAnchor.constraint(equalTo: parent.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -insets.bottom)
        ])
    }

    func captureAsImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        self.layer.render(in: context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
