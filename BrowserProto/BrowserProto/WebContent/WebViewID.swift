import Foundation

struct WebViewID: Identifiable, Hashable {
    typealias ID = String

    let id: ID

    init() {
        id = UUID().uuidString
    }
}
