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
        case creationTime(Date?)
        case lastAccessedTime(Date?)
        case accessCount(Int?)
    }

    let id: ID
    var url: URL?
    var title: String?
    var favicon: Favicon?
    var thumbnail: Thumbnail?
    var interactionState: Data?
    var creationTime: Date?
    var lastAccessedTime: Date?
    var accessCount: Int?

    // TODO: extend data model
}

extension TabData {
    mutating func apply(_ field: MutableField) {
        switch field {
        case let .url(url):
            self.url = url
        case let .title(title):
            self.title = title
        case let .favicon(favicon):
            self.favicon = favicon
        case let .thumbnail(thumbnail):
            self.thumbnail = thumbnail
        case let .interactionState(interactionState):
            self.interactionState = interactionState
        case let .creationTime(creationTime):
            self.creationTime = creationTime
        case let .lastAccessedTime(lastAccessedTime):
            self.lastAccessedTime = lastAccessedTime
        case let .accessCount(accessCount):
            self.accessCount = accessCount
        }
    }

    func applying(_ field: MutableField) -> TabData {
        var copy = self
        copy.apply(field)
        return copy
    }
}
