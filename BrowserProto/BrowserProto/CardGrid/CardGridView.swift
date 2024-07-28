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
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")

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

        model.cardsChanges.sink { [weak self] change in
            guard let self else { return }
            print(">>> cards change: \(change)")
            // XXX hack
            collectionView.reloadData()
        }.store(in: &subscriptions)
    }
}

extension CardGridView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        model.cards.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        let card = model.cards[indexPath.item]
        if let thumbnail = card.thumbnail {
            cell.backgroundColor = .clear
            cell.backgroundView = UIImageView(image: thumbnail)
        } else {
            cell.backgroundColor = .systemTeal
        }
        return cell
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
