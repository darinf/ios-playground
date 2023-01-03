// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import SwiftUI
import WebKit

class WebViewController: UIViewController {
    var webView: WKWebView?
    var overlayModel: OverlayModel?
    var overlayUpdater: OverlayUpdater?
    var subscriptions: Set<AnyCancellable> = []

    func updateWebView(webView: WKWebView, overlayModel: OverlayModel) {
        self.webView = webView
        self.overlayModel = overlayModel

        view.subviews.forEach { $0.removeFromSuperview() }
        view.addSubview(webView)
        setupConstraints()

        addRefreshControl(to: webView)

        overlayUpdater = .init(scrollView: webView.scrollView, overlayModel: overlayModel)

        webView.scrollView.contentInsetAdjustmentBehavior = .always

        // Important that we restore the toolbars whenever the URL is changed or else
        // WebKit will not properly restore scroll position when going back/forward.
        webView.publisher(for: \.url, options: .new).sink { url in
            overlayModel.resetHeight()
        }.store(in: &subscriptions)

        Publishers.CombineLatest(
            overlayModel.$docked,
            overlayModel.$height
        )
        .sink { [unowned self] docked, height in
            updateBottomInsets(docked: docked, height: height)
        }.store(in: &subscriptions)

        overlayModel.$interactivelyChangingHeight.scan((false, false)) {
            ($0.1, $1)
        }
        .sink { [unowned webView] interactivelyChangingHeight in
            if !interactivelyChangingHeight.0 && interactivelyChangingHeight.1 {
                // Started interactively changing height
                webView.perform(NSSelectorFromString("_beginInteractiveObscuredInsetsChange"))
            } else if interactivelyChangingHeight.0 && !interactivelyChangingHeight.1 {
                // Stopped interactively changing height
                webView.perform(NSSelectorFromString("_endInteractiveObscuredInsetsChange"))
            }
        }
        .store(in: &subscriptions)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view = UIView()
    }

    func setupConstraints() {
        guard let webView else { return }

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
    }

    func updateBottomInsets(docked: Bool, height: CGFloat) {
        guard let webView else { return }

        let bottomBarHeight = docked ? height : 0
        let bottomSafeAreaInset = view.window?.safeAreaInsets.bottom ?? 0

        additionalSafeAreaInsets = .init(
            top: 0, left: 0, bottom: max(0, bottomBarHeight - bottomSafeAreaInset), right: 0
        )
        webView.setValue(
            UIEdgeInsets(top: 0, left: 0, bottom: max(0, bottomSafeAreaInset - bottomBarHeight), right: 0),
            forKey: "unobscuredSafeAreaInsets"
        )
        webView.setValue(
            UIEdgeInsets(top: 0, left: 0, bottom: bottomBarHeight, right: 0),
            forKey: "obscuredInsets"
        )
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

struct WebViewContainerView: UIViewControllerRepresentable {
    typealias UIViewControllerType = WebViewController

    let webView: WKWebView
    let overlayModel: OverlayModel

    func makeUIViewController(context: Context) -> WebViewController {
        return WebViewController()
    }

    func updateUIViewController(_ webViewController: WebViewController, context: Context) {
        webViewController.updateWebView(webView: webView, overlayModel: overlayModel)
    }
}

struct WebContentsView: View {
    @ObservedObject var card: WebContentsCardModel
    @EnvironmentObject var overlayModel: OverlayModel

    var body: some View {
        WebViewContainerView(webView: card.webView, overlayModel: overlayModel)
    }
}
