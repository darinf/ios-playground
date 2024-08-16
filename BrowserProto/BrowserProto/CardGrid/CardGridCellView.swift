import UIKit

final class CardGridCellView: UICollectionViewCell {
    enum Action {
        case closed
    }

    var handler: ((Action) -> Void)?

    var card: Card? {
        didSet {
            cardView?.removeFromSuperview()
            cardView = nil
            cardViewModel = nil

            guard let card, !card.hidden else { return }

            let model = CardViewModel(selected: isSelected, thumbnail: card.thumbnail, title: card.title, favicon: card.favicon)
            let view = CardView(model: model) { [weak self] action in
                guard let self else { return }
                switch action {
                case .closed:
                    handler?(.closed)
                }
            }
            cardView = view
            cardViewModel = model

            contentView.addSubview(view)
            view.activateContainmentConstraints(inside: self)
        }
    }

    private var cardView: CardView?
    private var cardViewModel: CardViewModel?

    override var isSelected: Bool {
        didSet {
            cardViewModel?.selected = isSelected
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        handler = nil
        card = nil
    }
}
