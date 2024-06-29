import Combine
import UIKit
import WebKit

final class WebContentView: UIView {
    let model = WebContentViewModel()

    enum Action {
        case panning(offset: CGFloat)
        case panningEnd(offset: CGFloat)
    }

    private let handler: (Action) -> Void
    private var subscriptions: Set<AnyCancellable> = []
    private var overrideSafeAreaInsets: UIEdgeInsets?

    private static var configuration = {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        return configuration
    }()

    private lazy var webView = {
        let webView = WKWebView(frame: .zero, configuration: Self.configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.clipsToBounds = false
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        return webView
    }()

    private lazy var panGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(onPan))
        gesture.delegate = self
        gesture.maximumNumberOfTouches = 1
        gesture.allowedScrollTypesMask = .all
        return gesture
    }()

    init(handler: @escaping (Action) -> Void) {
        self.handler = handler
        super.init(frame: .zero)

        webView.scrollView.addGestureRecognizer(panGestureRecognizer)

        addSubview(webView)

        setupConstraints()
        setupObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateLayout(insets: UIEdgeInsets) {
        webView.setValue(
            UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
            forKey: "unobscuredSafeAreaInsets"
        )
        webView.setValue(
            insets,
            forKey: "obscuredInsets"
        )
        webView.setMinimumViewportInset(insets, maximumViewportInset: insets)

        overrideSafeAreaInsets = insets
        setNeedsLayout()
    }

    func goBack() {
        webView.goBack()
    }

    func goForward() {
        webView.goForward()
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

        webView.publisher(for: \.url).dropFirst().sink { [weak self] url in
            self?.model.url = url
        }.store(in: &subscriptions)

        webView.publisher(for: \.canGoBack).dropFirst().sink { [weak self] canGoBack in
            self?.model.canGoBack = canGoBack
        }.store(in: &subscriptions)

        webView.publisher(for: \.canGoForward).dropFirst().sink { [weak self] canGoForward in
            self?.model.canGoForward = canGoForward
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

    @objc private func onPan() {
        let translation = panGestureRecognizer.translation(in: self)
        guard abs(translation.y) > abs(translation.x) else { return }
        switch panGestureRecognizer.state {
        case .began:
            print(">>> began gesture")
        case .changed:
            handler(.panning(offset: translation.y))
        case .ended:
            handler(.panningEnd(offset: translation.y))
        case .possible:
            print(">>> gesture possible")
        case .cancelled:
            print(">>> gesture cancelled")
        case .failed:
            print(">>> gesture failed")
        @unknown default:
            print(">>> gesture unknown")
        }
    }
}

extension WebContentView: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}
