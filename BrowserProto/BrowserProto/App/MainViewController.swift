import Combine
import UIKit

class MainViewController: UIViewController {
    private var subscriptions: Set<AnyCancellable> = []

    private lazy var backgroundView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        return view
    }()

    private lazy var webContentView = {
        WebContentView()
    }()

    private lazy var bottomBarView = {
        BottomBarView()
    }()

    private lazy var bottomBarViewHeightConstraint: NSLayoutConstraint = {
        bottomBarView.heightAnchor.constraint(equalToConstant: 0)
    }()

    override func loadView() {
        view = backgroundView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(bottomBarView)
        view.addSubview(webContentView)

        setupInitialConstraints()
        setupObservers()

        view.bringSubviewToFront(bottomBarView)

        webContentView.model.url = URL(string: "https://news.ycombinator.com/")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.setNeedsUpdateConstraints()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        view.setNeedsUpdateConstraints()
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
        updateBottomBarHeight(expanded: bottomBarView.model.expanded, animated: false)
    }

    private func setupInitialConstraints() {
        bottomBarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomBarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBarView.widthAnchor.constraint(equalTo: view.widthAnchor),
            bottomBarViewHeightConstraint
        ])

        webContentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webContentView.topAnchor.constraint(equalTo: view.topAnchor),
            webContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webContentView.widthAnchor.constraint(equalTo: view.widthAnchor),
            webContentView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
    }

    private func setupObservers() {
        bottomBarView.model.$expanded.dropFirst().sink { [weak self] expanded in
            self?.updateBottomBarHeight(expanded: expanded, animated: true)
        }.store(in: &subscriptions)

        webContentView.model.$url.dropFirst().sink { [weak self] url in
            self?.bottomBarView.urlBarView.model.displayText = url?.host() ?? ""
        }.store(in: &subscriptions)
    }

    private func updateBottomBarHeight(expanded: Bool, animated: Bool) {
        let contentBoxHeight: CGFloat = expanded ? BottomBarView.Metrics.contentBoxExpandedHeight : BottomBarView.Metrics.contentBoxCompactHeight

        let newHeight = view.safeAreaInsets.bottom + contentBoxHeight + BottomBarView.Metrics.margin

        let applyNewHeight = { [self] in
            bottomBarViewHeightConstraint.constant = newHeight
            webContentView.webView.scrollView.contentInsetAdjustmentBehavior = .never
            webContentView.webView.scrollView.contentInset = .init(
                top: view.safeAreaInsets.top,
                left: view.safeAreaInsets.left,
                bottom: newHeight,
                right: view.safeAreaInsets.right
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
}
