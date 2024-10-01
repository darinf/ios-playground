import Foundation
import IdentifiedCollections

extension MainViewModel {
    func handle(_ action: CardGridView.Action) {
        switch action {
        case let .removeCard(cardID):
            switch tabsGroupingModel.items[id: cardID]! {
            case let .tab(tab):
                tabsModel.removeTab(byID: tab.id, inSection: currentTabsSection)
            case let .group(group):
                // TODO: Consider adding a bulk remove function on tabsModel to improve performance
                group.tabs.forEach {
                    tabsModel.removeTab(byID: $0.id, inSection: currentTabsSection)
                }
            }
        case let .selectCard(cardID):
            switch tabsGroupingModel.items[id: cardID]! {
            case .tab:
                tabsModel.selectTab(byID: cardID, inSection: currentTabsSection)
                cardGridViewModel.showGrid = false
                updateSelectedTabLastAccessedTime()
            case let .group(group):
                tabsGroupingModel.expandGroup(group)
            }
        case let .movedCard(cardID, toIndex):
            // Apply the change directly to the TabsGroupingModel, and then derive
            // changes to apply to TabsModel from that.

            let fromIndex = tabsGroupingModel.tabsModelIndex(of: cardID)

            tabsGroupingModel.move(cardID, toIndex: toIndex)

            switch tabsGroupingModel.items[id: cardID]! {
            case .tab:
                tabsModel.moveTab(
                    inSection: currentTabsSection,
                    fromIndex: fromIndex,
                    toIndex: tabsGroupingModel.tabsModelIndex(of: toIndex)
                )
            case let .group(group):
                tabsModel.moveTabs(
                    inSection: currentTabsSection,
                    fromIndex: fromIndex,
                    toIndex: tabsGroupingModel.tabsModelIndex(of: toIndex),
                    count: group.tabs.count
                )
            }
        }
    }

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
                case .url, .interactionState, .creationTime, .lastAccessedTime, .accessCount:
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
        case let .moved(itemID, toIndex: index):
            cardGridViewModel.moveCard(itemID, toIndex: index)
        }
    }

    private func cards(for items: IdentifiedArrayOf<TabsGroupingModel.Item>) -> IdentifiedArrayOf<Card> {
        .init(uniqueElements: items.map { Card(from: $0) })
    }
}
