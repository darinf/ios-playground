import Combine
import Foundation

final class BottomBarViewModel {
    @Published var expanded: Bool = false
    @Published var url: URL?
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var progress: Double?
    @Published var mainMenuConfig: MainMenuConfig = .init(incognitoChecked: false)
}
