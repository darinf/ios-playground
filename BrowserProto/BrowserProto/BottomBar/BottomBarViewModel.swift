import Combine
import Foundation

final class BottomBarViewModel {
    let mainMenuModel = MainMenuModel()
    
    @Published var expanded: Bool = false
    @Published var url: URL?
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var progress: Double?
}
