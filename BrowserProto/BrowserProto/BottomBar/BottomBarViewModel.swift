import Combine
import Foundation

final class BottomBarViewModel {
    @Published var url: URL?
    @Published var progress: Double?
    @Published var mainMenuConfig: MainMenuConfig = .init(incognitoChecked: false)
    @Published var configureForAllTabs: Bool = false
}
