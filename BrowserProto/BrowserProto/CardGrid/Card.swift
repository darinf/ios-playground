import UIKit

struct Card: Identifiable {
    typealias ID = UUID

    let id: ID
    var title: String?
    var favicon: ImageRef?
    var thumbnail: ImageRef?
    var hidden: Bool = false
}

extension Card: Equatable {
    static func == (a: Card, b: Card) -> Bool {
        a.id == b.id
    }
}
