import Foundation
import IdentifiedCollections

struct TabsData: Codable {
    var sections: IdentifiedArrayOf<TabsSectionData> = []
}

enum TabsSection: Hashable, Codable {
    case `default`
    case nonPersistent
    case custom(UUID)
}

struct TabsSectionData: Identifiable, Codable {
    typealias ID = TabsSection
    
    let id: TabsSection
    var tabs: IdentifiedArrayOf<TabData> = []
}

struct TabData: Identifiable, Codable {
    typealias ID = UUID

    enum MutableField {
        case url(URL?)
        case title(String?)
        case faviconURL(URL?)
    }

    let id: ID
    var url: URL?
    var title: String?
    var faviconURL: URL?

    // TODO: extend data model
}
