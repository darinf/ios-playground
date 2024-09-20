import Combine
import Foundation
import IdentifiedCollections

final class TabsGroupingModel {
//    enum TabsEntryChange {
//        
//    }
//
//    struct TabsEntry: Identifiable {
//        let tabData: TabData
//        let groupID: UUID?
//
//        var id: TabData.ID {
//            tabData.id
//        }
//    }
//
//    private(set) var data: IdentifiedArrayOf<TabsEntry> = []
//    let dataChanges = PassthroughSubject<DataChange, Never>()


    typealias GroupID = UUID

    private(set) var map: [TabData.ID: GroupID] = [:]
}
