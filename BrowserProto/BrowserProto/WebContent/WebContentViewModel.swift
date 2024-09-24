import Foundation
import Combine
import UIKit
import WebKit

final class WebContentViewModel {
    enum Change {
        case opened(relativeToOpener: Bool)
        case switched
        case poppedBack(from: WebContent)
    }

    private(set) var webContent: WebContent?
    let webContentChanges = PassthroughSubject<Change, Never>()

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

    func openWebContent(withOpener opener: WebContent? = nil, relativeToOpener: Bool = false) {
        openWebContent(with: WebContent(forIncognito: incognito, withOpener: opener), relativeToOpener: relativeToOpener)
    }

    func openWebContent(with newWebContent: WebContent, relativeToOpener: Bool = false) {
        webContent = newWebContent
        webContentChanges.send(.opened(relativeToOpener: relativeToOpener))
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
