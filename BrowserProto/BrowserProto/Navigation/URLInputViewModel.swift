import Combine

final class URLInputViewModel {
    @Published private(set) var showing: Bool = false
    @Published private(set) var text: String = ""

    func show() {
        showing = true
    }

    func dismiss(withResult result: String? = nil) {
        if let result {
            text = result
        }
        showing = false
    }
}
