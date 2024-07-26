import UIKit

final class MainMenu: UIMenu {
    enum Action {
        case toggleIncognito(Bool)
    }

    static func build(with config: MainMenuConfig, handler: @escaping (Action) -> Void) -> UIMenu {
        let incognitoAction: UIAction = .init(
            title: "Incognito",
            image: .init(systemName: config.incognitoChecked ? "checkmark.square" : "square")
        ) { _ in
            handler(.toggleIncognito(!config.incognitoChecked))
        }

        return .init(children: [incognitoAction])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
