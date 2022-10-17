// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import SwiftUI

class BrowserViewModel: ObservableObject {
    private var subscriptions: Set<AnyCancellable> = []
    private var selectedCardSubscriptions: Set<AnyCancellable> = []

    let cardGridViewModel: CardGridViewModel<WebContentsCardModel>
    let omniBarViewModel = OmniBarViewModel()
    let zeroQueryViewModel = ZeroQueryViewModel()

    @Published private(set) var showZeroQuery = false

    var selectedCard: WebContentsCardModel? {
        cardGridViewModel.selectedCardDetails?.model.card
    }

    private func updateThumbnailForSelectedCard(completion: @escaping () -> Void) {
        if let selectedCard = selectedCard {
            selectedCard.updateThumbnail(completion: completion)
        } else {
            DispatchQueue.main.async(execute: completion)
        }
    }

    private func observe(cardDetails: CardGridViewModel<WebContentsCardModel>.CardDetails?) {
        selectedCardSubscriptions = []

        guard let details = cardDetails else {
            omniBarViewModel.urlFieldViewModel.reset()
            omniBarViewModel.canEditCurrentUrl = false
            return
        }

        let card = details.model.card

        omniBarViewModel.canEditCurrentUrl = true

        card.$url.sink { [weak self] url in
            self?.omniBarViewModel.urlFieldViewModel.input = url?.absoluteString ?? ""
        }.store(in: &selectedCardSubscriptions)

        card.$isLoading.sink { [weak self] isLoading in
            if isLoading {
                self?.omniBarViewModel.update(hidden: false)
            }
            self?.omniBarViewModel.urlFieldViewModel.update(isLoading: isLoading)
        }.store(in: &selectedCardSubscriptions)

        card.$estimatedProgress.sink { [weak self] estimatedProgress in
            self?.omniBarViewModel.urlFieldViewModel.update(progress: estimatedProgress)
        }.store(in: &selectedCardSubscriptions)

        card.$hideOverlays.sink { [weak self] hideOverlays in
            self?.omniBarViewModel.update(hidden: hideOverlays)
        }.store(in: &selectedCardSubscriptions)

        card.childCardPublisher.sink { [weak self] newCard in
            guard let self = self else { return }
            self.updateThumbnailForSelectedCard {
                self.cardGridViewModel.selectCardDetails(
                    details: self.cardGridViewModel.appendCard(card: newCard))
            }
        }.store(in: &selectedCardSubscriptions)
    }

    init() {
        let initialCards: [WebContentsCardModel] = [
            .init(url: URL(string: "https://news.ycombinator.com/")!)
        ]
        self.cardGridViewModel = .init(cards: initialCards)
        cardGridViewModel.$hideOverlays.sink { [weak self] hideOverlays in
            self?.omniBarViewModel.update(hidden: hideOverlays)
        }.store(in: &subscriptions)

        // Observe selected card's URL. Observe asynchronously to let other updates happen first.
        self.cardGridViewModel.$selectedCardId.receive(on: DispatchQueue.main).sink { [weak self] id in
            guard let self = self else { return }
            if let id = id {
                self.observe(cardDetails: self.cardGridViewModel.cardDetails(for: id))
            } else {
                self.observe(cardDetails: nil)
            }
        }.store(in: &subscriptions)
    }
}

// MARK: OmniBar
extension BrowserViewModel {
    func handleOmniBarAction(_ action: OmniBarView.Action) {
        switch action {
        case .urlField:
            presentZeroQuery(target: .existingCard)
        case .newCard:
            updateThumbnailForSelectedCard { [self] in
                presentZeroQuery(target: .newCard)
            }
        case .showCards:
            if cardGridViewModel.zoomed {
                cardGridViewModel.zoomOut()
            } else {
                cardGridViewModel.zoomIn()
            }
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
            omniBarViewModel.urlFieldViewModel.input = input
            dismissZeroQuery()

            let url = UrlFixup.fromUser(input: input)

            if case .newCard = zeroQueryViewModel.target {
                // Create new card and select it.
                let newCard = WebContentsCardModel(url: url)
                cardGridViewModel.selectCardDetails(
                    details: cardGridViewModel.appendCard(card: newCard))
            }

            cardGridViewModel.zoomIn()

            if let selectedCard = selectedCard, let url = url {
                selectedCard.navigate(to: url)
            }
        }
    }
}
