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
        self.init(webView: Self.createWebView(configuration: Self.configuration(forIncognito: incognito)))
    }

    static func from(id: ID?) -> WebViewRef? {
        guard let id else { return nil }
        return allRefs[id]
    }

    static func createWebView(configuration: WKWebViewConfiguration) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = userAgentString
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.clipsToBounds = false
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        return webView
    }

    private static var userAgentString: String = {
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
    }()

    private static var normalConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.ignoresViewportScaleLimits = true
        configuration.websiteDataStore = .default()
        return configuration
    }()

    private static var incognitoConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.ignoresViewportScaleLimits = true
        configuration.websiteDataStore = .nonPersistent()
        return configuration
    }()

    private static func configuration(forIncognito incognito: Bool) -> WKWebViewConfiguration {
        print(">>> configuration for incognito: \(incognito)")
        return incognito ? incognitoConfiguration : normalConfiguration
    }
}
