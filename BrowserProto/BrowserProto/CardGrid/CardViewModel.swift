import Combine
import UIKit

final class CardViewModel {
    @Published var selected: Bool
    @Published var thumbnail: UIImage?
    @Published var title: String = ""
    @Published var icon: UIImage?
    @Published var hideCloseButton: Bool = false
    @Published var disableCornerRadius: Bool = false

    init(selected: Bool, thumbnail: UIImage?) {
        self.selected = selected
        self.thumbnail = thumbnail
    }
}
