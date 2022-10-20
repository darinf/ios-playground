// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import Foundation
import UIKit
import WebKit

fileprivate func userAgentString() -> String {
    let version = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")
    return "Mozilla/5.0 (iPhone; CPU iPhone OS \(version) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
}

// One of these per tab
class WebContentsCardModel: NSObject, CardModel {
    // CardModel fields:
    var id: UUID
    @Published private(set) var title: String = ""
    @Published private(set) var thumbnail = pixelFromColor(.white)
    @Published private(set) var favicon = UIImage(systemName: "globe")!

    @Published private(set) var url: URL? = nil
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var estimatedProgress: Double = 0.0

    // If overlays should be hidden b/c the content is being scrolled
    @Published private(set) var hideOverlays: Bool = false

    // Notifies on creation of a new child card (WebView).
    let childCardPublisher = PassthroughSubject<WebContentsCardModel, Never>()

    private let context: WebContentsContext
    private var scrollViewObserver: ScrollViewObserver?
    private let configuration: WKWebViewConfiguration
    private var subscriptions: Set<AnyCancellable> = []
    private let backgroundQueue = DispatchQueue(label: "background-queue")
    private let storedCard: StoredCard

    init(
        context: WebContentsContext,
        url: URL?,
        withConfiguration configuration: WKWebViewConfiguration? = nil
    ) {
        self.id = UUID()
        self.context = context
        self.url = url
        self.configuration = configuration ?? context.defaultConfiguration
        self.storedCard = StoredCard(store: context.store)
        super.init()

        initializeStoredCard()
        keepStoredCardUpdated()
    }

    // Called as part of session restore. OK to block on image decoding.
    // TODO: Consider performing image decoding on the background queue instead.
    init(
        context: WebContentsContext,
        storedCard: StoredCard
    ) {
        precondition(storedCard.id != nil)

        self.id = storedCard.id!
        self.title = storedCard.title ?? ""
        self.url = URL(string: storedCard.url)
        self.thumbnail = Self.decodeImage(from: storedCard.thumbnail)
        self.context = context
        self.configuration = context.defaultConfiguration
        self.storedCard = storedCard
        super.init()

        keepStoredCardUpdated()
    }

    lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.uiDelegate = self  // weak reference
        webView.navigationDelegate = self  // weak reference
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = userAgentString()

        webView.publisher(for: \.url, options: .new).receive(on: DispatchQueue.main)
            .assign(to: &$url)
        webView.publisher(for: \.title, options: .new).receive(on: DispatchQueue.main)
            .map { $0 != nil ? $0! : "" }.assign(to: &$title)
        webView.publisher(for: \.isLoading, options: .new).receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        webView.publisher(for: \.estimatedProgress, options: .new).receive(on: DispatchQueue.main)
            .assign(to: &$estimatedProgress)

        Self.addRefreshControl(to: webView)

        webView.scrollView.clipsToBounds = false

        scrollViewObserver = .init(scrollView: webView.scrollView)
        scrollViewObserver?.$direction.receive(on: DispatchQueue.main)
            .map { $0 == .down }.assign(to: &$hideOverlays)

        if let url = url {
            webView.load(URLRequest(url: url))
        }

        return webView
    }()

    func navigate(to url: URL) {
        webView.load(URLRequest(url: url))
    }

    func updateThumbnail(completion: @escaping () -> Void) {
        webView.stopLoading()
        webView.takeSnapshot(with: nil) { image, error in
            // No idea what thread this comes in on, so make sure we are on main.
            DispatchQueue.main.async {
                if let image = image {
                    self.thumbnail = image
                }
                completion()
            }
        }
    }

    private static func addRefreshControl(to webView: WKWebView) {
        let rc = UIRefreshControl(
            frame: .zero,
            primaryAction: UIAction { [weak webView] _ in
                webView?.reload()
                // Dismiss refresh control now as the regular progress bar will soon appear.
                webView?.scrollView.refreshControl?.endRefreshing()
            })
        webView.scrollView.refreshControl = rc
        webView.scrollView.bringSubviewToFront(rc)
    }
}

// MARK: Storage

extension WebContentsCardModel {
    private static func decodeImage(from data: Data?, fallback: (() -> UIImage) = { pixelFromColor(.white) }) -> UIImage {
        let result: UIImage
        if let data = data, let image = UIImage(data: data) {
            result = image
        } else {
            result = fallback()
        }
        return result
    }

    private func initializeStoredCard() {
        storedCard.id = id
        context.store.save()
    }

    private func keepStoredCardUpdated() {
        // TODO: Consider batching calls to store.save()

        $url
            .dropFirst()
            .map { $0?.absoluteString ?? "" }
            .sink { [storedCard, context] url in
                if url != storedCard.url {
                    storedCard.url = url
                    context.store.save()
                }
            }
            .store(in: &subscriptions)

        $title
            .dropFirst()
            .sink { [storedCard, context] title in
                if title != storedCard.title {
                    storedCard.title = title
                    context.store.save()
                }
            }
            .store(in: &subscriptions)

        // Run image encoding off the main thread.
        $thumbnail
            .dropFirst()
            .receive(on: backgroundQueue)
            .map { $0.pngData() }
            .receive(on: DispatchQueue.main)
            .sink { [storedCard, context] thumbnail in
                storedCard.thumbnail = thumbnail
                context.store.save()
            }
            .store(in: &subscriptions)
    }
}


// MARK: WebViewDelegates

extension WebContentsCardModel: WKUIDelegate {
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        let newCard = WebContentsCardModel(
            context: context, url: nil, withConfiguration: configuration)
        childCardPublisher.send(newCard)

        // Reset to show overlays for when it is next selected.
        hideOverlays = false

        return newCard.webView
    }
}

extension WebContentsCardModel: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        print(">>> error: \(error.localizedDescription)")
    }
}
