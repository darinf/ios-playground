import Foundation
import UIKit

final class Thumbnail {
    typealias ID = UUID

    let id: ID
    let image: ImageRef?

    init(id: ID, image: ImageRef?) {
        self.id = id
        self.image = image
    }
}
