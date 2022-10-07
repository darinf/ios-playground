// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import SwiftUI

class BrowserViewModel: ObservableObject {
    private var selectedCardIdSubscription: AnyCancellable?
    private var selectedCardUrlSubscription: AnyCancellable?

    let cardGridViewModel: CardGridViewModel<WebContentsCardModel>
    let omniBarViewModel = OmniBarViewModel()
    let zeroQueryViewModel = ZeroQueryViewModel()
    let webContentsViewModel = WebContentsViewModel()

    @Published private(set) var showZeroQuery = false

    func presentZeroQuery() {
        zeroQueryViewModel.urlFieldViewModel.input = omniBarViewModel.urlFieldViewModel.input
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
        let initialCards: [WebContentsCardModel] = [
            .init()
        ]
        self.cardGridViewModel = .init(cards: initialCards)

        // Observe selected card's URL.
        self.selectedCardIdSubscription = self.cardGridViewModel.$selectedCardId.sink { id in
            if let id = id, let cardDetail = self.cardGridViewModel.card(for: id) {
                self.selectedCardUrlSubscription = cardDetail.model.card.$url.sink { url in
                    self.omniBarViewModel.urlFieldViewModel.input = url?.absoluteString ?? ""
                }
            } else {
                self.selectedCardUrlSubscription = nil
            }
        }
    }
}
