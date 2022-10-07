// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import SwiftUI

class BrowserViewModel: ObservableObject {
    private var selectedCardIdSubscription: AnyCancellable?
    private var selectedCardSubscriptions: Set<AnyCancellable> = []

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
        cardGridViewModel.selectedCardDetails?.model.card
    }

    init() {
        let initialCards: [WebContentsCardModel] = [
            .init(url: URL(string: "https://news.ycombinator.com/")!)
        ]
        self.cardGridViewModel = .init(cards: initialCards)

        // Observe selected card's URL.
        self.selectedCardIdSubscription = self.cardGridViewModel.$selectedCardId.sink { [weak self] id in
            guard let self = self else { return }
            if let id = id {
                self.observe(cardDetails: self.cardGridViewModel.cardDetails(for: id))
            } else {
                self.observe(cardDetails: nil)
            }
        }
    }

    func observe(cardDetails: CardGridViewModel<WebContentsCardModel>.CardDetails?) {
        guard let details = cardDetails else {
            self.selectedCardSubscriptions = []
            return
        }

        let card = details.model.card

        card.$url.sink { url in
            DispatchQueue.main.async {
                self.omniBarViewModel.urlFieldViewModel.input = url?.absoluteString ?? ""
            }
        }.store(in: &selectedCardSubscriptions)

        card.$hideOverlays.sink { hideOverlays in
            DispatchQueue.main.async {
                self.omniBarViewModel.update(hidden: hideOverlays)
            }
        }.store(in: &selectedCardSubscriptions)

    }
}
