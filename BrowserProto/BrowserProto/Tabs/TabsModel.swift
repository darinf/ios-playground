import Combine
import Foundation
import IdentifiedCollections
import UIKit

final class TabsModel {
    enum TabsChange {
        case appended(TabData, inSection: TabsSection)
        case inserted(TabData, atIndex: Int, inSection: TabsSection)
        case removed(atIndex: Int, inSection: TabsSection)
        case removedAll(inSection: TabsSection)
        case updated(TabData.MutableField, atIndex: Int, inSection: TabsSection)
    }

    private(set) var data: TabsData = .init()
    let tabsChanges = PassthroughSubject<TabsChange, Never>()

    private(set) var liveWebContent: [WebContent.ID: WebContent] = [:]
}

extension TabsModel {
    func appendTab(_ tab: TabData, inSection section: TabsSection) {
        data.sections[id: section]!.tabs.append(tab)
        tabsChanges.send(.appended(tab, inSection: section))
    }

    func insertTab(_ tab: TabData, inSection section: TabsSection, after previousID: TabData.ID) {
        let insertionIndex = indexByID(previousID, inSection: section) + 1
        data.sections[id: section]!.tabs.insert(tab, at: insertionIndex)
        tabsChanges.send(.inserted(tab, atIndex: insertionIndex, inSection: section))
    }

    func removeTab(byID tabID: TabData.ID, inSection section: TabsSection) {
        let removalIndex = indexByID(tabID, inSection: section)
        data.sections[id: section]!.tabs.remove(at: removalIndex)
        tabsChanges.send(.removed(atIndex: removalIndex, inSection: section))
    }

    func removeAllTabs(inSection section: TabsSection) {
        data.sections[id: section]!.tabs = []
        tabsChanges.send(.removedAll(inSection: section))
    }

    func updateURL(_ url: URL?, forTabByID tabID: TabData.ID, inSection section: TabsSection) {
        let tabIndex = indexByID(tabID, inSection: section)
        data.sections[id: section]!.tabs[tabIndex].url = url
        tabsChanges.send(.updated(.url(url), atIndex: tabIndex, inSection: section))
    }

    func updateTitle(_ title: String?, forTabByID tabID: TabData.ID, inSection section: TabsSection) {
        let tabIndex = indexByID(tabID, inSection: section)
        data.sections[id: section]!.tabs[tabIndex].title = title
        tabsChanges.send(.updated(.title(title), atIndex: tabIndex, inSection: section))
    }

    func updateFaviconURL(_ faviconURL: URL?, forTabByID tabID: TabData.ID, inSection section: TabsSection) {
        let tabIndex = indexByID(tabID, inSection: section)
        data.sections[id: section]!.tabs[tabIndex].faviconURL = faviconURL
        tabsChanges.send(.updated(.faviconURL(faviconURL), atIndex: tabIndex, inSection: section))
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
