import Combine
import UIKit

class MainViewController: UIViewController {
    let model = MainViewModel()

    private var subscriptions: Set<AnyCancellable> = []
    private var webContentSubscriptions: Set<AnyCancellable> = []
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
            case let .navigate(text, target):
                if case .newTab = target {
                    model.webContentViewModel.openWebContent()
                }
                model.webContentViewModel.navigate(to: URLInput.url(from: text))
                if model.cardGridViewModel.showGrid {
                    model.cardGridViewModel.showGrid = false
                }
            }
        }
    }()

    private lazy var cardGridView = {
        CardGridView(model: model.cardGridViewModel, zoomedView: webContentView) { [weak self] action in
            guard let self else { return }
            switch action {
            case let .removeCard(byID: cardID):
                model.cardGridViewModel.removeCard(byID: cardID)
            }
        }
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
                model.urlInputViewModel.visibility = .showing(
                    initialValue: model.webContentViewModel.url?.absoluteString ?? "",
                    forTarget: .currentTab
                )
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
            case .addTab:
                model.urlInputViewModel.visibility = .showing(initialValue: "", forTarget: .newTab)
            case .mainMenu(let mainMenuAction):
                print(">>> mainMenu: \(mainMenuAction)")
                switch mainMenuAction {
                case .toggleIncognito(let incognitoEnabled):
                    // TODO: Figure out how to provide memory for existing cards.
                    model.cardGridViewModel.removeAllCards()
                    model.webContentViewModel.incognito = incognitoEnabled
                    model.urlInputViewModel.visibility = .showing(initialValue: "", forTarget: .newTab)
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

        model.webContentViewModel.openWebContent()
        model.webContentViewModel.navigate(to: URL(string: "https://news.ycombinator.com/"))
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        view.setNeedsUpdateConstraints()
    }

    override func updateViewConstraints() {
        updateLayout(animated: false)
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
        model.webContentViewModel.$panningDeltaY.dropFirst().sink { [weak self] panningDeltaY in
            self?.updateBottomBarOffset(panningDeltaY: panningDeltaY)
        }.store(in: &subscriptions)

        model.tabsModel.tabsChanges.sink { [weak self] change in
            guard let self else { return }
            switch change {
            case let .appended(tab, inSection: section):
                guard model.currentTabsSection == section else { return }
                model.cardGridViewModel.appendCard(.init(from: tab))
            case let .inserted(tab, atIndex: index, inSection: section):
                guard model.currentTabsSection == section else { return }
                model.cardGridViewModel.insertCard(.init(from: tab), atIndex: index)
            case let .removed(atIndex: index, inSection: section):
                guard model.currentTabsSection == section else { return }
                model.cardGridViewModel.removeCard(atIndex: index)
            case let .removedAll(inSection: section):
                guard model.currentTabsSection == section else { return }
                model.cardGridViewModel.removeAllCards()
            case let .updated(field, atIndex: index, inSection: section):
                guard model.currentTabsSection == section else { return }
                switch field {
                case .url:
                    break
                case let .title(title):
                    model.cardGridViewModel.updateTitle(title, forCardAtIndex: index)
                case .faviconURL:
                    break
                }
            }
        }.store(in: &subscriptions)

        model.webContentViewModel.webContentChanges.sink { [weak self] change in
            guard let self else { return }
            let currentWebContent = model.webContentViewModel.webContent
            switch change {
            case .opened:
                let newCard = Card(id: currentWebContent!.id)
                if let opener = currentWebContent?.opener {
                    model.cardGridViewModel.insertCard(newCard, after: opener.id)
                } else {
                    model.cardGridViewModel.appendCard(newCard)
                }
            case .switched:
                break
            case let .poppedBack(from: closedWebContent):
                model.cardGridViewModel.removeCard(byID: closedWebContent.id)
                // TODO: If currentWebContent is nil, then we need to select a different card.
            }
            model.cardGridViewModel.selectedID = currentWebContent?.id
            setupWebContentObservers(for: currentWebContent)
        }.store(in: &subscriptions)

        model.cardGridViewModel.$selectedID.removeDuplicates().sink { [weak self] selectedID in
            guard let self else { return }
            model.webContentViewModel.replaceWebContent(with: .from(id: selectedID))
            if selectedID == nil {
                model.cardGridViewModel.showGrid = true
            }
        }.store(in: &subscriptions)

        model.cardGridViewModel.$showGrid.dropFirst().removeDuplicates().sink { [weak self] showGrid in
            self?.model.bottomBarViewModel.centerButtonViewModel.mode = showGrid ? .showAsPlus : .showAsText
        }.store(in: &subscriptions)

        model.cardGridViewModel.cardsChanges.sink { [weak self] _ in
            guard let self else { return }
            model.bottomBarViewModel.tabsButtonEnabled = !model.cardGridViewModel.cards.isEmpty
        }.store(in: &subscriptions)
    }

    private func setupWebContentObservers(for webContent: WebContent?) {
        guard let webContent else {
            webContentSubscriptions.removeAll()
            return
        }

        webContent.$url.dropFirst().sink { [weak self] url in
            self?.model.bottomBarViewModel.centerButtonViewModel.text = url?.host() ?? ""
            self?.resetBottomBarOffset()
        }.store(in: &webContentSubscriptions)

        webContent.$title.dropFirst().sink { [weak self] title in
            self?.model.cardGridViewModel.updateTitle(title, forCardByID: webContent.id)
        }.store(in: &webContentSubscriptions)

        webContent.$favicon.dropFirst().sink { [weak self] favicon in
            self?.model.cardGridViewModel.updateFavicon(favicon, forCardByID: webContent.id)
        }.store(in: &webContentSubscriptions)

        webContent.$progress.dropFirst().sink { [weak self] progress in
            self?.model.bottomBarViewModel.centerButtonViewModel.progress = progress
        }.store(in: &webContentSubscriptions)

        webContent.$thumbnail.sink { [weak self] thumbnail in
            self?.model.cardGridViewModel.updateThumbnail(thumbnail, forCardByID: webContent.id)
        }.store(in: &webContentSubscriptions)
    }

    private func updateLayout(animated: Bool) {
        let safeAreaInsets = view.safeAreaInsets

        let contentBoxHeight: CGFloat = BottomBarView.Metrics.contentBoxHeight

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
        return BottomBarView.Metrics.contentBoxHeight + BottomBarView.Metrics.margin
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

extension Card {
    init(from tab: TabData) {
        self.init(id: tab.id, title: tab.title, favicon: nil, thumbnail: nil)
    }
}
