import Combine
import Foundation
import IdentifiedCollections

final class TabsGroupingModel {
    enum Change {
        case selected(TabData.ID?) // Only tabs can be selected
        case appended(Item)
        case inserted(Item, atIndex: Int)
        case removed(Item, atIndex: Int)
        case removedAll
        case updated(Item, atIndex: Int)
        case updatedAll
        case swapped(atIndex1: Int, atIndex2: Int)
    }

    enum Item {
        case tab(TabData)
        case group(TabsGroup)
    }

    private(set) var items: [Item] = []
}

struct TabsGroup: Identifiable {
    typealias ID = UUID

    let id: ID
    let tabs: [TabData]
}

