import UIKit

struct Card: Identifiable {
    typealias ID = UUID

    let id: ID
    var title: String?
    var favicon: UIImage?
    var thumbnail: UIImage?
}

extension Card: Equatable {
    static func == (a: Card, b: Card) -> Bool {
        a.id == b.id
    }
}
