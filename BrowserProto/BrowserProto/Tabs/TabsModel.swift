import Combine
import Foundation
import IdentifiedCollections
import UIKit

final class TabsModel {
    enum TabsChange {
        case selected(TabData.ID?)
        case appended(TabData)
        case inserted(TabData, atIndex: Int)
        case removed(atIndex: Int)
        case removedAll
        case updated(TabData.MutableField, atIndex: Int)
    }

    private(set) var data: TabsData = .init()
    let tabsChanges = PassthroughSubject<(TabsSection, TabsChange), Never>()

    private(set) var liveWebContent: [WebContent.ID: WebContent] = [:]
}

extension TabsModel {
    func selectTab(byID tabID: TabData.ID?, inSection section: TabsSection) {
        data.sections[id: section]!.selectedTab = tabID
        tabsChanges.send((section, .selected(tabID)))
    }

    func appendTab(_ tab: TabData, inSection section: TabsSection) {
        data.sections[id: section]!.tabs.append(tab)
        tabsChanges.send((section, .appended(tab)))
    }

    func insertTab(_ tab: TabData, inSection section: TabsSection, after previousID: TabData.ID) {
        let insertionIndex = indexByID(previousID, inSection: section) + 1
        data.sections[id: section]!.tabs.insert(tab, at: insertionIndex)
        tabsChanges.send((section, .inserted(tab, atIndex: insertionIndex)))
    }

    func removeTab(byID tabID: TabData.ID, inSection section: TabsSection) {
        let removalIndex = indexByID(tabID, inSection: section)
        data.sections[id: section]!.tabs.remove(at: removalIndex)
        tabsChanges.send((section, .removed(atIndex: removalIndex)))
    }

    func removeAllTabs(inSection section: TabsSection) {
        data.sections[id: section]!.tabs = []
        tabsChanges.send((section, .removedAll))
    }

    func updateURL(_ url: URL?, forTabByID tabID: TabData.ID, inSection section: TabsSection) {
        let tabIndex = indexByID(tabID, inSection: section)
        data.sections[id: section]!.tabs[tabIndex].url = url
        tabsChanges.send((section, .updated(.url(url), atIndex: tabIndex)))
    }

    func updateTitle(_ title: String?, forTabByID tabID: TabData.ID, inSection section: TabsSection) {
        let tabIndex = indexByID(tabID, inSection: section)
        data.sections[id: section]!.tabs[tabIndex].title = title
        tabsChanges.send((section, .updated(.title(title), atIndex: tabIndex)))
    }

    func updateFavicon(_ favicon: Favicon?, forTabByID tabID: TabData.ID, inSection section: TabsSection) {
        let tabIndex = indexByID(tabID, inSection: section)
        data.sections[id: section]!.tabs[tabIndex].favicon = favicon
        tabsChanges.send((section, .updated(.favicon(favicon), atIndex: tabIndex)))
    }

    func updateThumbnail(_ thumbnail: Thumbnail?, forTabByID tabID: TabData.ID, inSection section: TabsSection) {
        let tabIndex = indexByID(tabID, inSection: section)
        data.sections[id: section]!.tabs[tabIndex].thumbnail = thumbnail
        tabsChanges.send((section, .updated(.thumbnail(thumbnail), atIndex: tabIndex)))
    }

    func tabByID(_ tabID: TabData.ID, inSection section: TabsSection) -> TabData {
        data.sections[id: section]!.tabs[id: tabID]!
    }

    func tabByIndex(_ index: Int, inSection section: TabsSection) -> TabData {
        data.sections[id: section]!.tabs[index]
    }

    func indexByID(_ tabID: TabData.ID, inSection section: TabsSection) -> IdentifiedArrayOf<TabData>.Index {
        let section = data.sections[id: section]!
        return section.tabs.index(id: tabID)!
    }
}
