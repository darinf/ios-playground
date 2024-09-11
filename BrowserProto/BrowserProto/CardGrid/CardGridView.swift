import Combine
import UIKit

final class CardGridView: UIView {
    enum Metrics {
        static let bottomInset: CGFloat = 80
        static let minimumLineSpacing: CGFloat = 16 + CardView.Metrics.bottomMargin
        static let minimumInteritemSpacing: CGFloat = 10
        static let itemHeight: CGFloat = 200
    }

    enum Action {
        case selectCard(byID: Card.ID)
        case removeCard(byID: Card.ID)
        case swappedCards(atIndex1: Int, atIndex2: Int)
    }

    private let model: CardGridViewModel
    private let zoomedView: UIView
    private let handler: (Action) -> Void
    private let overlayCardView: OverlayCardView
    private var subscriptions: Set<AnyCancellable> = []

    private lazy var collectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = Metrics.minimumLineSpacing
        layout.minimumInteritemSpacing = Metrics.minimumInteritemSpacing

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CardGridCellView.self, forCellWithReuseIdentifier: "cell")
        collectionView.alwaysBounceVertical = true
        collectionView.isPrefetchingEnabled = true

        return collectionView
    }()

    private var selectedItemIndex: Int? {
        model.selectedID.map { model.indexByID($0) }
    }

    init(model: CardGridViewModel, zoomedView: UIView, handler: @escaping (Action) -> Void) {
        self.model = model
        self.zoomedView = zoomedView
        self.handler = handler
        self.overlayCardView = .init(model: model.overlayCardViewModel)
        super.init(frame: .zero)

        addSubview(collectionView)
        addSubview(zoomedView)
        addSubview(overlayCardView)

        collectionView.activateContainmentConstraints(inside: self)
        zoomedView.activateContainmentConstraints(inside: self)
        overlayCardView.activateContainmentConstraints(inside: self)

        self.bringSubviewToFront(zoomedView)

        collectionView.addGestureRecognizer(
            UILongPressGestureRecognizer(target: self, action: #selector(onLongPress))
        )

        setupObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupObservers() {
        model.$showGrid.dropFirst().removeDuplicates().sink { [weak self] showGrid in
            guard let self else { return }
            guard let selectedID = model.selectedID else {
                model.overlayCardViewModel.state = .hidden
                zoomedView.isHidden = true
                return
            }

            let card = model.cards[id: selectedID]

            let index = model.indexByID(selectedID)
            scrollToRevealItem(at: index, animated: !showGrid)

            let attributes = collectionView.layoutAttributesForItem(at: .init(item: index, section: 0))
            let rect = attributes?.frame.offsetBy(dx: -collectionView.contentOffset.x, dy: -collectionView.contentOffset.y)

            zoomedView.isHidden = true
            if showGrid {
                model.overlayCardViewModel.state = .transitionToGrid(card: card, cardAt: rect)
            } else {
                model.overlayCardViewModel.state = .transitionToZoomed(card: card, cardAt: rect)
            }
        }.store(in: &subscriptions)

        model.$selectedID.sink { [weak self] selectedID in
            guard let self else { return }
            guard let selectedID else {
                collectionView.selectItem(at: nil, animated: false, scrollPosition: [])
                return
            }
            let index = model.indexByID(selectedID)
            collectionView.selectItem(at: .init(item: index, section: 0), animated: false, scrollPosition: [])
        }.store(in: &subscriptions)

        model.cardsChanges.sink { [weak self] change in
            guard let self else { return }
            switch change {
            case let .updated(card, atIndex: index):
                guard let cell = collectionView.cellForItem(at: .init(item: index, section: 0)) else { return }
                (cell as! CardGridCellView).card = card
            case .swapped:
                break // Ignored as this is driven by collectionView(_:moveItemAt:to:)
            default:
                collectionView.reloadData()
            }
        }.store(in: &subscriptions)

        model.overlayCardViewModel.$state.removeDuplicates().sink { [weak self] state in
            guard let self else { return }
            let hideSelectedCell: Bool
            switch state {
            case .hidden:
                zoomedView.isHidden = model.showGrid
                if !model.showGrid {
                    bringSubviewToFront(zoomedView)
                }
                hideSelectedCell = false
            case .transitionToGrid, .transitionToZoomed:
                hideSelectedCell = true
            }
            if let selectedItemIndex {
                model.update(.hidden(hideSelectedCell), forCardAtIndex: selectedItemIndex)
            }
        }.store(in: &subscriptions)

        model.$additionalContentInsets.sink { [weak self] insets in
            guard let self else { return }
            var adjustedInsets = insets
            adjustedInsets.bottom += (Metrics.minimumLineSpacing - Metrics.minimumInteritemSpacing)
            collectionView.contentInset = adjustedInsets
            collectionView.verticalScrollIndicatorInsets = insets
        }.store(in: &subscriptions)
    }

    private func scrollToRevealItem(at index: Int, animated: Bool) {
        guard let attributes = collectionView.layoutAttributesForItem(at: .init(item: index, section: 0)) else { return }
        let contentOffset = collectionView.contentOffset
        let viewportFrame = attributes.frame.offsetBy(dx: -contentOffset.x, dy: -contentOffset.y)
        let visibleContentBounds = bounds.inset(by: collectionView.adjustedContentInset).insetBy(dx: 0, dy: Metrics.minimumInteritemSpacing)

        let deltaY: CGFloat
        if viewportFrame.minY < visibleContentBounds.minY {
            deltaY = viewportFrame.minY - visibleContentBounds.minY
        } else if viewportFrame.maxY > visibleContentBounds.maxY {
            deltaY = viewportFrame.maxY - visibleContentBounds.maxY
        } else {
            deltaY = 0
        }

        let newY = collectionView.contentOffset.y + deltaY
        UIView.animate(withDuration: animated ? 0.2 : 0) { [collectionView] in
            collectionView.contentOffset.y = newY
        }
    }

    @objc private func onLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            guard let targetIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else { return }
            collectionView.beginInteractiveMovementForItem(at: targetIndexPath)
        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: collectionView))
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
}

extension CardGridView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        model.cards.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CardGridCellView
        let card = model.cards[indexPath.item]
        cell.handler = { [weak self] action in
            guard let self else { return }
            switch action {
            case .closed:
                handler(.removeCard(byID: card.id))
            }
        }
        cell.card = card
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        true
    }

    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        handler(.swappedCards(atIndex1: sourceIndexPath.item, atIndex2: destinationIndexPath.item))
    }
}

extension CardGridView: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        handler(.selectCard(byID: model.cards[indexPath.item].id))
    }
}

extension CardGridView: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let totalSpacing = Metrics.minimumInteritemSpacing
        let itemWidth = (collectionView.bounds.width - totalSpacing) / 2 - Metrics.minimumInteritemSpacing
        let itemHeight: CGFloat = Metrics.itemHeight // Set a fixed height for the cells
        return CGSize(width: itemWidth, height: itemHeight)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return UIEdgeInsets(
            top: Metrics.minimumInteritemSpacing,
            left: Metrics.minimumInteritemSpacing,
            bottom: Metrics.minimumInteritemSpacing,
            right: Metrics.minimumInteritemSpacing
        )
    }
}
