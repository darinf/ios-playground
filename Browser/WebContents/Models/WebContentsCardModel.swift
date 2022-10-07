// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import Foundation
import UIKit
import WebKit

// One of these per tab
class WebContentsCardModel: CardModel {
    // CardModel fields:
    let id = UUID().uuidString
    @Published private(set) var title: String = ""
    @Published private(set) var thumbnail = UIImage(systemName: "plus")!
    @Published private(set) var favicon = UIImage(systemName: "plus")!

    @Published private(set) var url: URL?

    // If overlays should be hidden b/c the content is being scrolled
    @Published private(set) var hideOverlays: Bool = false

    private var subscriptions: Set<AnyCancellable> = []
    private var scrollViewObserver: ScrollViewObserver?

    init(url: URL? = nil) {
        self.url = url
    }

    private static var configuration = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        return configuration
    }()

    lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero, configuration: Self.configuration)
        webView.allowsBackForwardNavigationGestures = true

        webView.publisher(for: \.url, options: .new).sink { url in
            DispatchQueue.main.async {
                self.url = url
            }
        }.store(in: &subscriptions)

        webView.publisher(for: \.title, options: .new).sink { title in
            DispatchQueue.main.async {
                self.title = title ?? ""
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

    func prepareToShowAsThumbnail(completion: @escaping () -> Void) {
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
