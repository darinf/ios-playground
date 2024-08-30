import UIKit

final class ImageRef {
    private enum Backing {
        case none
        case image(UIImage)
        case lazyLoad(() -> UIImage?)
    }

    private var backing: Backing

    var value: UIImage? {
        switch backing {
        case .none:
            return nil
        case let .image(image):
            return image
        case let .lazyLoad(provider):
            guard let image = provider() else {
                backing = .none
                return nil
            }
            backing = .image(image)
            return image
        }
    }

    var valueIfLoaded: UIImage? {
        switch backing {
        case .none, .lazyLoad:
            return nil
        case let .image(image):
            return image
        }
    }

    init(image: UIImage?) {
        if let image {
            backing = .image(image)
        } else {
            backing = .none
        }
    }

    init(provider: @escaping () -> UIImage?) {
        backing = .lazyLoad(provider)
    }
}
