import WebKit

enum WebViewConfiguration {
    static func `for`(incognito: Bool) -> WKWebViewConfiguration {
        return incognito ? incognitoConfiguration : normalConfiguration
    }

    static var userAgentString: String = {
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
    }()

    private static var userContentController = {
        let controller = WKUserContentController()
        FaviconObserver.setup(userContentController: controller)
        return controller
    }()

    private static var normalConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        configuration.allowsInlineMediaPlayback = true
        configuration.ignoresViewportScaleLimits = true
        configuration.websiteDataStore = .default()
        configuration.userContentController = userContentController
        return configuration
    }()

    private static var incognitoConfiguration = {
        let configuration = normalConfiguration
        configuration.websiteDataStore = .nonPersistent()
        return configuration
    }()
}
