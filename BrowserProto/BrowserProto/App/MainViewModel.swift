import Combine
import Foundation

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
}
