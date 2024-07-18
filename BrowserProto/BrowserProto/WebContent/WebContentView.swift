import Combine
import UIKit
import WebKit

final class WebContentView: UIView {
    enum Action {}

    private let model: WebContentViewModel
    private let handler: (Action) -> Void
    private var subscriptions: Set<AnyCancellable> = []
    private var webViewSubscriptions: Set<AnyCancellable> = []
    private var overrideSafeAreaInsets: UIEdgeInsets?
    private var lastTranslation: CGPoint = .zero

    private static var configuration = {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        return configuration
    }()

    private var webView: WKWebView?
    private var webViewConstraints: [NSLayoutConstraint] = []

    private lazy var panGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(onPan))
        gesture.delegate = self
        gesture.maximumNumberOfTouches = 1
        gesture.allowedScrollTypesMask = .all
        return gesture
    }()

    init(model: WebContentViewModel, handler: @escaping (Action) -> Void) {
        self.model = model
        self.handler = handler

        super.init(frame: .zero)

        let webViewID = WebViewID()
        _ = Self.createWebView(id: webViewID, configuration: Self.configuration)
        model.pushWebView(withID: webViewID)

        setupObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setWebView(_ webView: WKWebView?) {
        if let existingWebView = self.webView {
            NSLayoutConstraint.deactivate(webViewConstraints)
            webViewConstraints = []
            existingWebView.uiDelegate = nil
            existingWebView.scrollView.removeGestureRecognizer(panGestureRecognizer)
            existingWebView.scrollView.refreshControl = nil
            existingWebView.removeFromSuperview()
            webViewSubscriptions.removeAll()
        }

        self.webView = webView

        guard let webView else { return }

        webView.uiDelegate = self
        webView.scrollView.addGestureRecognizer(panGestureRecognizer)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        refreshControl.tintColor = .init(dynamicProvider: { [webView] _ in
            if webView.scrollView.backgroundColor?.isDarkColor ?? false {
                return .systemGray.resolvedColor(with: UITraitCollection.init(userInterfaceStyle: .dark))
            } else {
                return .systemGray.resolvedColor(with: UITraitCollection.init(userInterfaceStyle: .light))
            }
        })
        webView.scrollView.refreshControl = refreshControl

        addSubview(webView)

        setupWebViewObservers()
        setupWebViewConstraints()
    }

    func updateLayout(insets: UIEdgeInsets) {
        overrideSafeAreaInsets = insets
        setNeedsLayout()

        guard let webView else { return }

        webView.setValue(
            UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
            forKey: "unobscuredSafeAreaInsets"
        )
        webView.setValue(
            insets,
            forKey: "obscuredInsets"
        )
        webView.setMinimumViewportInset(insets, maximumViewportInset: insets)

        // TODO: Might need to tweak this further.
        webView.scrollView.verticalScrollIndicatorInsets = .init(
            top: insets.top,
            left: 0,
            bottom: insets.bottom - super.safeAreaInsets.bottom,
            right: 0
        )
    }

    private func setupWebViewConstraints() {
        guard let webView else { return }
        webView.translatesAutoresizingMaskIntoConstraints = false
        webViewConstraints = [
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            webView.widthAnchor.constraint(equalTo: widthAnchor),
            webView.heightAnchor.constraint(equalTo: heightAnchor)
        ]
        NSLayoutConstraint.activate(webViewConstraints)
    }

    private func setupObservers() {
        model.$id.sink { [weak self] id in
            guard let self else { return }
            if let id {
                setWebView(WebViewStore.shared.lookup(byID: id))
            } else {
                setWebView(nil)
            }
        }.store(in: &subscriptions)
    }

    private func setupWebViewObservers() {
        guard let webView else { return }

        webView.publisher(for: \.url, options: [.initial]).sink { [weak self] url in
            self?.model.url = url
        }.store(in: &webViewSubscriptions)

        Publishers.CombineLatest(
            model.$backStack,
            webView.publisher(for: \.canGoBack, options: [.initial])
        ).sink { [weak self] (backStack, canGoBack) in
            if canGoBack {
                self?.model.canGoBack = true
            } else {
                self?.model.canGoBack = !backStack.isEmpty
            }
        }.store(in: &webViewSubscriptions)

        webView.publisher(for: \.canGoForward, options: [.initial]).sink { [weak self] canGoForward in
            self?.model.canGoForward = canGoForward
        }.store(in: &webViewSubscriptions)

        Publishers.CombineLatest(
            webView.publisher(for: \.isLoading, options: [.initial]),
            webView.publisher(for: \.estimatedProgress, options: [.initial])
        ).sink { [weak self] in
            self?.model.updateProgress(isLoading: $0.0, estimatedProgress: $0.1)
        }.store(in: &webViewSubscriptions)
    }

    override var safeAreaInsets: UIEdgeInsets {
        overrideSafeAreaInsets ?? super.safeAreaInsets
    }

    @objc private func onPan(_ gesture: UIPanGestureRecognizer) {
        let panning = (gesture.state == .changed)

        let translation = gesture.translation(in: self)
        let dy = lastTranslation.y - translation.y

        let deltaY: CGFloat
        if abs(translation.x) > abs(translation.y) {
            deltaY = 0
        } else {
            deltaY = dy
        }

        if gesture.state == .ended || gesture.state == .cancelled {
            lastTranslation = .zero
        } else {
            lastTranslation = translation
        }

        if panning {
            model.panningDeltaY = deltaY
        } else {
            model.panningDeltaY = nil
        }
    }

    @objc private func onRefresh() {
        guard let webView else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        webView.reload()
        if let refreshControl = webView.scrollView.refreshControl {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                refreshControl.endRefreshing()
            }
        }
    }

    private static func createWebView(id: WebViewID, configuration: WKWebViewConfiguration) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.clipsToBounds = false
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        WebViewStore.shared.insert(webView, withID: id)
        return webView
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

extension WebContentView: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        print(">>> createWebView")
        
        let newWebViewID = WebViewID()
        let newWebView = Self.createWebView(id: newWebViewID, configuration: configuration)

        DispatchQueue.main.async { [self] in
            model.pushWebView(withID: newWebViewID)
        }

        return newWebView
    }
}
