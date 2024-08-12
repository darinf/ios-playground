import Foundation
import IdentifiedCollections

struct TabsData {
    var sections: IdentifiedArrayOf<TabsSectionData> = [
        .init(id: .default),
        .init(id: .incognito)
    ]
}

enum TabsSection: Hashable {
    case `default`
    case incognito
    case custom(UUID)
}

struct TabsSectionData: Identifiable {
    typealias ID = TabsSection

    let id: TabsSection
    var selectedTab: TabData.ID?
    var tabs: IdentifiedArrayOf<TabData> = []
}

struct TabData: Identifiable {
    typealias ID = WebContent.ID

    enum MutableField {
        case url(URL?)
        case title(String?)
        case favicon(Favicon?)
        case thumbnail(Thumbnail?)
    }

    let id: ID
    var url: URL?
    var title: String?
    var favicon: Favicon?
    var thumbnail: Thumbnail?

    // TODO: extend data model
}
