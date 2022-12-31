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
        self.allDetails = Self.buildAllDetails(cards: cards)
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

// MARK: Initialization

extension CardGridViewModel {
    static func buildAllDetails(cards: [Card]) -> [CardDetails] {
        // The given array is not sorted by `nextId`. Our job is produce an array
        // of `CardDetails` that are sorted by `nextId`. However, some cards may
        // not have that field set yet.
        //
        // Step 1: Separate out the cards that have `nextId` set.
        // Step 2: Order the set of cards with `nextId` set.
        // Step 3: Append the remainder of the cards in the given order.

        func getCardById(_ id: Card.ID) -> Card? {
            cards.first(where: { $0.id == id })
        }

        // Separate out the cards that have `nextId` set, indexed by `nextId`.
        let cardsWithNextId: [Card.ID: Card] = .init(
            uniqueKeysWithValues: cards.compactMap { $0.nextId != nil ? ($0.nextId!, $0) : nil }
        )

        // Find the last card referenced by that set. Should be a card not in that set.
        var lastReferencedCard: Card?
        for card in cardsWithNextId {
            if let next = getCardById(card.value.nextId!), next.nextId == nil {
                lastReferencedCard = next
                break
            }
        }
        guard let lastReferencedCard else {
            print(">>> Error: Could not find last referenced card!")
            return cards.map { CardDetails(card: $0) }
        }

        var sortedCards: [Card] = []
        sortedCards.append(lastReferencedCard)

        var last: Card? = lastReferencedCard
        while last != nil {
            let previous = cardsWithNextId[last!.id]
            if let previous {
                sortedCards.insert(previous, at: 0)
            }
            last = previous
        }

        // Exclude lastReferencedCard here since it has already been handled.
        let cardsWithoutNextId = cards.compactMap {
            $0.id != lastReferencedCard.id && $0.nextId == nil ? $0 : nil
        }
        for card in cardsWithoutNextId {
            if let last = sortedCards.last {
                last.nextId = card.id
            }
            sortedCards.append(card)
        }

        return sortedCards.map { CardDetails(card: $0) }
    }
}

// MARK: Mutation

extension CardGridViewModel {
    func selectCard(byId id: Card.ID) {
        selectedCardId = id
    }

    static func append(_ details: CardDetails, to all: inout [CardDetails]) {
        let last = all.last

        all.append(details)
        details.model.card.nextId = nil

        if let last {
            last.model.card.nextId = details.id
        }
    }

    static func insert(_ details: CardDetails, at index: Int, to all: inout [CardDetails]) {
        assert(index < all.count)

        let previous: CardDetails? = index > 0 ? all[index - 1] : nil
        let current = all[index]

        all.insert(details, at: index)
        details.model.card.nextId = current.id

        if let previous {
            previous.model.card.nextId = details.id
        }
    }

    @discardableResult
    static func remove(at index: Int, from all: inout [CardDetails]) -> CardDetails {
        let previous: CardDetails? = index > 0 ? all[index - 1] : nil
        let doomed = all[index]

        all.remove(at: index)

        if let previous {
            previous.model.card.nextId = doomed.model.card.nextId
        }
        return doomed
    }

    private func append(card: Card) -> CardDetails {
        assert(cardDetails(for: card.id) == nil)

        let details = CardDetails(card: card)
        Self.append(details, to: &allDetails)
        return details
    }

    private func insert(card: Card, after parentId: Card.ID) -> CardDetails {
        assert(cardDetails(for: card.id) == nil)
        assert(cardDetails(for: parentId) != nil)  // Parent must exist!

        let parentIndex = cardIndex(for: parentId)!
        let details = CardDetails(card: card)

        Self.insert(details, at: parentIndex + 1, to: &allDetails)

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
            Self.remove(at: doomedIndex, from: &allDetails)
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
        case beforeCard(Card)
        case atEnd
    }

    func move(card: Card, to target: MoveTarget) {
        var newAllDetails = allDetails
        let index = newAllDetails.firstIndex(where: { $0.id == card.id })!
        let details = Self.remove(at: index, from: &newAllDetails)
        switch target {
        case .beforeCard(let targetCard):
            let newIndex = newAllDetails.firstIndex(where: { $0.id == targetCard.id })!
            Self.insert(details, at: newIndex, to: &newAllDetails)
        case .atEnd:
            Self.append(details, to: &newAllDetails)
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
            if sourceIndex + ncols + 1 < maxIndex {
                targetIndex = sourceIndex + ncols + 1
            } else if sourceIndex + ncols + 1 >= maxIndex {
                return .atEnd
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
            } else if sourceIndex + 2 >= maxIndex {
                return .atEnd
            }
            break
        }

        guard let targetIndex else { return nil }

        return .beforeCard(allDetails[targetIndex].model.card)
    }

    func moveCard(_ cardDetail: CardDetails, direction: CardView<Card>.Direction, geom: GeometryProxy) {
        if let target = getMoveTarget(cardDetail.id, direction: direction, geom: geom) {
            cardDetail.model.translationOrigin = cardDetail.model.lastTranslation
            withAnimation {
                move(card: cardDetail.model.card, to: target)
            }
        }
    }
}
