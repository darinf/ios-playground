import Combine
import UIKit
import WebKit

final class WebContentView: UIView {
    enum Action {}

    private struct DragBackState {
        let revealedWebView: WKWebView?
        let overlay: UIView
    }

    private let model: WebContentViewModel
    private let handler: (Action) -> Void
    private var subscriptions: Set<AnyCancellable> = []
    private var webContentSubscriptions: Set<AnyCancellable> = []
    private var overrideSafeAreaInsets: UIEdgeInsets?
    private var lastTranslation: CGPoint = .zero
    private var dragBackState: DragBackState?

    private var webView: WKWebView?

    private lazy var panGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(onPan))
        gesture.delegate = self
        gesture.maximumNumberOfTouches = 1
        gesture.allowedScrollTypesMask = .all
        return gesture
    }()

    private lazy var edgeSwipeGestureRecognizer = {
        let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(onLeftEdgeSwipe))
        gesture.edges = [.left]
        return gesture
    }()

    init(model: WebContentViewModel, handler: @escaping (Action) -> Void) {
        self.model = model
        self.handler = handler

        super.init(frame: .zero)

        setupObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setWebView(_ webView: WKWebView?) {
        if let existingWebView = self.webView {
            existingWebView.uiDelegate = nil
            existingWebView.scrollView.removeGestureRecognizer(panGestureRecognizer)
            existingWebView.scrollView.refreshControl = nil
            existingWebView.removeFromSuperview()
            webContentSubscriptions.removeAll()
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
        webView.activateContainmentConstraints(inside: self)

        setupWebContentModelObservers()
    }

    private func setupWebContentModelObservers() {
        model.webContent?.$canGoBackToOpener.sink { [weak self] canGoBackToOpener in
            guard let self else { return }
            if canGoBackToOpener {
                addGestureRecognizer(edgeSwipeGestureRecognizer)
            } else {
                removeGestureRecognizer(edgeSwipeGestureRecognizer)
            }
        }.store(in: &webContentSubscriptions)
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

    func updateThumbnail() {
        guard let webContent = model.webContent else { return }
        webContent.thumbnail = captureAsImage().map { .init(id: webContent.id, image: $0) }
    }

    private func setupObservers() {
        model.webContentChanges.sink { [weak self] _ in
            guard let self else { return }
            if let webContent = model.webContent {
                setWebView(webContent.webView)
            } else {
                setWebView(nil)
            }
        }.store(in: &subscriptions)
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

    @objc private func onLeftEdgeSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let offset = translation.x

        if gesture.state == .ended {
            if offset > 100 {
                let exitingWebView = webView

                if let dragBackState {
                    dragBackState.revealedWebView?.removeFromSuperview()
                    dragBackState.overlay.removeFromSuperview()
                    self.dragBackState = nil
                }

                model.goBack()
                webView?.layer.setAffineTransform(.init(translationX: 0, y: 0))
                
                if let exitingWebView {
                    addSubview(exitingWebView)
                    bringSubviewToFront(exitingWebView)
                    exitingWebView.activateContainmentConstraints(inside: self)
                    exitingWebView.layer.setAffineTransform(.init(translationX: offset, y: 0))

                    UIView.animate(withDuration: 0.2) { [self] in
                        if let screen = window?.screen {
                            exitingWebView.layer.setAffineTransform(.init(translationX: screen.bounds.width, y: 0))
                        }
                    } completion: { _ in
                        exitingWebView.removeFromSuperview()
                    }
                }
            } else {
                UIView.animate(withDuration: 0.2) { [self] in
                    webView?.layer.setAffineTransform(.init(translationX: 0, y: 0))
                } completion: { [self] _ in
                    if let dragBackState {
                        dragBackState.revealedWebView?.removeFromSuperview()
                        dragBackState.overlay.removeFromSuperview()
                        self.dragBackState = nil
                    }
                }
            }
        } else {
            if dragBackState == nil {
                let overlay = UIView()
                overlay.backgroundColor = .systemFill
                addSubview(overlay)
                sendSubviewToBack(overlay)
                overlay.activateContainmentConstraints(inside: self)

                let revealedWebView = model.previousWebView
                if let revealedWebView {
                    addSubview(revealedWebView)
                    sendSubviewToBack(revealedWebView)
                    revealedWebView.activateContainmentConstraints(inside: self)
                }
                dragBackState = .init(revealedWebView: revealedWebView, overlay: overlay)
            }
            webView?.layer.setAffineTransform(.init(translationX: offset, y: 0))
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

        let newWebContent = WebContent(
            webView: WebContent.createWebView(configuration: configuration),
            opener: model.webContent
        )

        DispatchQueue.main.async { [self] in
            updateThumbnail()
            model.openWebContent(with: newWebContent)
        }

        return newWebContent.webView
    }

    func webViewDidClose(_ webView: WKWebView) {
        model.popBack()
    }
}
