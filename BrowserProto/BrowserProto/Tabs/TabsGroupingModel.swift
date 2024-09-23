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
        case updated(Item.MutableField, ofItem: Item, atIndex: Int)
        case updatedAll(IdentifiedArrayOf<Item>, selectedItemID: Item.ID?)
        case swapped(atIndex1: Int, atIndex2: Int)
    }

    enum Item: Identifiable {
        typealias ID = UUID

        enum MutableField {
            case tab(TabData.MutableField)
            case group(TabsGroup.MutableField)
        }

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

    private var tabToGroupMap: [TabData.ID: TabsGroup.ID] = [:]
}

struct TabsGroup: Identifiable {
    typealias ID = UUID

    enum MutableField {
        case tabs
    }

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
        guard let previousIndex = items.index(id: previousID) else {
            fatalError("Unexpected previousID: does not correspond to an item")
        }
        let index = previousIndex + 1
        items.insert(item, at: index)
        changes.send(.inserted(item, atIndex: index))
    }

    func remove(_ itemID: Item.ID) {
        assert(itemID != selectedItemID) // Should have been updated to nil as a precondition
        if let index = items.index(id: itemID) {
            let item = items.remove(at: index)
            changes.send(.removed(item, atIndex: index))
        } else {
            // Look to see if this refers to a tab that is part of a group.
            guard let groupID = tabToGroupMap[itemID], let item = items[id: groupID], case .group(let group) = item else {
                fatalError("Unexpected itemID: does not map to a group")
            }
            var tabs = group.tabs
            guard tabs.remove(id: itemID) != nil else {
                fatalError("Unexpected itemID: not a tab within a group")
            }
            tabToGroupMap.removeValue(forKey: itemID)
            // XXX flatten a group of one
            let updatedItem: Item = .group(.init(id: group.id, tabs: tabs))
            let index = items.index(id: groupID)!
            items[index] = updatedItem
            changes.send(.updated(.group(.tabs), ofItem: updatedItem, atIndex: index))
        }
    }

    func removeAll() {
        assert(selectedItemID == nil) // Should have been updated to nil as a precondition
        items.removeAll()
        tabToGroupMap.removeAll()
        changes.send(.removedAll)
    }

    func update(_ field: TabData.MutableField, ofTab tabID: TabData.ID) {
        if let index = items.index(id: tabID), case .tab(let tab) = items[index] {
            let updatedItem: Item = .tab(tab.applying(field))
            items[index] = updatedItem
            changes.send(.updated(.tab(field), ofItem: updatedItem, atIndex: index))
        } else {
            // Look to see if this refers to a tab that is part of a group.
            guard let groupID = tabToGroupMap[tabID], let item = items[id: groupID], case .group(let group) = item else {
                fatalError("Unexpected tabID: does not map to a group")
            }
            var tabs = group.tabs
            guard let tab = tabs[id: tabID] else {
                fatalError("Unexpected tabID: not a tab within a group")
            }
            tabs[id: tabID] = tab.applying(field)
            items[id: groupID] = .group(.init(id: group.id, tabs: tabs))
            changes.send(.updated(.group(.tabs), ofItem: item, atIndex: items.index(id: groupID)!))
        }
    }

    func updateAll(_ tabsSectionData: TabsSectionData) {
        (items, tabToGroupMap) = ItemsBuilder(for: tabsSectionData).makeItems()
        selectedItemID = tabsSectionData.selectedTabID
        changes.send(.updatedAll(items, selectedItemID: selectedItemID))
    }

    func swap(_ tabsSectionData: TabsSectionData, atIndex1 index1: Int, atIndex2 index2: Int) {
        let tab1 = tabsSectionData.tabs[index1]
        let tab2 = tabsSectionData.tabs[index2]

        guard let indexOfItem1 = items.index(id: tab1.id), let indexOfItem2 = items.index(id: tab2.id) else {
            fatalError("Unexpected tabs: not found as top level items")
        }

        items.swapAt(indexOfItem1, indexOfItem2)
        changes.send(.swapped(atIndex1: indexOfItem1, atIndex2: indexOfItem2))
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

    func makeItems() -> (items: IdentifiedArrayOf<TabsGroupingModel.Item>, tabToGroupMap: [TabData.ID: TabsGroup.ID]) {
        var items: [TabsGroupingModel.Item] = []
        var group: TabsGroup?
        var tabToGroupMap: [TabData.ID: TabsGroup.ID] = [:]

        func appendGroup(_ group: TabsGroup) {
            // XXX flatten a group of one
            items.append(.group(group))
        }

        for tab in tabsSectionData.tabs {
            if shouldElideTab(tab) {
                if group != nil {
                    group = group!.appending(tab: tab)
                } else {
                    group = .init(id: .init(), tabs: [tab])
                }
                tabToGroupMap[tab.id] = group!.id
            } else {
                if let group {
                    appendGroup(group)
                }
                group = nil
                items.append(.tab(tab))
            }
        }
        if let group {
            appendGroup(group)
        }

        return (items: .init(uniqueElements: items), tabToGroupMap: tabToGroupMap)
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
