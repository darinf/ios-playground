import UIKit

struct Card: Identifiable {
    typealias ID = UUID

    let id: ID
    var title: String?
    var favicon: UIImage?
    var thumbnail: UIImage?
}
