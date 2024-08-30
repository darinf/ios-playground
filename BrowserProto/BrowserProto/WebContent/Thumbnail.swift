import Foundation
import UIKit

final class Thumbnail {
    typealias ID = UUID

    private enum Backing {
        case none
        case image(UIImage)
        case lazyLoad(() -> UIImage?)
    }

    let id: ID
    private var backing: Backing

    var image: UIImage? {
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

    init(id: ID, image: UIImage?) {
        self.id = id
        if let image {
            backing = .image(image)
        } else {
            backing = .none
        }
    }

    init(id: ID, provider: @escaping () -> UIImage?) {
        self.id = id
        backing = .lazyLoad(provider)
    }
}
