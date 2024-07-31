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
        URLInputView(model: model.urlInputViewModel) { [weak self] action in
            guard let self else { return }
            switch action {
            case .navigate(let text):
                model.webContentViewModel.navigate(to: URLInput.url(from: text))
            }
        }
    }()

    private lazy var cardGridView = {
        CardGridView(model: model.cardGridViewModel, zoomedView: webContentView)
    }()

    private lazy var webContentView = {
        WebContentView(model: model.webContentViewModel) { _ in }
    }()

    private lazy var topBarView = {
        UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    }()

    private lazy var bottomBarView = {
        BottomBarView(model: model.bottomBarViewModel) { [weak self] action in
            guard let self else { return }
            switch action {
            case .editURL:
                model.urlInputViewModel.visibility = .showing(initialValue: model.webContentViewModel.url?.absoluteString ?? "")
            case .goBack:
                model.webContentViewModel.goBack()
            case .goForward:
                model.webContentViewModel.goForward()
            case .showTabs:
                // Refresh thumbnail before showing grid.
                if !model.cardGridViewModel.showGrid {
                    webContentView.updateThumbnail()
                }
                model.cardGridViewModel.showGrid.toggle()
            case .mainMenu(let mainMenuAction):
                print(">>> mainMenu: \(mainMenuAction)")
                switch mainMenuAction {
                case .toggleIncognito(let incognitoEnabled):
                    model.webContentViewModel.incognito = incognitoEnabled
                    model.urlInputViewModel.visibility = .showing(initialValue: "")
                }
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
        view.addSubview(cardGridView)
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

        model.webContentViewModel.openWebView()
        model.webContentViewModel.navigate(to: URL(string: "https://news.ycombinator.com/"))
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        view.setNeedsUpdateConstraints()
    }

    override func updateViewConstraints() {
        updateLayout(expanded: model.bottomBarViewModel.expanded, animated: false)
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

        cardGridView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardGridView.topAnchor.constraint(equalTo: topBarView.bottomAnchor),
            cardGridView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cardGridView.widthAnchor.constraint(equalTo: view.widthAnchor)
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
        model.bottomBarViewModel.$expanded.dropFirst().sink { [weak self] expanded in
            self?.updateLayout(expanded: expanded, animated: true)
        }.store(in: &subscriptions)

        model.webContentViewModel.$url.dropFirst().sink { [weak self] url in
            self?.model.bottomBarViewModel.url = url
            self?.resetBottomBarOffset()
        }.store(in: &subscriptions)

        model.webContentViewModel.$canGoBack.dropFirst().sink { [weak self] canGoBack in
            self?.model.bottomBarViewModel.canGoBack = canGoBack
        }.store(in: &subscriptions)

        model.webContentViewModel.$canGoForward.dropFirst().sink { [weak self] canGoForward in
            self?.model.bottomBarViewModel.canGoForward = canGoForward
        }.store(in: &subscriptions)

        model.webContentViewModel.$progress.dropFirst().sink { [weak self] progress in
            self?.model.bottomBarViewModel.progress = progress
        }.store(in: &subscriptions)

        model.webContentViewModel.$panningDeltaY.dropFirst().sink { [weak self] panningDeltaY in
            self?.updateBottomBarOffset(panningDeltaY: panningDeltaY)
        }.store(in: &subscriptions)

        model.webContentViewModel.$thumbnail.sink { [weak self] thumbnail in
            guard let self else { return }
            guard let selectedID = model.cardGridViewModel.selectedID else { return }
            model.cardGridViewModel.updateThumbnail(thumbnail, forCardByID: selectedID)
        }.store(in: &subscriptions)

        model.webContentViewModel.webViewRefChanges.sink { [weak self] change in
            guard let self else { return }
            let currentRef = model.webContentViewModel.webViewRef
            switch change {
            case .opened:
                let newCard = Card(id: currentRef!.id)
                if let openerRef = currentRef?.openerRef {
                    model.cardGridViewModel.insertCard(newCard, after: openerRef.id)
                } else {
                    model.cardGridViewModel.appendCard(newCard)
                }
            case .switched:
                break
            case let .poppedBack(from: closedRef):
                model.cardGridViewModel.removeCard(byID: closedRef.id)
                // TODO: If currentRef is nil, then we need to select a different card.
            }
            model.cardGridViewModel.selectedID = currentRef?.id
        }.store(in: &subscriptions)

        model.cardGridViewModel.$selectedID.removeDuplicates().sink { [weak self] selectedID in
            guard let self else { return }
            model.webContentViewModel.replaceWebView(withRef: .from(id: selectedID))
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
        let expanded = model.bottomBarViewModel.expanded
        return (expanded ? BottomBarView.Metrics.contentBoxExpandedHeight : BottomBarView.Metrics.contentBoxCompactHeight) + BottomBarView.Metrics.margin
    }

    private func updateBottomBarOffset(panningDeltaY: CGFloat?) {
        let maxOffset = bottomBarMaxOffset
        if let panningDeltaY {
            animateBottomBarOffset(to: max(min(bottomBarOffset + panningDeltaY, maxOffset), 0))
        } else if bottomBarOffset < maxOffset {
            if bottomBarOffset / maxOffset > 0.5 {
                animateBottomBarOffset(to: maxOffset)
            } else {
                resetBottomBarOffset()
            }
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

    private func animateBottomBarOffset(to offset: CGFloat) {
        UIView.animate(withDuration: 0.2) { [self] in
            setBottomBarOffset(offset)
        }
    }

    private func resetBottomBarOffset() {
        animateBottomBarOffset(to: 0)
    }
}
