import Combine
import WebKit

final class WebViewRef: Identifiable {
    typealias ID = UUID

    let id: ID
    let webView: WKWebView
    let model: WebContentModel
    let openerRef: WebViewRef?
    private var subscriptions: Set<AnyCancellable> = []

    private static var allRefs = [ID: WebViewRef]()

    init(webView: WKWebView, openerRef: WebViewRef? = nil) {
        id = .init()
        self.webView = webView
        model = .init()
        self.openerRef = openerRef

        Self.allRefs[id] = self // TODO: Replace with TabsModel

        setupObservers()
    }

    convenience init(forIncognito incognito: Bool) {
        self.init(webView: Self.createWebView(configuration: WebViewConfiguration.for(incognito: incognito)))
    }

    // TODO: Replace with TabsModel
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

    private func setupObservers() {
        webView.publisher(for: \.url, options: [.initial]).sink { [weak self] url in
            self?.model.url = url
        }.store(in: &subscriptions)

        webView.publisher(for: \.title, options: [.new]).sink { [weak self] title in
            self?.model.title = title
        }.store(in: &subscriptions)

        webView.publisher(for: \.canGoBack, options: [.initial]).sink { [weak self] canGoBack in
            guard let self else { return }
            if canGoBack {
                model.canGoBack = true
                model.canGoBackToOpener = false
            } else {
                let hasOpenerRef = openerRef != nil
                model.canGoBack = hasOpenerRef
                model.canGoBackToOpener = hasOpenerRef
            }
        }.store(in: &subscriptions)

        webView.publisher(for: \.canGoForward, options: [.initial]).sink { [weak self] canGoForward in
            self?.model.canGoForward = canGoForward
        }.store(in: &subscriptions)

        Publishers.CombineLatest(
            webView.publisher(for: \.isLoading, options: [.initial]),
            webView.publisher(for: \.estimatedProgress, options: [.initial])
        ).sink { [weak self] in
            self?.model.updateProgress(isLoading: $0.0, estimatedProgress: $0.1)
        }.store(in: &subscriptions)
    }
}
