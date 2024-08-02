import Combine
import UIKit

final class CardViewModel {
    @Published var selected: Bool
    @Published var thumbnail: UIImage?

    init(selected: Bool, thumbnail: UIImage?) {
        self.selected = selected
        self.thumbnail = thumbnail
    }
}
