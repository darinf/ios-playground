// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import Foundation

class CardDraggingModel<Card>: ObservableObject where Card: CardModel {
    @Published private(set) var draggingCard: CardViewModel<Card>? = nil
    @Published private(set) var frame: CGRect = .zero
    @Published var translation: CGSize = .zero

    var isDragging: Bool {
        draggingCard != nil
    }

    func startDragging(card: CardViewModel<Card>, frame: CGRect) {
        draggingCard = card
        self.frame = frame
        self.translation = .zero
    }

    func stopDragging() {
        draggingCard = nil
    }
}
