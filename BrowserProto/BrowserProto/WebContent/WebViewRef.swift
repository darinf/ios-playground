import WebKit

final class WebViewRef: Identifiable {
    typealias ID = UUID

    let id: ID
    let webView: WKWebView
    let openerRef: WebViewRef?

    private static var allRefs = [ID: WebViewRef]()

    init(webView: WKWebView, openerRef: WebViewRef? = nil) {
        id = .init()
        self.webView = webView
        self.openerRef = openerRef

        Self.allRefs[id] = self // TODO: How do we avoid leaks?
    }

    convenience init(forIncognito incognito: Bool) {
        self.init(webView: Self.createWebView(configuration: WebViewConfiguration.for(incognito: incognito)))
    }

    static func from(id: ID?) -> WebViewRef? {
        guard let id else { return nil }
        return allRefs[id]
    }

    static func createWebView(configuration: WKWebViewConfiguration) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = WebViewConfiguration.userAgentString
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.clipsToBounds = false
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        return webView
    }
}
