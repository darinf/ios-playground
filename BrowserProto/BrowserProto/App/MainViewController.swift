import Combine
import UIKit

class MainViewController: UIViewController {
    let model = MainViewModel()

    private var subscriptions: Set<AnyCancellable> = []
    private var bottomBarOffset: CGFloat = .zero

    private lazy var backgroundView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()

    private lazy var urlInputView = {
        URLInputView()
    }()

    private lazy var webContentView = {
        WebContentView()
    }()

    private lazy var topBarView = {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    }()

    private lazy var bottomBarView = {
        BottomBarView() { [weak self] action in
            guard let self else { return }
            switch action {
            case .editURL:
                urlInputView.model.show()
            case .goBack:
                webContentView.goBack()
            case .goForward:
                webContentView.goForward()
            default:
                print(">>> unhandled action: \(action)")
            }
        }
    }()

    private lazy var topBarViewHeightConstraint: NSLayoutConstraint = {
        topBarView.bottomAnchor.constraint(equalTo: view.topAnchor, constant: 0)
    }()

    private lazy var bottomBarViewHeightConstraint: NSLayoutConstraint = {
        bottomBarView.heightAnchor.constraint(equalToConstant: 0)
    }()

    override func loadView() {
        view = backgroundView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(topBarView)
        view.addSubview(bottomBarView)
        view.addSubview(webContentView)
        view.addSubview(urlInputView)

        setupInitialConstraints()
        setupObservers()

        view.bringSubviewToFront(topBarView)
        view.bringSubviewToFront(bottomBarView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.setNeedsUpdateConstraints()

        webContentView.model.url = URL(string: "https://news.ycombinator.com/")
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        view.setNeedsUpdateConstraints()
    }

    override func updateViewConstraints() {
        updateLayout(expanded: bottomBarView.model.expanded, animated: false)
        super.updateViewConstraints()
    }

    private func setupInitialConstraints() {
        topBarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topBarView.topAnchor.constraint(equalTo: view.topAnchor),
            topBarView.leftAnchor.constraint(equalTo: view.leftAnchor),
            topBarView.rightAnchor.constraint(equalTo: view.rightAnchor),
            topBarViewHeightConstraint
        ])

        bottomBarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomBarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBarView.widthAnchor.constraint(equalTo: view.widthAnchor),
            bottomBarViewHeightConstraint
        ])

        webContentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webContentView.topAnchor.constraint(equalTo: topBarView.bottomAnchor),
            webContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webContentView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])

        urlInputView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            urlInputView.topAnchor.constraint(equalTo: view.topAnchor),
            urlInputView.widthAnchor.constraint(equalTo: view.widthAnchor),
            urlInputView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupObservers() {
        bottomBarView.model.$expanded.dropFirst().sink { [weak self] expanded in
            self?.updateLayout(expanded: expanded, animated: true)
        }.store(in: &subscriptions)

        webContentView.model.$url.dropFirst().sink { [weak self] url in
            self?.bottomBarView.model.url = url
            self?.resetBottomBarOffset()
        }.store(in: &subscriptions)

        webContentView.model.$canGoBack.dropFirst().sink { [weak self] canGoBack in
            self?.bottomBarView.model.canGoBack = canGoBack
        }.store(in: &subscriptions)

        webContentView.model.$canGoForward.dropFirst().sink { [weak self] canGoForward in
            self?.bottomBarView.model.canGoForward = canGoForward
        }.store(in: &subscriptions)

        webContentView.model.$progress.dropFirst().sink { [weak self] progress in
            self?.bottomBarView.model.progress = progress
        }.store(in: &subscriptions)

        webContentView.model.$panningDeltaY.dropFirst().sink { [weak self] panningDeltaY in
            self?.updateBottomBarOffset(panningDeltaY: panningDeltaY)
        }.store(in: &subscriptions)

        urlInputView.model.$text.dropFirst().sink { [weak self] text in
            self?.webContentView.model.url = URLInput.url(from: text)
        }.store(in: &subscriptions)
    }

    private func updateLayout(expanded: Bool, animated: Bool) {
        let safeAreaInsets = view.safeAreaInsets

        let contentBoxHeight: CGFloat = expanded ? BottomBarView.Metrics.contentBoxExpandedHeight : BottomBarView.Metrics.contentBoxCompactHeight

        let newHeight = safeAreaInsets.bottom + contentBoxHeight + BottomBarView.Metrics.margin

        let applyNewHeight = { [self] in
            topBarViewHeightConstraint.constant = safeAreaInsets.top
            bottomBarViewHeightConstraint.constant = newHeight

            webContentView.updateLayout(
                insets: UIEdgeInsets(top: 0, left: 0, bottom: newHeight, right: 0)
            )
        }

        if animated {
            UIView.animate(withDuration: 0.2, delay: 0.0) {
                applyNewHeight()
                self.view.layoutIfNeeded()
            }
        } else {
            applyNewHeight()
        }
    }

    private var bottomBarMaxOffset: CGFloat {
        let expanded = bottomBarView.model.expanded
        return (expanded ? BottomBarView.Metrics.contentBoxExpandedHeight : BottomBarView.Metrics.contentBoxCompactHeight) + BottomBarView.Metrics.margin
    }

    private func updateBottomBarOffset(panningDeltaY: CGFloat?) {
        let maxOffset = bottomBarMaxOffset
        if let panningDeltaY {
            setBottomBarOffset(max(min(bottomBarOffset + panningDeltaY, maxOffset), 0))
        } else if bottomBarOffset < maxOffset {
            resetBottomBarOffset()
        }
    }

    private func setBottomBarOffset(_ newOffset: CGFloat) {
        bottomBarOffset = newOffset

        let maxOffset = bottomBarMaxOffset
        let transform = CGAffineTransform(translationX: 0, y: bottomBarOffset)
        bottomBarView.layer.setAffineTransform(transform)
        bottomBarView.contentView.layer.opacity = Float(abs(maxOffset - bottomBarOffset) / maxOffset)

        let newHeight = view.safeAreaInsets.bottom + maxOffset - bottomBarOffset
        webContentView.updateLayout(
            insets: UIEdgeInsets(top: 0, left: 0, bottom: newHeight, right: 0)
        )
    }

    private func resetBottomBarOffset() {
        UIView.animate(withDuration: 0.2) { [self] in
            setBottomBarOffset(0)
        }
    }
}
