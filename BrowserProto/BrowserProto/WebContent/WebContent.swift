import Combine
import WebKit

final class WebContent: NSObject, Identifiable {
    typealias ID = UUID

    let id: ID
    let webView: WKWebView
    private(set) var opener: WebContent?

    @Published var url: URL?
    @Published var title: String?
    @Published var favicon: Favicon?
    @Published var thumbnail: Thumbnail?
    @Published var interactionState: Data?
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var canGoBackToOpener: Bool = false
    @Published private(set) var progress: Double?

    private var subscriptions: Set<AnyCancellable> = []

    private static var allWebContent = [ID: WeakBox<WebContent>]()

    init(
        webView: WKWebView,
        withOpener opener: WebContent? = nil,
        withID id: ID = .init(),
        withFavicon favicon: Favicon? = nil,
        withThumbnail thumbnail: Thumbnail? = nil,
        withInteractionState interactionState: Data? = nil
    ) {
        self.id = id
        self.webView = webView
        self.opener = opener
        self.favicon = favicon
        self.thumbnail = thumbnail
        self.interactionState = interactionState

        super.init()

        webView.interactionState = interactionState
        webView.navigationDelegate = self

        Self.allWebContent[id] = .init(self)

        setupObservers()
    }

    convenience init(
        forIncognito incognito: Bool,
        withOpener opener: WebContent? = nil,
        withID id: ID = .init(),
        withFavicon favicon: Favicon? = nil,
        withThumbnail thumbnail: Thumbnail? = nil,
        withInteractionState interactionState: Data? = nil
    ) {
        self.init(
            webView: Self.createWebView(configuration: WebContentConfiguration.for(incognito: incognito)),
            withOpener: opener,
            withID: id,
            withFavicon: favicon,
            withThumbnail: thumbnail,
            withInteractionState: interactionState
        )
    }

    deinit {
        Self.allWebContent[id] = nil
    }

    static func from(id: ID?) -> WebContent? {
        guard let id else { return nil }
        return allWebContent[id]?.object
    }

    static func from(webView: WKWebView) -> WebContent? {
        allWebContent.first(where: { $0.value.object?.webView == webView })?.value.object
    }

    static func createWebView(configuration: WebContentConfiguration) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = WebContentConfiguration.userAgentString
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.clipsToBounds = false
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        return webView
    }

    func updateThumbnail(completion: @escaping () -> Void = {}) {
        webView.takeSnapshot(with: nil) { [self] image, error in
            if let error {
                print(">>> takeSnapshot failed: \(error)")
            } else if let image {
                print(">>> takeSnapshot succeeded: \(image.size)")
            }
            thumbnail = .init(id: id, image: .init(image: image))
            completion()
        }
    }

    func dropOpener() {
        opener = nil
        canGoBackToOpener = false
    }

    private func setupObservers() {
        webView.publisher(for: \.url, options: [.initial]).sink { [weak self] url in
            guard let self else { return }
            self.url = url
            interactionState = webView.interactionState as? Data
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

extension WebContent: WKNavigationDelegate {
    func webView(_ webView: WKWebView, respondTo challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        return (.performDefaultHandling, challenge.proposedCredential)
    }
}
