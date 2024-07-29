import WebKit

struct WebViewRef: Identifiable {
    typealias ID = UUID

    let id: ID
    let webView: WKWebView

    private static var allRefs = [ID: WebViewRef]()

    init(webView: WKWebView) {
        id = .init()
        self.webView = webView

        Self.allRefs[id] = self // TODO: How do we avoid leaks?
    }

    static func from(id: ID?) -> WebViewRef? {
        guard let id else { return nil }
        return allRefs[id]
    }
}
