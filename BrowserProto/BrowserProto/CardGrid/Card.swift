import UIKit

struct Card: Identifiable {
    typealias ID = UUID

    enum MutableField {
        case title(String?)
        case favicon(ImageRef?)
        case content(Content)
        case hidden(Bool)
    }

    enum Content {
        case image(ImageRef?)
        case tiled([ImageRef?], overage: Int) // Up to 3 images
    }

    let id: ID
    var title: String?
    var favicon: ImageRef?
    var content: Content = .image(nil)
    var hidden: Bool = false
}

extension Card: Equatable {
    static func == (a: Card, b: Card) -> Bool {
        a.id == b.id
    }
}
