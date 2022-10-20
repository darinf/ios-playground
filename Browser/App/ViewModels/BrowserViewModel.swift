// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import SwiftUI

class BrowserViewModel: ObservableObject {
    private var subscriptions: Set<AnyCancellable> = []
    private var selectedCardSubscriptions: Set<AnyCancellable> = []
    private let store = Store()
    private let webContentsContext: WebContentsContext

    let cardGridViewModel: CardGridViewModel<WebContentsCardModel>
    let omniBarViewModel = OmniBarViewModel()
    let zeroQueryViewModel = ZeroQueryViewModel()

    @Published private(set) var showZeroQuery = false

    init() {
        webContentsContext = .init(store: store)

        // TODO: consider reading data asynchronously at startup?
        cardGridViewModel = .init(
            cards: store.fetchStoredCards().map { [webContentsContext] in
                .init(context: webContentsContext, storedCard: $0)
            }
        )

        cardGridViewModel.$hideOverlays
            .sink(receiveValue: omniBarViewModel.update(hidden:))
            .store(in: &subscriptions)

        // Observe selected card's URL. Observe asynchronously to let other updates happen first.
        self.cardGridViewModel.$selectedCardId
            .receive(on: DispatchQueue.main)
            .map { [cardGridViewModel] id in
                guard let id = id else { return nil }
                return cardGridViewModel.cardDetails(for: id)
            }
            .sink { [weak self] cardDetails in
                self?.onSelect(cardDetails: cardDetails)
            }
            .store(in: &subscriptions)
    }

    private func onSelect(cardDetails: CardGridViewModel<WebContentsCardModel>.CardDetails?) {
        selectedCardSubscriptions = []

        guard let details = cardDetails else {
            omniBarViewModel.urlFieldViewModel.reset()
            omniBarViewModel.canEditCurrentUrl = false
            return
        }

        let card = details.model.card

        omniBarViewModel.canEditCurrentUrl = true

        card.$url
            .map { $0?.absoluteString ?? "" }
            .assign(to: \.input, on: omniBarViewModel.urlFieldViewModel)
            .store(in: &selectedCardSubscriptions)

        card.$isLoading
            .sink(receiveValue: omniBarViewModel.update(isLoading:))
            .store(in: &selectedCardSubscriptions)

        card.$estimatedProgress
            .sink(receiveValue: omniBarViewModel.urlFieldViewModel.update(progress:))
            .store(in: &selectedCardSubscriptions)

        card.$hideOverlays
            .sink(receiveValue: omniBarViewModel.update(hidden:))
            .store(in: &selectedCardSubscriptions)

        card.childCardPublisher
            .sink(receiveValue: cardGridViewModel.onCreated(childCard:))
            .store(in: &selectedCardSubscriptions)
    }
}

// MARK: OmniBar
extension BrowserViewModel {
    func handleOmniBarAction(_ action: OmniBarView.Action) {
        switch action {
        case .urlField:
            presentZeroQuery(target: .existingCard)
        case .newCard:
            cardGridViewModel.updateThumbnailForSelectedCard { [self] in
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

            let url = UrlFixup.fromUser(input: input)

            if case .newCard = zeroQueryViewModel.target {
                cardGridViewModel.appendAndSelect(
                    card: WebContentsCardModel(context: webContentsContext, url: url))
            }

            cardGridViewModel.zoomIn()

            if let details = cardGridViewModel.selectedCardDetails, let url = url {
                details.model.card.navigate(to: url)
            }

            // Dismiss as last step so that only the new card is shown.
            dismissZeroQuery()
        }
    }
}
