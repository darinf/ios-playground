// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import SwiftUI

class CardGridViewModel<Card>: ObservableObject where Card: CardModel {
    @Published private(set) var zoomed: Bool = false
    @Published var showContent: Bool = false
    @Published var selectedCardId: String?

    struct CardDetail: Identifiable {
        let model: CardViewModel<Card>
        var id: String { model.card.id }
        init(card: Card) {
            self.model = .init(card: card)
        }
    }

    let cards: [CardDetail]

    var selectedCard: CardDetail? {
        cards.first(where: { $0.id == selectedCardId })
    }

    init(cards: [Card]) {
        self.cards = cards.map { CardDetail(card: $0) }
    }

    func zoomIn() {
        // Update showContent immediately to hide the content overlay
        showContent = false
        withAnimation(CardUX.transitionAnimation) {
            zoomed = true
        }
    }

    func zoomOut() {
        // showContent updated after the animation completes
        withAnimation(CardUX.transitionAnimation) {
            zoomed = false
        }
    }
}
