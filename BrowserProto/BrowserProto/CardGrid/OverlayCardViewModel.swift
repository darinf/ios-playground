import Combine
import UIKit

final class OverlayCardViewModel {
    enum State: Equatable {
        case hidden
        case transitionToGrid(card: Card?, cardAt: CGRect?)
        case transitionToZoomed(card: Card?, cardAt: CGRect?)
    }

    @Published var state: State = .hidden
}
