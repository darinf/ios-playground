import WebKit

final class WebViewStore {
    static let shared = WebViewStore()

    private var webViews: [WebViewID: WKWebView] = [:]

    func insert(_ webView: WKWebView, withID id: WebViewID) {
        webViews[id] = webView
    }

    func remove(byID id: WebViewID) {
        webViews[id] = nil
    }

    func lookup(byID id: WebViewID) -> WKWebView? {
        webViews[id]
    }
}
