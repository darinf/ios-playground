import Combine
import Foundation

final class TabsModel {
    enum TabsChange {
        case appended(TabsSection, Tab)
        case inserted(TabsSection, Tab, atIndex: Int)
        case removed(TabsSection, atIndex: Int)
        case removedAll(TabsSection)
        case updated(TabsSection, Tab, atIndex: Int)
    }

    private(set) var tabs: TabsData = .init()
    let tabsChanges = PassthroughSubject<TabsChange, Never>()

    private(set) var webViewRefs: [WebViewRef.ID: WebViewRef] = [:]
}

enum TabsSection: Hashable, Codable {
    case `default`
    case incognito
}

struct TabsData: Codable {
    var tabs: [TabsSection: [Tab]] = [:]
}

struct Tab: Codable {
    let id: UUID
    var url: URL?

    // TODO: extend data model
}
