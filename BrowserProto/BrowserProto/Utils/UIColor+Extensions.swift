import UIKit

extension UIColor {
    var isDarkColor: Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Calculate luminance
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue

        // Determine if color is dark
        return luminance < 0.5
    }
}
