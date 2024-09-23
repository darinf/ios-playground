import Combine
import Foundation
import IdentifiedCollections

final class TabsGroupingModel {
    enum Change {
        case selected(Item.ID?)
        case appended(Item)
        case inserted(Item, atIndex: Int)
        case removed(Item, atIndex: Int)
        case removedAll
        case updated(Item, atIndex: Int)
        case updatedAll
        case swapped(atIndex1: Int, atIndex2: Int)
    }

    enum Item: Identifiable {
        typealias ID = UUID

        case tab(TabData)
        case group(TabsGroup)

        var id: ID {
            switch self {
            case .tab(let tab):
                return tab.id
            case .group(let group):
                return group.id
            }
        }
    }

    private(set) var items: IdentifiedArrayOf<Item> = []
    private(set) var selectedItemID: Item.ID?

    let changes = PassthroughSubject<Change, Never>()
}

struct TabsGroup: Identifiable {
    typealias ID = UUID

    let id: ID
    let tabs: IdentifiedArrayOf<TabData>
}

extension TabsGroupingModel {
    func apply(_ change: TabsModel.Change) {
        switch change {
        case let .selected(tabID):
            select(tabID)
        case let .appended(tab):
            append(.tab(tab))
        case let .inserted(tab, atIndex: _, after: previousID):
            insert(.tab(tab), after: previousID)
        case let .removed(tabID, atIndex: _):
            remove(tabID)
        case .removedAll:
            removeAll()
        case let .updated(field, ofTab: tabID, atIndex: _):
            update(field, ofTab: tabID)
        case let .updatedAll(tabsSectionData):
            updateAll(tabsSectionData)
        case let .swapped(tabsSectionData, atIndex1: index1, atIndex2: index2):
            swap(tabsSectionData, atIndex1: index1, atIndex2: index2)
        }
    }

    func select(_ itemID: Item.ID?) {
        selectedItemID = itemID
        changes.send(.selected(itemID))
    }

    func append(_ item: Item) {
        items.append(item)
        changes.send(.appended(item))
    }

    func insert(_ item: Item, after previousID: TabData.ID) {
        let index = items.index(id: previousID)! + 1
        items.insert(item, at: index)
        changes.send(.inserted(item, atIndex: index))
    }

    func remove(_ itemID: Item.ID) {
        assert(itemID != selectedItemID)
        let index = items.index(id: itemID)!
        let item = items.remove(at: index)
        changes.send(.removed(item, atIndex: index))
    }

    func removeAll() {
        assert(selectedItemID == nil)
        items.removeAll()
        changes.send(.removedAll)
    }

    func update(_ field: TabData.MutableField, ofTab tabID: TabData.ID) {
        // XXX
    }

    func updateAll(_ tabsSectionData: TabsSectionData) {
        items = ItemsBuilder(for: tabsSectionData).makeItems()
        selectedItemID = tabsSectionData.selectedTabID
        changes.send(.updatedAll)
    }

    func swap(_ tabsSectionData: TabsSectionData, atIndex1 index1: Int, atIndex2 index2: Int) {
        // XXX
    }
}

private final class ItemsBuilder {
    enum Metrics {
        static let daysThreshold = 5.0
    }

    private let tabsSectionData: TabsSectionData

    init(for tabsSectionData: TabsSectionData) {
        self.tabsSectionData = tabsSectionData
    }

    func makeItems() -> IdentifiedArrayOf<TabsGroupingModel.Item> {
        var items: [TabsGroupingModel.Item] = []
        var group: TabsGroup?

        func appendGroup(_ group: TabsGroup) {
            items.append(.group(group))
        }

        for tab in tabsSectionData.tabs {
            if shouldElideTab(tab) {
                if group != nil {
                    group = group!.appending(tab: tab)
                } else {
                    group = .init(id: .init(), tabs: [tab])
                }
            } else {
                if let group {
                    appendGroup(group)
                } else {
                    items.append(.tab(tab))
                }
                group = nil
            }
        }
        if let group {
            appendGroup(group)
        }

        return .init(uniqueElements: items)
    }

    private func shouldElideTab(_ tab: TabData) -> Bool {
        guard let lastAccessTime = tab.lastAccessedTime else { return true }

        let now = Date.now
        let deltaSeconds = now.distance(to: lastAccessTime)
        let deltaDays = deltaSeconds / 60 / 60 / 24

        return deltaDays < -Metrics.daysThreshold
    }
}

extension TabsGroup {
    func appending(tab: TabData) -> TabsGroup {
        .init(id: id, tabs: tabs + [tab])
    }
}
