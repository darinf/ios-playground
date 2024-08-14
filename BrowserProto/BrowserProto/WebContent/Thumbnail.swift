import Foundation
import UIKit

struct Thumbnail {
    typealias ID = UUID

    let id: ID
    let image: UIImage

    init(id: ID, image: UIImage) {
        self.id = id
        self.image = image
    }
}
