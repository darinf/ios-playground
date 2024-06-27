import Combine
import UIKit

class MainViewController: UIViewController {
    private var subscriptions: Set<AnyCancellable> = []

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
                view.bringSubviewToFront(urlInputView)
                urlInputView.model.showing = true
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

        urlInputView.isHidden = true

        webContentView.webView.scrollView.clipsToBounds = false

        setupInitialConstraints()
        setupObservers()

        view.bringSubviewToFront(topBarView)
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
            self?.bottomBarView.urlBarView.model.displayText = url?.host() ?? ""
        }.store(in: &subscriptions)

//        bottomBarView.urlBarView.model.$editing.dropFirst().sink { [weak self] editing in
//            guard let self else { return }
//            if editing {
//                urlInputView.isHidden = false
//                view.bringSubviewToFront(urlInputView)
//                urlInputView.textField.becomeFirstResponder()
//            } else {
//                urlInputView.textField.resignFirstResponder()
//                urlInputView.isHidden = true
//            }
//        }.store(in: &subscriptions)
    }

    private func updateLayout(expanded: Bool, animated: Bool) {
        let safeAreaInsets = view.safeAreaInsets

        let contentBoxHeight: CGFloat = expanded ? BottomBarView.Metrics.contentBoxExpandedHeight : BottomBarView.Metrics.contentBoxCompactHeight

        let newHeight = safeAreaInsets.bottom + contentBoxHeight + BottomBarView.Metrics.margin

        let applyNewHeight = { [self] in
            topBarViewHeightConstraint.constant = safeAreaInsets.top
            bottomBarViewHeightConstraint.constant = newHeight
            webContentView.webView.scrollView.contentInsetAdjustmentBehavior = .always

            let insets = UIEdgeInsets(top: 0, left: 0, bottom: newHeight, right: 0)
            webContentView.webView.setValue(
                UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
                forKey: "unobscuredSafeAreaInsets"
            )
            webContentView.webView.setValue(
                insets,
                forKey: "obscuredInsets"
            )
            webContentView.webView.setMinimumViewportInset(insets, maximumViewportInset: insets)

            webContentView.model.overrideSafeAreaInsets = insets
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
