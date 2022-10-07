// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import Foundation

class CardViewModel<Card>: ObservableObject where Card: CardModel {
    let card: Card
    @Published var showDecorations: Bool = true
    @Published var pressed: Bool = false

    private var subscription: AnyCancellable?

    init(card: Card) {
        self.card = card

        self.subscription = self.card.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }
    }
}
