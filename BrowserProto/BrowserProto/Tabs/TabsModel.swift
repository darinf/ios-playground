import Combine
import Foundation
import IdentifiedCollections
import UIKit

final class TabsModel {
    enum Change {
        case selected(TabData.ID?)
        case appended(TabData)
        case inserted(TabData, atIndex: Int, after: TabData.ID)
        case removed(TabData.ID, atIndex: Int)
        case removedAll
        case updated(TabData.MutableField, ofTab: TabData.ID, atIndex: Int)
        case updatedAll(TabsSectionData)
        case swapped(TabsSectionData, atIndex1: Int, atIndex2: Int)
    }

    private(set) var data: TabsData = .init()
    let changes = PassthroughSubject<(TabsSection, Change), Never>()
}

extension TabsModel {
    func selectedTabID(inSection section: TabsSection) -> TabData.ID? {
        data.sections[id: section]!.selectedTabID
    }

    func selectTab(byID tabID: TabData.ID?, inSection section: TabsSection) {
        guard data.sections[id: section]!.selectedTabID != tabID else { return }
        data.sections[id: section]!.selectedTabID = tabID
        changes.send((section, .selected(tabID)))
    }

    func appendTab(_ tab: TabData, inSection section: TabsSection) {
        data.sections[id: section]!.tabs.append(tab)
        changes.send((section, .appended(tab)))
    }

    func insertTab(_ tab: TabData, inSection section: TabsSection, after previousID: TabData.ID) {
        let insertionIndex = indexByID(previousID, inSection: section) + 1
        data.sections[id: section]!.tabs.insert(tab, at: insertionIndex)
        changes.send((section, .inserted(tab, atIndex: insertionIndex, after: previousID)))
    }

    func removeTab(byID tabID: TabData.ID, inSection section: TabsSection) {
        var sectionData = data.sections[id: section]!

        var notifyNilSelectedTab = false
        if sectionData.selectedTabID == tabID {
            sectionData.selectedTabID = nil
            notifyNilSelectedTab = true // Defer until model is actually updated.
        }

        let removalIndex = indexByID(tabID, inSection: section)
        sectionData.tabs.remove(at: removalIndex)

        data.sections[id: section] = sectionData

        if notifyNilSelectedTab {
            changes.send((section, .selected(nil)))
        }
        changes.send((section, .removed(tabID, atIndex: removalIndex)))
    }

    func removeAllTabs(inSection section: TabsSection) {
        var sectionData = data.sections[id: section]!

        var notifyNilSelectedTab = false
        if sectionData.selectedTabID != nil {
            sectionData.selectedTabID = nil
            notifyNilSelectedTab = true // Defer until model is actually updated.
        }

        data.sections[id: section]!.tabs = []

        if notifyNilSelectedTab {
            changes.send((section, .selected(nil)))
        }
        changes.send((section, .removedAll))
    }

    func replaceAllTabsData(_ data: TabsData) {
        self.data = data
        data.sections.forEach {
            changes.send(($0.id, .updatedAll($0)))
        }
    }

    func swapTabs(inSection section: TabsSection, atIndex1 index1: Int, atIndex2 index2: Int) {
        data.sections[id: section]!.tabs.swapAt(index1, index2)
        changes.send((section, .swapped(data.sections[id: section]!, atIndex1: index1, atIndex2: index2)))
    }

    func update(_ field: TabData.MutableField, forTabByID tabID: TabData.ID, inSection section: TabsSection) {
        let tabIndex = indexByID(tabID, inSection: section)
        data.sections[id: section]!.tabs[tabIndex].update(field)
        changes.send((section, .updated(field, ofTab: tabID, atIndex: tabIndex)))
    }

    func indexByID(_ tabID: TabData.ID, inSection section: TabsSection) -> IdentifiedArrayOf<TabData>.Index {
        let section = data.sections[id: section]!
        return section.tabs.index(id: tabID)!
    }

    func tabExists(byID tabID: TabData.ID, inSection section: TabsSection) -> Bool {
        data.sections[id: section]!.tabs[id: tabID] != nil
    }

    func webContent(for tabID: TabData.ID, inSection section: TabsSection) -> WebContent? {
        if let webContent = WebContent.from(id: tabID) {
            return webContent
        }

        let tabData = data.sections[id: section]!.tabs[id: tabID]!

        // Restore the WebContent
        let webContent = WebContent(
            forIncognito: section == .incognito,
            withID: tabID,
            withFavicon: tabData.favicon,
            withThumbnail: tabData.thumbnail,
            withInteractionState: tabData.interactionState
        )
        if let url = tabData.url {
            // TODO: should use `interactionState` here.
            webContent.webView.load(.init(url: url))
        }
        return webContent
    }
}

extension TabData {
    mutating func update(_ field: MutableField) {
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
        case let .lastAccessedTime(lastAccessedTime):
            self.lastAccessedTime = lastAccessedTime
        }
    }
}
