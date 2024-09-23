import UIKit

struct Card: Identifiable {
    typealias ID = UUID

    enum Metrics {
        static let maxTiledImages = 3
    }

    enum MutableField {
        case title(String?)
        case favicon(ImageRef?)
        case content(Content)
        case hidden(Bool)
    }

    enum Content {
        case image(ImageRef?)
        case tiled([ImageRef?], overage: Int) // Up to Metrics.maxTiledImages images
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
