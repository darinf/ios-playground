import Combine
import UIKit

final class CardViewModel {
    @Published var selected: Bool
    @Published var thumbnail: UIImage?
    @Published var title: String?
    @Published var favicon: UIImage?
    @Published var hideDecorations: Bool = false

    init(selected: Bool, thumbnail: UIImage?, title: String?, favicon: UIImage?) {
        self.selected = selected
        self.thumbnail = thumbnail
        self.title = title
        self.favicon = favicon
    }
}
