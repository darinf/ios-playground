import Combine
import WebKit

final class WebContent: Identifiable {
    typealias ID = UUID

    let id: ID
    let webView: WKWebView
    let opener: WebContent?

    @Published var url: URL?
    @Published var title: String?
    @Published var favicon: Favicon?
    @Published var thumbnail: Thumbnail?
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var canGoBackToOpener: Bool = false
    @Published private(set) var progress: Double?

    private var subscriptions: Set<AnyCancellable> = []

    private static var allWebContent = [ID: WebContent]()

    init(
        webView: WKWebView,
        opener: WebContent? = nil,
        withID id: ID = .init(),
        withFavicon favicon: Favicon? = nil,
        withThumbnail thumbnail: Thumbnail? = nil
    ) {
        self.id = id
        self.webView = webView
        self.opener = opener
        self.favicon = favicon
        self.thumbnail = thumbnail

        Self.allWebContent[id] = self // TODO: Replace with TabsModel

        setupObservers()
    }

    convenience init(
        forIncognito incognito: Bool,
        withID id: ID = .init(),
        withFavicon favicon: Favicon? = nil,
        withThumbnail thumbnail: Thumbnail? = nil
    ) {
        self.init(
            webView: Self.createWebView(configuration: WebContentConfiguration.for(incognito: incognito)),
            withID: id,
            withFavicon: favicon,
            withThumbnail: thumbnail
        )
    }

    // TODO: Replace with TabsModel
    static func from(id: ID?) -> WebContent? {
        guard let id else { return nil }
        return allWebContent[id]
    }

    static func from(webView: WKWebView) -> WebContent? {
        allWebContent.first(where: { $0.value.webView == webView })?.value
    }

    static func createWebView(configuration: WebContentConfiguration) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = WebContentConfiguration.userAgentString
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.clipsToBounds = false
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        return webView
    }

    private func setupObservers() {
        webView.publisher(for: \.url, options: [.initial]).sink { [weak self] url in
            self?.url = url
        }.store(in: &subscriptions)

        webView.publisher(for: \.title, options: [.new]).sink { [weak self] title in
            self?.title = title
        }.store(in: &subscriptions)

        webView.publisher(for: \.canGoBack, options: [.initial]).sink { [weak self] canGoBack in
            guard let self else { return }
            if canGoBack {
                self.canGoBack = true
                canGoBackToOpener = false
            } else {
                let hasOpener = opener != nil
                self.canGoBack = hasOpener
                canGoBackToOpener = hasOpener
            }
        }.store(in: &subscriptions)

        webView.publisher(for: \.canGoForward, options: [.initial]).sink { [weak self] canGoForward in
            self?.canGoForward = canGoForward
        }.store(in: &subscriptions)

        Publishers.CombineLatest(
            webView.publisher(for: \.isLoading, options: [.initial]),
            webView.publisher(for: \.estimatedProgress, options: [.initial])
        ).sink { [weak self] in
            self?.updateProgress(isLoading: $0.0, estimatedProgress: $0.1)
        }.store(in: &subscriptions)
    }

    private func updateProgress(isLoading: Bool, estimatedProgress: Double) {
        let progress: Double?
        if isLoading {
            progress = estimatedProgress
        } else {
            progress = nil
        }
        if self.progress != progress {
            self.progress = progress
        }
    }
}
