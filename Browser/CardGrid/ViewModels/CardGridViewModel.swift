// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import SwiftUI

class CardGridViewModel<Card>: ObservableObject where Card: CardModel {
    struct CardDetails: Identifiable {
        let model: CardViewModel<Card>
        var id: Card.ID { model.card.id }
        init(card: Card) {
            self.model = .init(card: card)
        }
    }

    @Published private(set) var allDetails: [CardDetails]
    @Published private(set) var zoomed: Bool = true
    @Published private(set) var showContent: Bool = true
    @Published private(set) var selectedCardId: Card.ID?
    @Published private(set) var hideOverlays = false
    @Published private(set) var scrollToSelectedCardId: Int = 0

    private var scrollView: UIScrollView?
    private var scrollViewObserver: ScrollViewObserver?
    private var scrollViewDirectionSub: AnyCancellable?

    init(cards: [Card]) {
        self.allDetails = cards.map { CardDetails(card: $0) }
    }

    func cardDetails(for id: Card.ID) -> CardDetails? {
        allDetails.first(where: { $0.id == id })
    }

    func cardIndex(for id: Card.ID) -> Int? {
        allDetails.firstIndex(where: { $0.id == id })
    }

    var selectedCardDetails: CardDetails? {
        guard let id = selectedCardId else {
            return nil
        }
        return cardDetails(for: id)
    }

    func updateThumbnailForSelectedCard(completion: @escaping () -> Void) {
        if let details = selectedCardDetails {
            details.model.card.updateThumbnail(completion: completion)
        } else {
            DispatchQueue.main.async(execute: completion)
        }
    }

    func observe(scrollView: UIScrollView) {
        guard self.scrollView !== scrollView else {
            return
        }
        self.scrollView = scrollView

        scrollViewObserver = ScrollViewObserver(scrollView: scrollView)
        scrollViewDirectionSub = scrollViewObserver?.$direction.sink { [weak self] direction in
            self?.hideOverlays = (direction == .down)
        }
    }
}

// MARK: Mutation

extension CardGridViewModel {
    func selectCard(byId id: Card.ID) {
        selectedCardId = id
    }

    private func append(card: Card) -> CardDetails {
        assert(cardDetails(for: card.id) == nil)

        let details = CardDetails(card: card)
        allDetails.append(details)
        return details
    }

    private func insert(card: Card, after parentId: Card.ID) -> CardDetails {
        assert(cardDetails(for: card.id) == nil)
        assert(cardDetails(for: parentId) != nil)  // Parent must exist!

        let parentIndex = cardIndex(for: parentId)!

        let details = CardDetails(card: card)
        allDetails.insert(details, at: parentIndex + 1)
        return details
    }

    func appendAndSelect(card: Card) {
        selectCard(byId: append(card: card).id)
    }

    func insertAndSelect(childCard: Card) {
        assert(selectedCardId != nil)  // A child must have a parent!
        selectCard(byId: insert(card: childCard, after: selectedCardId!).id)
    }
}

// MARK: Zoom

extension CardGridViewModel {
    func zoomIn() {
        guard !zoomed else { return }

        scrollToSelectedCardId += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
            // Update showContent immediately to hide the content overlay
            showContent = false
            withAnimation(CardUX.transitionAnimation) {
                zoomed = true
            }
        }
    }

    func zoomOut() {
        guard zoomed else { return }

        // showContent updated after the animation completes

        let startAnimation = {
            withAnimation(CardUX.transitionAnimation) {
                self.zoomed = false
            }
        }

        if showContent, let details = selectedCardDetails {
            details.model.card.updateThumbnail(completion: startAnimation)
        } else {
            startAnimation()
        }
    }

    func onZoomCompleted() {
        if zoomed {
            showContent = true
        }
    }
}

// MARK: Card actions

extension CardGridViewModel {
    func activateCard(byId id: Card.ID) {
        selectCard(byId: id)
        if !zoomed {
            zoomIn()
        }
    }

    func closeCard(byId id: Card.ID) {
        guard let doomedIndex = cardIndex(for: id) else {
            return
        }
        allDetails.remove(at: doomedIndex)
        if id == selectedCardId {
            // Choose another card to select
            var indexToSelect = doomedIndex
            if allDetails.count == 0 {
                indexToSelect = -1
            } else if indexToSelect == allDetails.count {
                indexToSelect -= 1
            }
            if indexToSelect < 0 {
                selectedCardId = nil
            } else {
                selectedCardId = allDetails[indexToSelect].id
            }
        }
    }

    func onCreated(childCard: Card) {
        updateThumbnailForSelectedCard { [self] in
            insertAndSelect(childCard: childCard)
        }
    }
}
