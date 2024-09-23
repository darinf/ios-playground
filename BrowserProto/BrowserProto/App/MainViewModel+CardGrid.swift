import Foundation
import IdentifiedCollections

extension MainViewModel {
    func updateCardGrid(for change: TabsModel.Change, in section: TabsSection) {
        guard currentTabsSection == section else { return }
        switch change {
        case let .selected(tabID):
            // XXX make sure this tabID exists, split up tiled cards
            cardGridViewModel.selectedID = tabID
        case let .appended(tab):
            cardGridViewModel.appendCard(.init(from: tab))
        case let .inserted(tab, atIndex: index, after: _):
            // XXX need to map index
            cardGridViewModel.insertCard(.init(from: tab), atIndex: index)
        case let .removed(tabID, atIndex: _):
            guard let index = cardIndex(forTabByID: tabID) else {
                // XXX need to update tiled card
                return
            }
            cardGridViewModel.removeCard(atIndex: index)
        case .removedAll:
            cardGridViewModel.removeAllCards()
        case let .updated(field, ofTab: tabID, atIndex: _):
            guard let index = cardIndex(forTabByID: tabID) else {
                // XXX need to update tiled card
                return
            }
            switch field {
            case let .title(title):
                cardGridViewModel.update(.title(title), forCardAtIndex: index)
            case let .favicon(favicon):
                cardGridViewModel.update(.favicon(favicon?.image), forCardAtIndex: index)
            case let .thumbnail(thumbnail):
                cardGridViewModel.update(.content(.image(thumbnail?.image)), forCardAtIndex: index)
            case .url, .interactionState, .lastAccessedTime:
                break
            }
        case let .updatedAll(tabsSectionData):
            cardGridViewModel.replaceAllCards(
                cards(for: tabsSectionData),
                selectedID: tabsSectionData.selectedTabID
            )
        case let .swapped(_, atIndex1: index1, atIndex2: index2):
            // XXX
            cardGridViewModel.swapCards(atIndex1: index1, atIndex2: index2)
        }
    }

    func cardIndex(forTabByID tabID: TabData.ID) -> Int? {
        cardGridViewModel.indexByIDOrNil(tabID)
    }

    func cardIndex(forTabAtIndex tabIndex: Int) -> Int? {

        tabIndex // XXX
    }

    // TODO refactor into a helper class
    func cards(for tabsSectionData: TabsSectionData) -> IdentifiedArrayOf<Card> {
        var cards: [Card] = []

        struct Group {
            var id: Card.ID
            var images: [ImageRef?] = []
            var overage: Int = 0
        }
        var group: Group?

        func addGroup(_ group: Group) {
            cards.append(.init(
                id: group.id,
                title: "Archived",
                favicon: .init(image: .init(systemName: "square.grid.2x2.fill")),
                content: .tiled(group.images, overage: group.overage),
                hidden: false
            ))
        }

        for tab in tabsSectionData.tabs {
            if shouldElideTab(tab) {
                if group == nil {
                    group = .init(id: tab.id)
                }
                if group!.images.count < 3 {
                    group!.images.append(tab.thumbnail?.image)
                } else {
                    group!.overage += 1
                }
            } else {
                if let group {
                    addGroup(group)
                } else {
                    cards.append(.init(from: tab))
                }
                group = nil
            }
        }
        if let group {
            addGroup(group)
        }

        return .init(uniqueElements: cards)
    }

    func shouldElideTab(_ tab: TabData) -> Bool {
        guard let lastAccessTime = tab.lastAccessedTime else { return true }

        let now = Date.now
        let deltaSeconds = now.distance(to: lastAccessTime)
        let deltaDays = deltaSeconds / 60 / 60 / 24

        return deltaDays < -5
    }
}
