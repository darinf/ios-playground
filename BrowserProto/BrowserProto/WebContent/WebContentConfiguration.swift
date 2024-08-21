import WebKit

typealias WebContentConfiguration = WKWebViewConfiguration

extension WebContentConfiguration {
    static func `for`(incognito: Bool) -> WebContentConfiguration {
        incognito ? incognitoConfiguration : normalConfiguration
    }

    static var userAgentString: String = {
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
    }()

    private static var normalConfiguration = makeConfiguration(websiteDataStore: .default())
    private static var incognitoConfiguration = makeConfiguration(websiteDataStore: .nonPersistent())

    private static func makeConfiguration(websiteDataStore: WKWebsiteDataStore) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        configuration.allowsInlineMediaPlayback = true
        configuration.ignoresViewportScaleLimits = true
        configuration.websiteDataStore = websiteDataStore

        let controller = WKUserContentController()
        FaviconObserver.setup(userContentController: controller)
        configuration.userContentController = controller

        return configuration
    }
}
