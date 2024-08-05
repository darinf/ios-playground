import Foundation
import Combine
import UIKit
import WebKit

final class WebContentViewModel {
    enum WebContentChange {
        case opened
        case switched
        case poppedBack(from: WebContent)
    }

    private(set) var webContent: WebContent?
    let webContentChanges = PassthroughSubject<WebContentChange, Never>()

    @Published var panningDeltaY: CGFloat?
    @Published var incognito: Bool = false

    var webView: WKWebView? {
        webContent?.webView
    }

    var previousWebView: WKWebView? {
        webContent?.opener?.webView
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

    func openWebContent() {
        openWebContent(with: WebContent(forIncognito: incognito))
    }

    func openWebContent(with newWebContent: WebContent) {
        webContent = newWebContent
        webContentChanges.send(.opened)
    }

    func popBack() {
        guard let fromWebContent = webContent else { return }
        webContent = fromWebContent.opener // Can be nil, corresponding to window.close().
        webContentChanges.send(.poppedBack(from: fromWebContent))
    }

    func replaceWebContent(with newWebContent: WebContent?) {
        webContent = newWebContent
        webContentChanges.send(.switched)
    }
}

extension WebContentViewModel {
    var url: URL? {
        webContent?.url
    }
}
