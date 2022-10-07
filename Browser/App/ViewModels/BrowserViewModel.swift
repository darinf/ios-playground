// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

class BrowserViewModel: ObservableObject {
    let cardGridViewModel: CardGridViewModel<ColorCardModel>
    let omniBarViewModel = OmniBarViewModel()
    let zeroQueryViewModel = ZeroQueryViewModel()

    @Published private(set) var showZeroQuery = false

    func presentZeroQuery() {
        withAnimation {
            showZeroQuery = true
        }
    }

    func dismissZeroQuery() {
        withAnimation {
            showZeroQuery = false
        }
    }

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
