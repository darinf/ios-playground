import Combine
import UIKit

final class CardViewModel {
    @Published var selected: Bool
    @Published var thumbnail: ImageRef?
    @Published var title: String?
    @Published var favicon: ImageRef?
    @Published var hideDecorations: Bool = false

    init(selected: Bool, thumbnail: ImageRef?, title: String?, favicon: ImageRef?) {
        self.selected = selected
        self.thumbnail = thumbnail
        self.title = title
        self.favicon = favicon
    }
}
