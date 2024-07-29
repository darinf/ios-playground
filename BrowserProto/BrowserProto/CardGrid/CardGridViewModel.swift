import Combine
import Foundation
import IdentifiedCollections
import UIKit

struct Card: Identifiable {
    typealias ID = UUID

    let id: ID
    var thumbnail: UIImage?
}

final class CardGridViewModel {
    enum CardsChange {
        case appended(Card)
        case inserted(Card, atIndex: Int)
        case removed(atIndex: Int)
        case removedAll
        case updated(Card, atIndex: Int)
    }

    @Published var showGrid = false
    @Published var selectedID: Card.ID?
    
    private(set) var cards: IdentifiedArrayOf<Card> = []
    let cardsChanges = PassthroughSubject<CardsChange, Never>()

    func containsCard(byID cardID: Card.ID) -> Bool {
        cards[id: cardID] != nil
    }

    func appendCard(_ card: Card) {
        cards.append(card)
        cardsChanges.send(.appended(card))
    }

    func insertCard(_ card: Card, after previousID: Card.ID) {
        let insertionIndex = indexByID(previousID) + 1
        cards.insert(card, at: insertionIndex)
        cardsChanges.send(.inserted(card, atIndex: insertionIndex))
    }

    func removeCard(byID cardID: Card.ID) {
        let removalIndex = indexByID(cardID)
        cards.remove(at: removalIndex)
        cardsChanges.send(.removed(atIndex: removalIndex))
        if selectedID == cardID {
            selectedID = nil
        }
    }

    func removeAllCards() {
        cards = []
        cardsChanges.send(.removedAll)
        selectedID = nil
    }

    func updateThumbnail(_ thumbnail: UIImage?, forCardByID cardID: Card.ID) {
        let cardIndex = indexByID(cardID)
        cards[cardIndex].thumbnail = thumbnail
        cardsChanges.send(.updated(cards[cardIndex], atIndex: cardIndex))
    }

    func indexByID(_ cardID: Card.ID) -> IdentifiedArrayOf<Card>.Index {
        guard let index = cards.index(id: cardID) else {
            fatalError("Unexpected Card ID")
        }
        return index
    }
}
