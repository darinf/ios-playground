import SDWebImage
import WebKit

class FaviconObserver: NSObject, WKScriptMessageHandler {
    // Adapted from https://github.com/mozilla/page-metadata-parser
    static let source = """
        window.webkit.messageHandlers.FaviconObserver.postMessage(function() {
            var queries = [
                'link[rel="apple-touch-icon"]',
                'link[rel="apple-touch-icon-precomposed"]',
                'link[rel="icon" i]',
                'link[rel="fluid-icon"]',
                'link[rel="shortcut icon"]',
                'link[rel="Shortcut Icon"]',
                'link[rel="mask-icon"]'
            ]
            var bestSize = 0
            var bestHref = ""
            for (query of queries) {
                var elements = document.querySelectorAll(query)
                if (elements.length > 0) {
                    for (element of elements) {
                        const sizes = element.getAttribute('sizes');
                        if (sizes) {
                            const sizeMatches = sizes.match(/\\d+/g);
                            if (sizeMatches) {
                                const size = sizeMatches[0]
                                if (size > bestSize) {
                                    bestSize = size
                                    bestHref = element.getAttribute('href')
                                }
                            }
                        }
                        if (bestHref == "") {
                            bestHref = element.getAttribute('href')
                        }
                    }
                }
            }
            if (bestHref == "") {
                bestHref = "/favicon.ico"
            }
            return new URL(bestHref, document.URL).href
        }())
    """

    static func setup(userContentController: WKUserContentController) {
        userContentController.add(
            FaviconObserver(),
            contentWorld: .defaultClient,
            name: "FaviconObserver"
        )

        let userScript: WKUserScript = .init(
            source: source,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true,
            in: .defaultClient
        )
        userContentController.addUserScript(userScript)
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let urlString = message.body as? String,
              let url = URL(string: urlString),
              let webView = message.webView
        else { return }
        Task { @MainActor in
            var favicon = await fetchFavicon(at: url)
            if favicon == nil, let fallbackURL = URL(string: "/favicon.ico", relativeTo: webView.url) {
                favicon = await fetchFavicon(at: fallbackURL)
            }
            WebContent.from(webView: webView)?.favicon = favicon
        }
    }

    @MainActor
    private func fetchFavicon(at url: URL) async -> Favicon? {
        await withCheckedContinuation { continuation in
            SDWebImageManager.shared.loadImage(with: url, progress: nil) { image, _, _, _, _, _ in
                continuation.resume(returning: image.map { .init(url: url, image: .init(image: $0)) })
            }
        }
    }
}
