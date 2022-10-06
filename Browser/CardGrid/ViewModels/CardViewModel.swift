// Copyright 2022 Darin Fisher. All rights reserved.

import Combine

class CardViewModel<Card>: ObservableObject where Card: CardModel {
    let card: Card
    @Published var showDecorations: Bool = true
    @Published var pressed: Bool = false

    init(card: Card) {
        self.card = card
    }
}
