// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import SwiftUI

class CardGridViewModel<Card>: ObservableObject where Card: CardModel {
    @Published var zoomed: Bool = false
    @Published var selectedCardId: String?

    struct CardDetail: Identifiable {
        let model: CardViewModel<Card>
        var id: String { model.card.id }
        init(card: Card) {
            self.model = .init(card: card)
        }
    }

    let cards: [CardDetail]

    init(cards: [Card]) {
        self.cards = cards.map { CardDetail(card: $0) }
    }

    func zoomOut() {
        withAnimation(CardUX.transitionAnimation) {
            zoomed = false
        }
    }
}
