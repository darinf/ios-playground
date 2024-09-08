import Combine
import Foundation
import IdentifiedCollections

final class MainViewModel {
    let urlInputViewModel = URLInputViewModel()
    let bottomBarViewModel = BottomBarViewModel()
    let webContentViewModel = WebContentViewModel()
    let cardGridViewModel = CardGridViewModel()
    let tabsModel = TabsModel()
    let tabsStorage = TabsStorage()
    let webContentCache = WebContentCache()

    @Published var suppressInteraction: Bool = false
}

extension MainViewModel {
    var currentTabsSection: TabsSection {
        webContentViewModel.incognito ? .incognito : .default
    }

    func setIncognito(incognito: Bool) {
        webContentViewModel.incognito = incognito

        var cards = IdentifiedArrayOf<Card>()
        tabsModel.data.sections[id: currentTabsSection]!.tabs.forEach { tab in
            cards.append(.init(from: tab))
        }
        let selectedID = tabsModel.data.sections[id: currentTabsSection]!.selectedTabID
        cardGridViewModel.replaceAllCards(cards, selectedID: selectedID)
        if cards.isEmpty {
            cardGridViewModel.showGrid = true
        }
    }

    func updateCardGrid(for change: TabsModel.TabsChange, in section: TabsSection) {
        guard currentTabsSection == section else { return }
        switch change {
        case let .selected(tabID):
            cardGridViewModel.selectedID = tabID
        case let .appended(tab):
            cardGridViewModel.appendCard(.init(from: tab))
        case let .inserted(tab, atIndex: index):
            cardGridViewModel.insertCard(.init(from: tab), atIndex: index)
        case let .removed(atIndex: index):
            cardGridViewModel.removeCard(atIndex: index)
        case .removedAll:
            cardGridViewModel.removeAllCards()
        case let .updated(field, atIndex: index):
            switch field {
            case let .title(title):
                cardGridViewModel.updateTitle(title, forCardAtIndex: index)
            case let .favicon(favicon):
                cardGridViewModel.updateFavicon(favicon?.image, forCardAtIndex: index)
            case let .thumbnail(thumbnail):
                cardGridViewModel.updateThumbnail(thumbnail?.image, forCardAtIndex: index)
            case .url, .interactionState, .lastAccessedTime:
                break
            }
        case let .updatedAll(tabsSectionData):
            cardGridViewModel.replaceAllCards(
                .init(uniqueElements: tabsSectionData.tabs.map { Card(from: $0) }),
                selectedID: tabsSectionData.selectedTabID
            )
        case let .swapped(atIndex1: index1, atIndex2: index2):
            cardGridViewModel.swapCards(atIndex1: index1, atIndex2: index2)
        }
    }

    func updateTabs(for change: WebContentViewModel.WebContentChange) {
        let currentWebContent = webContentViewModel.webContent
        switch change {
        case .opened:
            let newTab = TabData(from: currentWebContent!)
            if let opener = currentWebContent!.opener {
                tabsModel.insertTab(newTab, inSection: currentTabsSection, after: opener.id)
            } else {
                tabsModel.appendTab(newTab, inSection: currentTabsSection)
            }
            currentWebContent.map { webContentCache.insert($0) }
        case .switched:
            currentWebContent.map { webContentCache.insert($0) }
        case let .poppedBack(from: closedWebContent):
            tabsModel.selectTab(byID: currentWebContent?.id, inSection: currentTabsSection)
            tabsModel.removeTab(byID: closedWebContent.id, inSection: currentTabsSection)
            webContentCache.remove(closedWebContent)
            // TODO: If currentWebContent is nil, then we need to select a different card.
        }
        tabsModel.selectTab(byID: currentWebContent?.id, inSection: currentTabsSection)
    }

    func updateSelectedTabLastAccessedTime() {
        guard let tabID = tabsModel.selectedTabID(inSection: currentTabsSection) else { return }
        tabsModel.update(.lastAccessedTime(.now), forTabByID: tabID, inSection: currentTabsSection)
    }

    func updateSelectedTabThumbnailIfShowing(completion: @escaping () -> Void) {
        if !cardGridViewModel.showGrid, let webContent = webContentViewModel.webContent {
            suppressInteraction = true
            // updateThumbnail could be blocked on a network load of the initial page. In that
            // case, we need to timeout.
            var timedOut = false
            var completed = false
            webContent.updateThumbnail { [self] in
                guard !timedOut else { return }
                suppressInteraction = false
                completed = true
                completion()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) { [self] in
                guard !completed else { return }
                timedOut = true
                suppressInteraction = false
                completion()
            }
        } else {
            Task { @MainActor in
                completion()
            }
        }
    }

    func validateOpener() {
        if let opener = webContentViewModel.webContent?.opener,
           !tabsModel.tabExists(byID: opener.id, inSection: currentTabsSection) {
            webContentViewModel.webContent?.dropOpener()
        }
    }
}

extension Card {
    init(from tab: TabData) {
        self.init(
            id: tab.id,
            title: tab.title,
            favicon: tab.favicon?.image,
            thumbnail: tab.thumbnail?.image
        )
    }
}

extension TabData {
    init(from webContent: WebContent) {
        self.init(
            id: webContent.id,
            url: webContent.url,
            title: webContent.title,
            favicon: webContent.favicon,
            thumbnail: webContent.thumbnail
        )
    }
}
