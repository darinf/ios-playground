// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import SwiftUI

class CardGridViewModel<Card>: ObservableObject where Card: CardModel {
    @Published private(set) var zoomed: Bool = true
    @Published var showContent: Bool = true
    @Published private(set) var selectedCardId: String?

    struct CardDetails: Identifiable {
        let model: CardViewModel<Card>
        var id: String { model.card.id }
        init(card: Card) {
            self.model = .init(card: card)
        }
    }

    @Published private(set) var allDetails: [CardDetails]

    func cardDetails(for id: String) -> CardDetails? {
        allDetails.first(where: { $0.id == id })
    }

    var selectedCardDetails: CardDetails? {
        guard let id = selectedCardId else {
            return nil
        }
        return cardDetails(for: id)
    }

    func selectCardDetails(details: CardDetails?) {
        selectedCardId = details?.id ?? nil
    }

    func appendCard(card: Card) -> CardDetails {
        let details = CardDetails(card: card)
        self.allDetails.append(details)
        return details
    }

    init(cards: [Card]) {
        self.allDetails = cards.map { CardDetails(card: $0) }
    }

    func zoomIn() {
        guard !zoomed else { return }

        // Update showContent immediately to hide the content overlay
        showContent = false
        withAnimation(CardUX.transitionAnimation) {
            zoomed = true
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
            details.model.card.updateThumbnail() { startAnimation() }
        } else {
            startAnimation()
        }
    }

    func activateCard(id: String) {
        selectedCardId = id
        if !zoomed {
            zoomIn()
        }
    }

    func closeCard(id: String) {
        if let doomedIndex = allDetails.firstIndex(where: { $0.id == id }) {
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
}
