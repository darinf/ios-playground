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

    var selectedCard: WebContentsCardModel? {
        cardGridViewModel.selectedCardDetails?.model.card
    }

    private func observe(cardDetails: CardGridViewModel<WebContentsCardModel>.CardDetails?) {
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
}

// MARK: OmniBar
extension BrowserViewModel {
    func handleOmniBarAction(_ action: OmniBarView.Action) {
        switch action {
        case .urlField:
            presentZeroQuery(target: .existingCard)
        case .newCard:
            presentZeroQuery(target: .newCard)
            break
        case .showCards:
            if cardGridViewModel.zoomed {
                cardGridViewModel.zoomOut()
            } else {
                cardGridViewModel.zoomIn()
            }
        case .showMenu:
            print(">>> showMenu")
        }
    }
}

// MARK: ZeroQuery
extension BrowserViewModel {
    func presentZeroQuery(target: ZeroQueryViewModel.Target) {
        zeroQueryViewModel.target = target
        if case .existingCard = target {
            zeroQueryViewModel.urlFieldViewModel.input = omniBarViewModel.urlFieldViewModel.input
        } else {
            zeroQueryViewModel.urlFieldViewModel.input = ""
        }
        withAnimation {
            showZeroQuery = true
        }
    }

    func dismissZeroQuery() {
        withAnimation {
            showZeroQuery = false
        }
    }

    func handleZeroQueryAction(_ action: ZeroQueryView.Action) {
        switch action {
        case .cancel:
            dismissZeroQuery()
        case .navigate(let input):
            print(">>> navigate to \(input)")

            omniBarViewModel.urlFieldViewModel.input = input
            dismissZeroQuery()

            let url = URL(string: input)

            if case .newCard = zeroQueryViewModel.target {
                // Create new card and select it.
                let newCard = WebContentsCardModel(url: url)
                cardGridViewModel.appendCard(card: newCard)
                cardGridViewModel.selectedCardId = newCard.id
            }

            if let selectedCard = selectedCard {
                if let url = url {
                    selectedCard.navigate(to: url)
                } else {
                    //selectedCard.navigate(to: URL(string: "https://neeva.com/search?q=\(input)")!)
                }
            }
        }
    }
}
