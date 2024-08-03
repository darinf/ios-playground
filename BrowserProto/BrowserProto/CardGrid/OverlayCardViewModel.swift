import Combine
import UIKit

final class OverlayCardViewModel {
    enum State {
        case hidden
        case transitionToGrid(thumbnail: UIImage?, cardAt: CGRect?)
        case transitionToZoomed(thumbnail: UIImage?, cardAt: CGRect?)
    }

    @Published var state: State = .hidden
}
