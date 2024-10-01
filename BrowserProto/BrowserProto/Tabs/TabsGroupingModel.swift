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
        case updated(Item.MutableField, atIndex: Int)
        case updatedAll(IdentifiedArrayOf<Item>, selectedItemID: Item.ID?)
        case moved(Item.ID, toIndex: Int)
    }

    enum Item: Identifiable, Equatable {
        typealias ID = UUID

        enum MutableField {
            case tab(TabData.MutableField)
            case group(TabsGroup)
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

        static func == (lhs: TabsGroupingModel.Item, rhs: TabsGroupingModel.Item) -> Bool {
            lhs.id == rhs.id
        }
    }

    private(set) var items: IdentifiedArrayOf<Item> = []
    private(set) var selectedItemID: Item.ID?
    let changes = PassthroughSubject<Change, Never>()

    private var tabToGroupMap: [TabData.ID: TabsGroup.ID] = [:]
}

struct TabsGroup: Identifiable {
    typealias ID = UUID

    let id: ID
    let tabs: IdentifiedArrayOf<TabData>
}

extension TabsGroupingModel {
    func apply(_ change: TabsModel.DataChange) {
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
        case .moved, .movedSubrange:
            break // Ignored
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
            if case .group(let group) = item {
                group.tabs.forEach {
                    tabToGroupMap.removeValue(forKey: $0.id)
                }
            }
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
            let updatedGroup = TabsGroup(id: group.id, tabs: tabs)
            let index = items.index(id: groupID)!
            items[index] = .group(updatedGroup)
            changes.send(.updated(.group(updatedGroup), atIndex: index))
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
            items[index] = .tab(tab.applying(field))
            changes.send(.updated(.tab(field), atIndex: index))
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
            let updatedGroup = TabsGroup(id: group.id, tabs: tabs)
            items[id: groupID] = .group(updatedGroup)
            changes.send(.updated(.group(updatedGroup), atIndex: items.index(id: groupID)!))
        }
    }

    func updateAll(_ tabsSectionData: TabsSectionData) {
        (items, tabToGroupMap) = ItemsBuilder(for: tabsSectionData).makeItems()
        selectedItemID = tabsSectionData.selectedTabID
        changes.send(.updatedAll(items, selectedItemID: selectedItemID))
    }

    func updateAllIfChanged(tabsSectionData: TabsSectionData) {
        let (items, tabToGroupMap) = ItemsBuilder(for: tabsSectionData).makeItems()
        guard self.items != items || selectedItemID != tabsSectionData.selectedTabID else { return }
        self.items = items
        self.tabToGroupMap = tabToGroupMap
        selectedItemID = tabsSectionData.selectedTabID
        changes.send(.updatedAll(items, selectedItemID: selectedItemID))
    }

    func move(_ itemID: Item.ID, toIndex index: Int) {
        print(">>> move \(itemID) to: \(index)")
        let itemIndex = items.index(id: itemID)!
        items.move(fromOffset: itemIndex, toOffset: index)
        changes.send(.moved(itemID, toIndex: index))
    }

    func expandGroup(_ group: TabsGroup) {
        let index = items.index(id: group.id)!

        var tabsToKeep = group.tabs
        var tabsToExtract: [TabData] = []
        for _ in 0..<min(group.tabs.count, 4) {
            tabsToExtract.append(tabsToKeep.removeLast()) // Reverses order
        }

        var insertionIndex: Int

        // Update group item
        if tabsToKeep.isEmpty {
            insertionIndex = index
            items.remove(at: index)
            changes.send(.removed(.group(group), atIndex: index))
        } else {
            insertionIndex = index + 1
            let updatedGroup = TabsGroup(id: group.id, tabs: tabsToKeep)
            items[id: group.id] = .group(updatedGroup)
            tabsToExtract.forEach {
                tabToGroupMap.removeValue(forKey: $0.id)
            }
            changes.send(.updated(.group(updatedGroup), atIndex: index))
        }

        // Now insert the tabsToExtract
        for tab in tabsToExtract {
            items.insert(.tab(tab), at: insertionIndex) // Reverses order
            changes.send(.inserted(.tab(tab), atIndex: insertionIndex))
        }
    }

    func tabsModelIndex(of itemID: Item.ID) -> Int {
        tabsModelIndex(of: items.index(id: itemID)!)
    }

    // Returns the index of the first tab in the group if the specified item is a group.
    func tabsModelIndex(of itemIndex: Int) -> Int {
        let targetItem = items[itemIndex]

        var result = 0
        for item in items {
            if item.id == targetItem.id {
                break
            }
            switch item {
            case .tab:
                result += 1
            case let .group(group):
                result += group.tabs.count
            }
        }

        return result
    }
}

private final class ItemsBuilder {
    enum Metrics {
        static let daysThreshold = 3.0
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
            // Flatten a group of one
            if group.tabs.count == 1 {
                items.append(.tab(group.tabs[0]))
            } else {
                items.append(.group(group))
                group.tabs.forEach {
                    tabToGroupMap[$0.id] = group.id
                }
            }
        }

        for tab in tabsSectionData.tabs {
            if tab.id != tabsSectionData.selectedTabID, shouldElideTab(tab) {
                if group != nil {
                    group = group!.appending(tab: tab)
                } else {
                    group = .init(id: .init(), tabs: [tab])
                }
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
