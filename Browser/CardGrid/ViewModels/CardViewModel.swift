// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import Foundation

class CardViewModel<Card>: ObservableObject where Card: CardModel {
    let card: Card
    @Published var showDecorations: Bool = true
    @Published var pressed: Bool
    @Published var longPressed: Bool = false
    var lastTranslation: CGSize = .zero
    var translationOrigin: CGSize = .zero {
        didSet {
            print(">>> didSet translationOrigin: \(translationOrigin)")
        }
    }

    private var subscription: AnyCancellable?

    init(card: Card, pressed: Bool = false) {
        self.card = card
        self.pressed = pressed

        // Forward card updates.
        self.subscription = self.card.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }
}
