import Foundation
import IdentifiedCollections

extension MainViewModel {
    func updateCardGrid(for change: TabsGroupingModel.Change) {
        switch change {
        case let .selected(itemID):
            cardGridViewModel.selectedID = itemID
        case let .appended(item):
            cardGridViewModel.appendCard(.init(from: item))
        case let .inserted(item, atIndex: index):
            cardGridViewModel.insertCard(.init(from: item), atIndex: index)
        case let .removed(_, atIndex: index):
            cardGridViewModel.removeCard(atIndex: index)
        case .removedAll:
            cardGridViewModel.removeAllCards()
        case let .updated(field, atIndex: index):
            switch field {
            case let .tab(tabField):
                switch tabField {
                case let .title(title):
                    cardGridViewModel.update(.title(title), forCardAtIndex: index)
                case let .favicon(favicon):
                    cardGridViewModel.update(.favicon(favicon?.image), forCardAtIndex: index)
                case let .thumbnail(thumbnail):
                    cardGridViewModel.update(.content(.image(thumbnail?.image)), forCardAtIndex: index)
                case .url, .interactionState, .lastAccessedTime:
                    break
                }
            case let .group(group):
                cardGridViewModel.update(.content(.tiled(group.images, overage: group.overage)), forCardAtIndex: index)
            }
        case let .updatedAll(items, selectedItemID):
            cardGridViewModel.replaceAllCards(
                cards(for: items),
                selectedID: selectedItemID
            )
        case let .swapped(atIndex1: index1, atIndex2: index2):
            cardGridViewModel.swapCards(atIndex1: index1, atIndex2: index2)
        }
    }

    func cards(for items: IdentifiedArrayOf<TabsGroupingModel.Item>) -> IdentifiedArrayOf<Card> {
        .init(uniqueElements: items.map { Card(from: $0) })
    }
}
