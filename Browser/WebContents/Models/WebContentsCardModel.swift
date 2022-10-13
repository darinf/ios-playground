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
    let id = UUID().uuidString
    @Published private(set) var title: String = ""
    @Published private(set) var thumbnail = pixelFromColor(.white)
    @Published private(set) var favicon = UIImage(systemName: "globe")!

    @Published private(set) var url: URL? = nil

    // If overlays should be hidden b/c the content is being scrolled
    @Published private(set) var hideOverlays: Bool = false

    // Notifies on creation of a new child card (WebView).
    let childCardPublisher = PassthroughSubject<WebContentsCardModel, Never>()

    private var subscriptions: Set<AnyCancellable> = []
    private var scrollViewObserver: ScrollViewObserver?
    private let configuration: WKWebViewConfiguration

    init(url: URL? = nil) {
        self.url = url
        self.configuration = Self.configuration
    }

    init(withConfiguration configuration: WKWebViewConfiguration) {
        self.configuration = configuration
    }

    private static var configuration = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        configuration.ignoresViewportScaleLimits = true
        configuration.allowsInlineMediaPlayback = true
        return configuration
    }()

    lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.uiDelegate = self  // weak reference
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = userAgentString()

        webView.publisher(for: \.url, options: .new).sink { [weak self] url in
            DispatchQueue.main.async {
                self?.url = url
            }
        }.store(in: &subscriptions)

        webView.publisher(for: \.title, options: .new).sink { [weak self] title in
            DispatchQueue.main.async {
                self?.title = title ?? ""
            }
        }.store(in: &subscriptions)

        if let url = url {
            webView.load(URLRequest(url: url))
        }

        Self.addRefreshControl(to: webView)

        scrollViewObserver = .init(scrollView: webView.scrollView)
        scrollViewObserver?.$direction.sink { [weak self] direction in
            DispatchQueue.main.async {
                self?.hideOverlays = (direction == .down)
            }
        }.store(in: &subscriptions)

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

// MARK: WebViewDelegates

extension WebContentsCardModel: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

        let newCard = WebContentsCardModel(withConfiguration: configuration)
        childCardPublisher.send(newCard)

        return newCard.webView
    }
}
