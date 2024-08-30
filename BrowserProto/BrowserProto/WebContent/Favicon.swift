import Foundation
import UIKit

final class Favicon {
    let url: URL
    let image: ImageRef?

    init(url: URL, image: ImageRef?) {
        self.url = url
        self.image = image
    }
}
