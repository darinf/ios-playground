import Combine

final class URLInputViewModel {
    enum Mode {
        case showing(initialValue: String)
        case hidden
    }
    @Published var mode: Mode = .hidden
}
