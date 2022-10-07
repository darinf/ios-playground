// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

class BrowserViewModel: ObservableObject {
    let cardGridViewModel: CardGridViewModel<WebContentsCardModel>
    let omniBarViewModel = OmniBarViewModel()
    let zeroQueryViewModel = ZeroQueryViewModel()
    let webContentsViewModel = WebContentsViewModel()

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

    var selectedCard: WebContentsCardModel? {
        cardGridViewModel.selectedCard?.model.card
    }

    init() {
//        let cards: [ColorCardModel] = [
//            .init(title: "First", color: .systemBlue),
//            .init(title: "Second", color: .systemPink),
//            .init(title: "Third", color: .systemPurple),
//            .init(title: "Fourth", color: .systemTeal),
//            .init(title: "Fifth", color: .systemOrange),
//            .init(title: "Sixth", color: .systemGreen),
//            .init(title: "Seventh", color: .systemIndigo),
//            .init(title: "Eighth", color: .systemRed),
//            .init(title: "Ninth", color: .systemBrown)
//        ]
//
        let initialCards: [WebContentsCardModel] = [
            .init(url: URL(string: "https://news.ycombinator.com/")!)
        ]
        self.cardGridViewModel = .init(cards: initialCards)
    }
}
