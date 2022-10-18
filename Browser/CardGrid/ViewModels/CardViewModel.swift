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

        // Forward card updates.
        self.subscription = self.card.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }
}
