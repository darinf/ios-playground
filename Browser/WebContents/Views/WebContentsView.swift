// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import SwiftUI
import WebKit

class OverlayManager: ObservableObject {
    var updater: OverlayUpdater?
    var subscription: AnyCancellable?

    func setup(for webView: WKWebView, with overlayModel: OverlayModel) {
        updater = .init(scrollView: webView.scrollView, overlayModel: overlayModel)

        subscription = webView.publisher(for: \.url, options: .new).sink { _ in
            overlayModel.resetHeight()
        }
    }
}

struct WebViewContainerView: UIViewRepresentable {
    let webView: WKWebView
    let overlayModel: OverlayModel

    @StateObject private var overlayManager = OverlayManager()

    func makeUIView(context: Context) -> UIView {
        return UIView()
    }

    func updateUIView(_ view: UIView, context: Context) {
        guard view.subviews.count != 1 || view.subviews.first != webView else { return }

        DispatchQueue.main.async {
            view.subviews.forEach { $0.removeFromSuperview() }
            view.addSubview(webView)

            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true

            webView.scrollView.clipsToBounds = false

            overlayManager.setup(for: webView, with: overlayModel)

            addRefreshControl(to: webView)
        }
    }

    private func addRefreshControl(to webView: WKWebView) {
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

struct WebContentsView: View {
    @ObservedObject var card: WebContentsCardModel
    @EnvironmentObject var overlayModel: OverlayModel

    var body: some View {
        WebViewContainerView(webView: card.webView, overlayModel: overlayModel)
            .padding(.bottom, overlayModel.height)
    }
}
