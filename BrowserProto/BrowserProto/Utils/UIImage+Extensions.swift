import UIKit

extension UIImage {
    func scaled(to targetSize: CGSize) -> UIImage? {
        // Calculate the aspect ratio
        let widthRatio  = targetSize.width  / self.size.width
        let heightRatio = targetSize.height / self.size.height

        // Determine the scale factor to use
        let scaleFactor = min(widthRatio, heightRatio)

        // Calculate the new size based on the scale factor
        let newSize = CGSize(width: self.size.width * scaleFactor, height: self.size.height * scaleFactor)

        // Create the image context
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }

        // Draw the image in the context
        self.draw(in: CGRect(origin: .zero, size: newSize))

        // Get the new image
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    func clipped(to rect: CGRect) -> UIImage? {
        // Ensure the rect is within the bounds of the image
        let imageRect = CGRect(origin: .zero, size: self.size)
        let clippedRect = rect.intersection(imageRect)

        // Begin image context
        UIGraphicsBeginImageContextWithOptions(clippedRect.size, false, self.scale)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Translate and scale context to clip correctly
        context.translateBy(x: -clippedRect.origin.x, y: -clippedRect.origin.y)

        // Draw the image in the context
        self.draw(in: CGRect(origin: .zero, size: self.size))

        // Get the new image
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    func resizeTopAlignedToFill(newWidth: CGFloat) -> UIImage? {
        let newHeight = size.height * newWidth / size.width

        let newSize = CGSize(width: newWidth, height: newHeight)

        UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.main.scale)
        draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }

    static func create1x1(with color: UIColor) -> UIImage {
        let size = CGSize(width: 1, height: 1)

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()

        context?.setFillColor(color.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image!
    }
}
