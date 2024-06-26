import Combine
import UIKit
import WebKit

final class WebContentView: UIView {
    let model = WebContentViewModel()

    private var subscriptions: Set<AnyCancellable> = []
    private var overrideSafeAreaInsets: UIEdgeInsets?

    private static var configuration = {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        return configuration
    }()

    lazy var webView = {
        let webView = WKWebView(frame: .zero, configuration: Self.configuration)
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }()

    init() {
        super.init(frame: .zero)

        addSubview(webView)

        setupConstraints()
        setupObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            webView.widthAnchor.constraint(equalTo: widthAnchor),
            webView.heightAnchor.constraint(equalTo: heightAnchor)
        ])
    }

    private func setupObservers() {
        model.$url.dropFirst().sink { [weak self] url in
            self?.navigate(to: url)
        }.store(in: &subscriptions)

        model.$overrideSafeAreaInsets.dropFirst().sink { [weak self] insets in
            self?.overrideSafeAreaInsets = insets
            self?.setNeedsLayout()
        }.store(in: &subscriptions)

        webView.publisher(for: \.url).dropFirst().sink { [weak self] url in
            self?.model.url = url
        }.store(in: &subscriptions)
    }

    private func navigate(to url: URL?) {
        if let url, url != webView.url {
            print(">>> navigating to: \(url)")
            webView.load(.init(url: url))
        }
    }

    override var safeAreaInsets: UIEdgeInsets {
        overrideSafeAreaInsets ?? super.safeAreaInsets
    }
}
