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
    @Published private(set) var scrollToSelectedCardId: Int = 0

    private var overlayModel: OverlayModel
    private var overlayUpdater: OverlayUpdater?
    private var scrollView: UIScrollView?
    private(set) var draggingModel: CardDraggingModel<Card> = .init()

    init(cards: [Card], selectedCardId: Card.ID?, overlayModel: OverlayModel) {
        self.allDetails = cards.map { CardDetails(card: $0) }
        self.selectedCardId = selectedCardId
        self.overlayModel = overlayModel
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
            // Run completion asynchronously here to simulate code path for when
            // a snapshot is actually taken.
            DispatchQueue.main.async(execute: completion)
        }
    }

    func setScrollView(_ scrollView: UIScrollView) {
        guard self.scrollView !== scrollView else {
            return
        }
        self.scrollView = scrollView
    }

    func observeScrollView(_ scrollView: UIScrollView) {
        guard self.scrollView !== scrollView else {
            return
        }
        self.scrollView = scrollView
        overlayUpdater = .init(scrollView: scrollView, overlayModel: overlayModel)
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

        scrollToSelectedCardId += 1

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
        withAnimation {
            allDetails[doomedIndex].model.card.close()
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
    }

    func onCreated(childCard: Card) {
        updateThumbnailForSelectedCard { [self] in
            insertAndSelect(childCard: childCard)
        }
    }
}

// MARK: Re-ordering

extension CardGridViewModel {
    enum MoveTarget {
        case existingCard(Card)
        case end
    }

    func move(card: Card, to target: MoveTarget) {
        var newAllDetails = allDetails
        let index = newAllDetails.firstIndex(where: { $0.id == card.id })!
        let details = newAllDetails.remove(at: index)
        switch target {
        case .existingCard(let targetCard):
            let newIndex = newAllDetails.firstIndex(where: { $0.id == targetCard.id })!
            newAllDetails.insert(details, at: newIndex)
        case .end:
            newAllDetails.append(details)
        }
        allDetails = newAllDetails
    }

    func numberOfColumns(geom: GeometryProxy) -> Int {
        // viewWidth = ((ncols + 1) * spacing) + (ncols * cardWidth)
        // viewWidth = ncols * spacing + spacing + ncols * cardWidth
        // viewWidth = ncols * (spacing + cardWidth) + spacing
        // ncols = (viewWidth - spacing) / (spacing + cardWidth)
        Int((geom.size.width - CardGridUX.spacing) / (CardGridUX.spacing + CardUX.minimumCardWidth))
    }

    func getMoveTarget(_ sourceId: Card.ID, direction: CardView<Card>.Direction, geom: GeometryProxy) -> MoveTarget? {
        let ncols = numberOfColumns(geom: geom)
        let sourceIndex = allDetails.firstIndex(where: { $0.id == sourceId })!
        let sourceCol = sourceIndex % ncols
        let maxIndex = allDetails.count - 1

        var targetIndex: Int? = nil
        switch direction {
        case .up:
            if sourceIndex - ncols >= 0 {
                targetIndex = sourceIndex - ncols
            }
            break
        case .down:
            if sourceIndex + ncols < maxIndex {
                targetIndex = sourceIndex + ncols
            }
            break
        case .left:
            if sourceCol > 0 && sourceIndex > 0 {
                targetIndex = sourceIndex - 1
            }
            break
        case .right:
            if sourceCol < (ncols - 1) && sourceIndex < (maxIndex - 1) {
                targetIndex = sourceIndex + 2
            }
            break
        }

        guard let targetIndex else { return nil }

        print(">>> new targetIndex: \(targetIndex), sourceIndex was \(sourceIndex)")

        return .existingCard(allDetails[targetIndex].model.card)
    }

    func moveCard(_ cardDetail: CardDetails, direction: CardView<Card>.Direction, geom: GeometryProxy) {
        print(">>> moveCard, direction: \(direction)")
        if let target = getMoveTarget(cardDetail.id, direction: direction, geom: geom) {
            cardDetail.model.translationOrigin = cardDetail.model.lastTranslation
            withAnimation {
                move(card: cardDetail.model.card, to: target)
            }
        }
    }
}
