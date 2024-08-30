import Combine
import Foundation
import IdentifiedCollections
import UIKit

final class CardGridViewModel {
    enum CardsChange {
        case appended(Card)
        case inserted(Card, atIndex: Int)
        case removed(atIndex: Int)
        case removedAll
        case updated(Card, atIndex: Int)
        case updatedAll
        case swapped(atIndex1: Int, atIndex2: Int)
    }

    @Published var showGrid = false
    @Published var selectedID: Card.ID?
    @Published var additionalContentInsets: UIEdgeInsets = .zero

    private(set) var cards: IdentifiedArrayOf<Card> = []
    let cardsChanges = PassthroughSubject<CardsChange, Never>()

    let overlayCardViewModel = OverlayCardViewModel()
}

extension CardGridViewModel {
    func containsCard(byID cardID: Card.ID) -> Bool {
        cards[id: cardID] != nil
    }

    func appendCard(_ card: Card) {
        cards.append(card)
        cardsChanges.send(.appended(card))
    }

    func insertCard(_ card: Card, after previousID: Card.ID) {
        let insertionIndex = indexByID(previousID) + 1
        insertCard(card, atIndex: insertionIndex)
    }

    func insertCard(_ card: Card, atIndex index: Int) {
        cards.insert(card, at: index)
        cardsChanges.send(.inserted(card, atIndex: index))
    }

    func removeCard(byID cardID: Card.ID) {
        let removalIndex = indexByID(cardID)
        removeCard(atIndex: removalIndex)
    }

    func removeCard(atIndex index: Int) {
        let card = cards[index]
        cards.remove(at: index)
        cardsChanges.send(.removed(atIndex: index))
        if selectedID == card.id {
            selectedID = nil
        }
    }

    func removeAllCards() {
        cards = []
        cardsChanges.send(.removedAll)
        selectedID = nil
    }

    func replaceAllCards(_ cards: IdentifiedArrayOf<Card>, selectedID: Card.ID?) {
        self.cards = cards
        cardsChanges.send(.updatedAll)
        self.selectedID = selectedID
    }

    func swapCards(atIndex1 index1: Int, atIndex2 index2: Int) {
        cards.swapAt(index1, index2)
        cardsChanges.send(.swapped(atIndex1: index1, atIndex2: index2))
    }

    func updateTitle(_ title: String?, forCardByID cardID: Card.ID) {
        let cardIndex = indexByID(cardID)
        updateTitle(title, forCardAtIndex: cardIndex)
    }

    func updateTitle(_ title: String?, forCardAtIndex index: Int) {
        cards[index].title = title
        cardsChanges.send(.updated(cards[index], atIndex: index))
    }

    func updateFavicon(_ favicon: ImageRef?, forCardByID cardID: Card.ID) {
        let cardIndex = indexByID(cardID)
        updateFavicon(favicon, forCardAtIndex: cardIndex)
    }

    func updateFavicon(_ favicon: ImageRef?, forCardAtIndex index: Int) {
        cards[index].favicon = favicon
        cardsChanges.send(.updated(cards[index], atIndex: index))
    }

    func updateThumbnail(_ thumbnail: ImageRef?, forCardByID cardID: Card.ID) {
        let cardIndex = indexByID(cardID)
        updateThumbnail(thumbnail, forCardAtIndex: cardIndex)
    }

    func updateThumbnail(_ thumbnail: ImageRef?, forCardAtIndex index: Int) {
        cards[index].thumbnail = thumbnail
        cardsChanges.send(.updated(cards[index], atIndex: index))
    }

    func updateHidden(_ hidden: Bool, forCardByID cardID: Card.ID) {
        let cardIndex = indexByID(cardID)
        updateHidden(hidden, forCardAtIndex: cardIndex)
    }

    func updateHidden(_ hidden: Bool, forCardAtIndex index: Int) {
        cards[index].hidden = hidden
        cardsChanges.send(.updated(cards[index], atIndex: index))
    }

    func indexByID(_ cardID: Card.ID) -> IdentifiedArrayOf<Card>.Index {
        guard let index = cards.index(id: cardID) else {
            fatalError("Unexpected Card ID")
        }
        return index
    }
}
