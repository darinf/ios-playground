import WebKit

struct WebViewRef: Identifiable {
    let id: UUID
    let webView: WKWebView

    init(webView: WKWebView) {
        self.id = .init()
        self.webView = webView
    }
}
