import Combine
import UIKit
import WebKit

final class WebContentView: UIView {
    let model = WebContentViewModel()

    private var subscriptions: Set<AnyCancellable> = []
    private var overrideSafeAreaInsets: UIEdgeInsets?
    private var lastTranslation: CGPoint = .zero
    private var suppressNavigation: Bool = false

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

    init() {
        super.init(frame: .zero)

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

        // TODO: Might need to tweak this further.
        webView.scrollView.verticalScrollIndicatorInsets = .init(
            top: insets.top,
            left: 0,
            bottom: insets.bottom - super.safeAreaInsets.bottom,
            right: 0
        )

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
            guard let self, !suppressNavigation else { return }
            navigate(to: url)
        }.store(in: &subscriptions)

        webView.publisher(for: \.url).dropFirst().sink { [weak self] url in
            guard let self else { return }
            suppressNavigation = true
            defer { suppressNavigation = false }
            model.url = url
        }.store(in: &subscriptions)

        webView.publisher(for: \.canGoBack).dropFirst().sink { [weak self] canGoBack in
            self?.model.canGoBack = canGoBack
        }.store(in: &subscriptions)

        webView.publisher(for: \.canGoForward).dropFirst().sink { [weak self] canGoForward in
            self?.model.canGoForward = canGoForward
        }.store(in: &subscriptions)

        webView.publisher(for: \.isLoading).combineLatest(webView.publisher(for: \.estimatedProgress)).dropFirst().sink { [weak self] in
            self?.updateProgress(isLoading: $0.0, estimatedProgress: $0.1)
        }.store(in: &subscriptions)
    }

    private func navigate(to url: URL?) {
        if let url {
            print(">>> navigating to: \(url)")
            webView.load(.init(url: url))
        }
    }

    private func updateProgress(isLoading: Bool, estimatedProgress: Double) {
        let progress: Double?
        if isLoading {
            progress = estimatedProgress
        } else {
            progress = nil
        }
        if model.progress != progress {
            model.progress = progress
        }
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
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        webView.reload()
        if let refreshControl = webView.scrollView.refreshControl {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                refreshControl.endRefreshing()
            }
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
