import Combine
import UIKit

final class OverlayCardView: UIView {
    private let model: OverlayCardViewModel
    private var cardView: CardView?
    private var cardViewModel: CardViewModel?
    private var cardViewRect: CGRect?
    private var subscriptions: Set<AnyCancellable> = []

    init(model: OverlayCardViewModel) {
        self.model = model
        super.init(frame: .zero)

        isUserInteractionEnabled = false

        setupObservers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        guard let cardView else { return }
        if let cardViewRect {
            cardView.frame = cardViewRect
        } else {
            cardView.frame = bounds.inset(by: .init(
                top: safeAreaInsets.top,
                left: safeAreaInsets.left,
                bottom: 0,
                right: safeAreaInsets.right
            ))
        }
    }

    private func setupObservers() {
        model.$state.sink { [weak self] state in
            guard let self else { return }
            switch state {
            case .hidden:
                removeCardView()
            case let .transitionToGrid(card: card, cardAt: cardRect):
                transitionToGrid(card: card, cardAt: cardRect)
            case let .transitionToZoomed(card: card, cardAt: cardRect):
                transitionToZoomed(card: card, cardAt: cardRect)
            }
        }.store(in: &subscriptions)
    }

    private func transitionToGrid(card: Card?, cardAt cardRect: CGRect?) {
        let cardViewModel = createCardViewIfNeeded(card: card)

        cardViewModel.selected = false
        cardViewModel.hideDecorations = true

        layoutIfNeeded()

        cardViewRect = cardRect
        setNeedsLayout()

        UIView.animate(withDuration: 0.3) { [self] in
            cardViewModel.selected = true
            cardViewModel.hideDecorations = false
            layoutIfNeeded()
        } completion: { [self] _ in
            guard case .transitionToGrid = model.state else { return }
            model.state = .hidden
        }
    }

    private func transitionToZoomed(card: Card?, cardAt cardRect: CGRect?) {
        let cardViewModel = createCardViewIfNeeded(card: card)

        cardViewModel.selected = true
        cardViewModel.hideDecorations = false

        cardViewRect = cardRect
        setNeedsLayout()

        layoutIfNeeded()

        cardViewRect = nil
        setNeedsLayout()

        UIView.animate(withDuration: 0.3) { [self] in
            cardViewModel.selected = false
            cardViewModel.hideDecorations = true
            layoutIfNeeded()
        } completion: { [self] _ in
            guard case .transitionToZoomed = model.state else { return }
            model.state = .hidden
        }
    }

    private func createCardViewIfNeeded(card: Card?) -> CardViewModel {
        if let cardViewModel {
            return cardViewModel
        }

        let cardViewModel = CardViewModel(selected: false, thumbnail: card?.thumbnail, title: card?.title, favicon: card?.favicon)
        let cardView = CardView(model: cardViewModel)

        self.cardViewModel = cardViewModel
        self.cardView = cardView

        addSubview(cardView)

        return cardViewModel
    }

    private func removeCardView() {
        cardView?.removeFromSuperview()
        cardView = nil
        cardViewModel = nil
        cardViewRect = nil
    }
}
