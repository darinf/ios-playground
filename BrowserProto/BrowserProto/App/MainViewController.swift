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
            self?.model.handle(action)
        }
    }()

    private lazy var cardGridView = {
        CardGridView(model: model.cardGridViewModel, zoomedView: webContentView) { [weak self] action in
            self?.model.handle(action)
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
            self?.model.handle(action)
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

        model.loadData()
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
            cardGridView.topAnchor.constraint(equalTo: view.topAnchor),
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

        model.tabsModel.changes.sink { [weak self] (section, change) in
            guard let self else { return }
            model.tabsStorage.persistTabsChange(change, in: section, for: model.tabsModel.data)
            model.updateCardGrid(for: change, in: section)
            model.validateOpener()
        }.store(in: &subscriptions)

        model.webContentViewModel.webContentChanges.sink { [weak self] change in
            guard let self else { return }
            model.updateTabs(for: change)
            setupWebContentObservers(for: model.webContentViewModel.webContent)
        }.store(in: &subscriptions)

        model.cardGridViewModel.$selectedID.dropFirst().removeDuplicates().sink { [weak self] selectedID in
            guard let self else { return }
            model.webContentViewModel.replaceWebContent(with: selectedID.flatMap { [model] in
                model.tabsModel.webContent(for: $0, inSection: model.currentTabsSection)
            })
            model.bottomBarViewModel.tabsButtonEnabled = selectedID != nil
        }.store(in: &subscriptions)

        model.cardGridViewModel.$showGrid.dropFirst().removeDuplicates().sink { [weak self] showGrid in
            self?.model.bottomBarViewModel.centerButtonViewModel.mode = showGrid ? .showAsPlus : .showAsText
        }.store(in: &subscriptions)

        model.$suppressInteraction.sink { [weak self] suppressInteraction in
            self?.view.isUserInteractionEnabled = !suppressInteraction
        }.store(in: &subscriptions)
    }

    private func setupWebContentObservers(for webContent: WebContent?) {
        // TODO: Maybe we should be listening to all WebContent instead of just the selected one?
        webContentSubscriptions.removeAll()

        guard let webContent else { return }

        webContent.$url.sink { [weak self] url in
            guard let self else { return }
            model.tabsModel.update(.url(url), forTabByID: webContent.id, inSection: model.currentTabsSection)
            model.bottomBarViewModel.centerButtonViewModel.text = url?.host() ?? ""
            resetBottomBarOffset()
        }.store(in: &webContentSubscriptions)

        webContent.$progress.sink { [weak self] progress in
            self?.model.bottomBarViewModel.centerButtonViewModel.progress = progress
        }.store(in: &webContentSubscriptions)

        webContent.$title.sink { [weak self] title in
            guard let self else { return }
            model.tabsModel.update(.title(title), forTabByID: webContent.id, inSection: model.currentTabsSection)
        }.store(in: &webContentSubscriptions)

        webContent.$favicon.sink { [weak self] favicon in
            guard let self else { return }
            model.tabsModel.update(.favicon(favicon), forTabByID: webContent.id, inSection: model.currentTabsSection)
        }.store(in: &webContentSubscriptions)

        webContent.$thumbnail.sink { [weak self] thumbnail in
            guard let self else { return }
            model.tabsModel.update(.thumbnail(thumbnail), forTabByID: webContent.id, inSection: model.currentTabsSection)
        }.store(in: &webContentSubscriptions)

        webContent.$interactionState.sink { [weak self] state in
            guard let self else { return }
            model.tabsModel.update(.interactionState(state), forTabByID: webContent.id, inSection: model.currentTabsSection)
        }.store(in: &webContentSubscriptions)
    }

    private func updateLayout(animated: Bool) {
        let safeAreaInsets = view.safeAreaInsets
        let newHeight = safeAreaInsets.bottom + bottomBarMaxOffset

        model.cardGridViewModel.additionalContentInsets = .init(top: 0, left: 0, bottom: bottomBarMaxOffset, right: 0)

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
