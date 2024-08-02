import Combine
import UIKit

final class CardGridView: UIView {
    private let model: CardGridViewModel
    private let zoomedView: UIView
    private var subscriptions: Set<AnyCancellable> = []

    private lazy var collectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CardGridCellView.self, forCellWithReuseIdentifier: "cell")

        return collectionView
    }()

    init(model: CardGridViewModel, zoomedView: UIView) {
        self.model = model
        self.zoomedView = zoomedView
        super.init(frame: .zero)

        addSubview(collectionView)
        addSubview(zoomedView)

        collectionView.activateContainmentConstraints(inside: self)
        zoomedView.activateContainmentConstraints(inside: self)

        self.bringSubviewToFront(zoomedView)

        setupObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupObservers() {
        model.$showGrid.dropFirst().sink { [weak self] showGrid in
            self?.zoomedView.isHidden = showGrid
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
                (collectionView.cellForItem(at: .init(item: index, section: 0)) as! CardGridCellView).card = card
            default:
                collectionView.reloadData()
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
        cell.handler = { [model] action in
            switch action {
            case .closed:
                model.removeCard(byID: card.id)
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
        print(">>> didSelectItemAt: \(indexPath)")
        model.selectedID = model.cards[indexPath.item].id
        model.showGrid = false
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
