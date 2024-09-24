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
        case moved(Card.ID, toIndex: Int)
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

    func moveCard(_ cardID: Card.ID, toIndex: Int) {
        let cardIndex = cards.index(id: cardID)!
        cards.move(fromOffset: cardIndex, toOffset: toIndex)
        cardsChanges.send(.moved(cardID, toIndex: toIndex))
    }

    func update(_ field: Card.MutableField, forCardByID cardID: Card.ID) {
        let cardIndex = indexByID(cardID)
        update(field, forCardAtIndex: cardIndex)
    }

    func update(_ field: Card.MutableField, forCardAtIndex index: Int) {
        switch field {
        case let .title(title):
            cards[index].title = title
        case let .favicon(favicon):
            cards[index].favicon = favicon
        case let .content(content):
            cards[index].content = content
        case let .hidden(hidden):
            cards[index].hidden = hidden
        }
        cardsChanges.send(.updated(cards[index], atIndex: index))
    }

    func indexByID(_ cardID: Card.ID) -> IdentifiedArrayOf<Card>.Index {
        guard let index = cards.index(id: cardID) else {
            fatalError("Unexpected Card ID")
        }
        return index
    }

    func indexByIDOrNil(_ cardID: Card.ID) -> IdentifiedArrayOf<Card>.Index? {
        cards.index(id: cardID)
    }
}
