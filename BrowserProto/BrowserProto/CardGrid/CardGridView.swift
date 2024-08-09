import Combine
import UIKit

final class CardGridView: UIView {
    enum Action {
        case selectCard(byID: Card.ID)
        case removeCard(byID: Card.ID)
    }

    private let model: CardGridViewModel
    private let zoomedView: UIView
    private let handler: (Action) -> Void
    private let overlayCardView: OverlayCardView
    private var subscriptions: Set<AnyCancellable> = []

    private lazy var collectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16 + CardView.Metrics.bottomMargin
        layout.minimumInteritemSpacing = 10

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CardGridCellView.self, forCellWithReuseIdentifier: "cell")

        return collectionView
    }()

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

            // TODO: handle case of a cell that is not visible
            let index = model.indexByID(selectedID)
//            collectionView.indexPathsForVisibleItems
//            collectionView.scrollToItem(at: .init(item: index, section: 0), at: .top, animated: <#T##Bool#>)

            let attributes = collectionView.layoutAttributesForItem(at: .init(item: index, section: 0))
            let rect = attributes?.frame

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
                collectionView.selectItem(at: nil, animated: false, scrollPosition: .top)
                return
            }
            let index = model.indexByID(selectedID)
            collectionView.selectItem(at: .init(item: index, section: 0), animated: false, scrollPosition: .top)
        }.store(in: &subscriptions)

        model.cardsChanges.sink { [weak self] change in
            guard let self else { return }
            print(">>> cards change: \(change)")
            switch change {
            case let .updated(card, atIndex: index):
                guard let cell = collectionView.cellForItem(at: .init(item: index, section: 0)) else { return }
                (cell as! CardGridCellView).card = card
            default:
                collectionView.reloadData()
            }
        }.store(in: &subscriptions)

        model.overlayCardViewModel.$state.removeDuplicates().sink { [weak self] state in
            guard let self else { return }
            if case .hidden = state {
                zoomedView.isHidden = model.showGrid
                if !model.showGrid {
                    bringSubviewToFront(zoomedView)
                }
            }
        }.store(in: &subscriptions)
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
        let totalSpacing = (collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing
        let itemWidth = (collectionView.bounds.width - totalSpacing) / 2 - 10
        let itemHeight: CGFloat = 200 // Set a fixed height for the cells
        return CGSize(width: itemWidth, height: itemHeight)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
}
