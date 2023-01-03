// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import Foundation
import SDWebImage
import SwiftUI
import UIKit
import WebKit

fileprivate func userAgentString() -> String {
    let version = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")
    return "Mozilla/5.0 (iPhone; CPU iPhone OS \(version) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
}

// One of these per tab
class WebContentsCardModel: NSObject {
    static var all: [Weak<WebContentsCardModel>] = []
    static var defaultFavicon = UIImage(systemName: "globe")!

    // CardModel fields:
    var id: UUID
    @Published private(set) var title: String = ""
    @Published private(set) var thumbnail: UIImage
    @Published private(set) var favicon: UIImage

    @Published private(set) var url: URL? = nil
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var estimatedProgress: Double = 0.0

    @Published var nextId: UUID?

    // Notifies on creation of a new child card (WebView).
    let childCardPublisher = PassthroughSubject<WebContentsCardModel, Never>()

    private let context: WebContentsContext
    private(set) var scrollViewObserver: ScrollViewObserver?
    private let configuration: WKWebViewConfiguration
    private var subscriptions: Set<AnyCancellable> = []
    private let backgroundQueue = DispatchQueue(label: "background-queue")
    private let storedCard: StoredCard

    private var webView_: WKWebView?
    var webView: WKWebView {
        get {
            if let webView = webView_ {
                return webView
            }
            webView_ = createWebView()
            return webView_!
        }
    }

    init(
        context: WebContentsContext,
        url: URL?,
        withConfiguration configuration: WKWebViewConfiguration? = nil
    ) {
        self.id = UUID()
        self.context = context
        self.url = url
        self.configuration = configuration ?? context.defaultConfiguration
        self.thumbnail = pixelFromColor(.white)
        self.favicon = Self.defaultFavicon
        self.storedCard = StoredCard(store: context.store)
        super.init()

        Self.all.append(.init(self))

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
        self.nextId = storedCard.next
        self.title = storedCard.title ?? ""
        self.url = URL(string: storedCard.url)
        self.thumbnail = Self.decodeImage(from: storedCard.thumbnail)
        self.favicon = Self.decodeImage(from: storedCard.favicon, fallback: { Self.defaultFavicon })
        self.context = context
        self.configuration = context.defaultConfiguration
        self.storedCard = storedCard
        super.init()

        Self.all.append(.init(self))

        keepStoredCardUpdated()
    }

    func navigate(to url: URL) {
        webView.load(URLRequest(url: url))
    }

    private func createWebView() -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.uiDelegate = self  // weak reference
        webView.navigationDelegate = self  // weak reference
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = userAgentString()

        DispatchQueue.main.async { [self] in
            let options: NSKeyValueObservingOptions = [.new, .initial]
            webView.publisher(for: \.url, options: options)
                .assign(to: &$url)
            webView.publisher(for: \.title, options: options)
                .map { $0 != nil ? $0! : "" }.assign(to: &$title)
            webView.publisher(for: \.isLoading, options: options)
                .assign(to: &$isLoading)
            webView.publisher(for: \.estimatedProgress, options: options)
                .assign(to: &$estimatedProgress)
        }

        webView.interactionState = storedCard.interactionState

        return webView
    }
}

// MARK: CardModel

extension WebContentsCardModel: CardModel {
    func close() {
        subscriptions.removeAll()
        if let webView = webView_ {
            webView.removeFromSuperview()
            webView.uiDelegate = nil
            webView.navigationDelegate = nil
            webView_ = nil
        }
        deleteStoredCard()
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

    private func deleteStoredCard() {
        context.store.container.viewContext.delete(storedCard)
        context.store.save()
    }

    private func keepStoredCardUpdated() {
        // TODO: Consider batching calls to store.save()

        let storedCard = self.storedCard
        let store = context.store

        // Snapshot the interactionState as well whenever the url changes.
        $url
            .dropFirst()
            .map { $0?.absoluteString ?? "" }
            .sink { [unowned self] url in
                if url != storedCard.url {
                    storedCard.url = url
                    storedCard.interactionState = webView.interactionState as? Data
                    store.save()
                }
            }
            .store(in: &subscriptions)

        $title
            .dropFirst()
            .sink { title in
                if title != storedCard.title {
                    storedCard.title = title
                    store.save()
                }
            }
            .store(in: &subscriptions)

        // Run image encoding off the main thread.
        $thumbnail
            .dropFirst()
            .receive(on: backgroundQueue)
            .map { $0.pngData() }
            .receive(on: DispatchQueue.main)
            .sink { thumbnail in
                storedCard.thumbnail = thumbnail
                store.save()
            }
            .store(in: &subscriptions)

        // Run image encoding off the main thread.
        $favicon
            .dropFirst()
            .receive(on: backgroundQueue)
            .map { $0.pngData() }
            .receive(on: DispatchQueue.main)
            .sink { favicon in
                storedCard.favicon = favicon
                store.save()
            }
            .store(in: &subscriptions)

        $nextId
            .dropFirst()
            .sink { nextId in
                if nextId != storedCard.next {
                    storedCard.next = nextId
                    store.save()
                }
            }
            .store(in: &subscriptions)
    }
}

// MARK: WKUIDelegate

extension WebContentsCardModel: WKUIDelegate {
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        let newCard = WebContentsCardModel(
            context: context, url: nil, withConfiguration: configuration)
        childCardPublisher.send(newCard)

        return newCard.webView
    }
}

// MARK: WKNavigationDelegate

extension WebContentsCardModel: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        print(">>> error: \(error.localizedDescription)")
        // TODO: Show error page
    }
}

// MARK: Favicon support

extension WebContentsCardModel {
    func updateFavicon(urlString: String) {
        guard let url = URL(string: urlString) else { return }

        // TODO: De-dupe favicon images that may be repeated across cards.
        SDWebImageManager.shared.loadImage(
            with: url,
            progress: { _, _, _  in }
        ) { [self] image, _, _, _, _, _  in
            if let image {
                favicon = image
            }
        }
    }
}

// MARK: Lookup by WebView

extension WebContentsCardModel {
    static func fromWebView(_ webView: WKWebView) -> WebContentsCardModel? {
        for weakModel in all {
            if let model = weakModel.value, model.webView_ == webView {
                return model
            }
        }
        return nil
    }
}
