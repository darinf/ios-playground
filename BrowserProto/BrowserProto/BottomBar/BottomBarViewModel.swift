import Combine
import Foundation

final class BottomBarViewModel {
    let centerButtonViewModel = CenterButtonViewModel()

    @Published var mainMenuConfig: MainMenuConfig = .init(incognitoChecked: false)
}
