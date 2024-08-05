import Foundation
import Combine
import UIKit
import WebKit

final class WebContentViewModel {
    enum WebViewRefChange {
        case opened
        case switched
        case poppedBack(from: WebViewRef)
    }

    private(set) var webViewRef: WebViewRef?
    let webViewRefChanges = PassthroughSubject<WebViewRefChange, Never>()

    @Published var panningDeltaY: CGFloat?
    @Published var incognito: Bool = false

    var webView: WKWebView? {
        webViewRef?.webView
    }

    var previousWebView: WKWebView? {
        webViewRef?.openerRef?.webView
    }

    var webContentModel: WebContentModel? {
        webViewRef?.model
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

    func openWebView() {
        openWebView(withRef: WebViewRef(forIncognito: incognito))
    }

    func openWebView(withRef newWebViewRef: WebViewRef) {
        webViewRef = newWebViewRef
        webViewRefChanges.send(.opened)
    }

    func popBack() {
        guard let fromRef = webViewRef else { return }
        webViewRef = fromRef.openerRef // Can be nil, corresponding to window.close().
        webViewRefChanges.send(.poppedBack(from: fromRef))
    }

    func replaceWebView(withRef newWebViewRef: WebViewRef?) {
        webViewRef = newWebViewRef
        webViewRefChanges.send(.switched)
    }
}

extension WebContentViewModel {
    var url: URL? {
        webContentModel?.url
    }
}
