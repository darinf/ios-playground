import Foundation
import Combine
import UIKit
import WebKit

final class WebContentViewModel {
    @Published private(set) var webViewRef: WebViewRef?
    @Published var url: URL?
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published private(set) var progress: Double?
    @Published var panningDeltaY: CGFloat?
    @Published private(set) var backStack: [WebViewRef] = [] // New items at the back
    @Published var incognito: Bool = false
    @Published var thumbnail: UIImage?

    var webView: WKWebView? {
        webViewRef?.webView
    }

    var previousWebView: WKWebView? {
        backStack.last?.webView
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
        } else {
            popBack()
        }
    }

    func goForward() {
        webView?.goForward()
    }

    func popBack() {
        guard !backStack.isEmpty else { return }
        webViewRef = backStack.popLast()
    }

    func pushWebView(withRef newWebViewRef: WebViewRef) {
        if let webViewRef {
            backStack.append(webViewRef)
        }
        webViewRef = newWebViewRef
    }

    func replaceWebView(withRef newWebViewRef: WebViewRef?) {
        print(">>> replaceWebView")
        backStack = []
        webViewRef = newWebViewRef
    }
}
