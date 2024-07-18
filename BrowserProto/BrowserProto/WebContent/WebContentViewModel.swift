import Foundation
import Combine
import UIKit
import WebKit

final class WebContentViewModel {
    @Published private(set) var id: WebViewID?
    @Published var url: URL?
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published private(set) var progress: Double?
    @Published var panningDeltaY: CGFloat?
    @Published private(set) var backStack: [WebViewID] = []

    private var webView: WKWebView? {
        guard let id else { return nil }
        return WebViewStore.shared.lookup(byID: id)
    }

    func updateProgress(isLoading: Bool, estimatedProgress: Double) {
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

    func navigate(to url: URL?) {
        guard let url, let webView else { return }
        webView.load(.init(url: url))
    }

    func goBack() {
        if let webView, webView.canGoBack {
            webView.goBack()
        } else if !backStack.isEmpty {
            id = backStack.first
            backStack.removeFirst()
        }
    }

    func goForward() {
        webView?.goForward()
    }

    func pushWebView(withID newWebViewID: WebViewID) {
        if let id {
            backStack.insert(id, at: 0)
        }
        id = newWebViewID
    }
}
