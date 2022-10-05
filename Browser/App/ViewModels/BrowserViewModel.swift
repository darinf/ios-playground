// Copyright 2022 Darin Fisher. All rights reserved.

import Combine

class BrowserViewModel: ObservableObject {
    let cardGridViewModel: CardGridViewModel<ColorCardModel>

    init() {
        let cards: [ColorCardModel] = [
            .init(title: "First", color: .systemBlue),
            .init(title: "Second", color: .systemPink),
            .init(title: "Third", color: .systemPurple),
            .init(title: "Fourth", color: .systemTeal),
            .init(title: "Fifth", color: .systemOrange),
            .init(title: "Sixth", color: .systemGreen),
            .init(title: "Seventh", color: .systemIndigo),
            .init(title: "Eighth", color: .systemRed),
            .init(title: "Ninth", color: .systemBrown)
        ]

        self.cardGridViewModel = .init(cards: cards)
    }
}
