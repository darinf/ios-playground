// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import SwiftUI

class CardGridViewModel<Card>: ObservableObject where Card: CardModel {
    @Published private(set) var zoomed: Bool = true
    @Published var showContent: Bool = true
    @Published var selectedCardId: String?

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

    func appendCard(card: Card) {
        self.allDetails.append(CardDetails(card: card))
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
            details.model.card.prepareToShowAsThumbnail() { startAnimation() }
        } else {
            startAnimation()
        }
    }
}
