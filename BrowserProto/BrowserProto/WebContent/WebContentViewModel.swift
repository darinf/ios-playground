import Foundation
import Combine
import UIKit

final class WebContentViewModel {
    @Published var url: URL?
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var progress: Double?
    @Published var panningDeltaY: CGFloat?

//    struct PanningState {
//        let panning: Bool
//        let deltaY: CGFloat
//    }
//    @Published var panningState: PanningState = .init(panning: false, deltaY: 0)
}
