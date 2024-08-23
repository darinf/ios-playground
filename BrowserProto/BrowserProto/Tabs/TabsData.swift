import Foundation
import IdentifiedCollections

struct TabsData: Codable {
    var sections: IdentifiedArrayOf<TabsSectionData> = [
        .init(id: .default),
        .init(id: .incognito)
    ]
}

enum TabsSection: Hashable, Codable {
    case `default`
    case incognito
    case custom(UUID)
}

struct TabsSectionData: Identifiable, Codable {
    typealias ID = TabsSection

    let id: TabsSection
    var selectedTabID: TabData.ID?
    var tabs: IdentifiedArrayOf<TabData> = []
}

struct TabData: Identifiable, Codable {
    typealias ID = WebContent.ID

    enum MutableField {
        case url(URL?)
        case title(String?)
        case favicon(Favicon?)
        case thumbnail(Thumbnail?)
        case interactionState(Data?)
    }

    let id: ID
    var url: URL?
    var title: String?
    var favicon: Favicon?
    var thumbnail: Thumbnail?
    var interactionState: Data?

    // TODO: extend data model
}
