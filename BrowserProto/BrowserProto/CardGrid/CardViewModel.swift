import Combine
import UIKit

final class CardViewModel {
    let card: Card?

    @Published var selected: Bool
    @Published var hideDecorations: Bool = false

    init(card: Card?, selected: Bool) {
        self.card = card
        self.selected = selected
    }
}
