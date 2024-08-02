import Combine
import Foundation

final class CenterButtonViewModel {
    enum Mode {
        case showAsText
        case showAsPlus
    }

    @Published var mode: Mode = .showAsText
    @Published var text: String = ""
    @Published var progress: Double?
}
