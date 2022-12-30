// Copyright 2022 Darin Fisher. All rights reserved.

import Combine

class CardDraggingModel<Card>: ObservableObject where Card: CardModel {
    @Published private(set) var draggingCard: Card? = nil

    var isDragging: Bool {
        draggingCard != nil
    }

    func startDragging(card: Card) {
        draggingCard = card
    }

    func stopDragging() {
        draggingCard = nil
    }
}
