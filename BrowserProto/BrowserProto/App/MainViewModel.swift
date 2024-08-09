import Combine
import Foundation
import IdentifiedCollections

final class MainViewModel {
    let urlInputViewModel = URLInputViewModel()
    let bottomBarViewModel = BottomBarViewModel()
    let webContentViewModel = WebContentViewModel()
    let cardGridViewModel = CardGridViewModel()
    let tabsModel = TabsModel()
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
        let selectedID = tabsModel.data.sections[id: currentTabsSection]!.selectedTab
        cardGridViewModel.replaceAllCards(cards, selectedID: selectedID)

//        cardGridViewModel.showGrid = true

//        urlInputViewModel.visibility = .showing(initialValue: "", forTarget: .newTab)
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
