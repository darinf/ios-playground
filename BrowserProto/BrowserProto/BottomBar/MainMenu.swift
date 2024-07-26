import Combine
import UIKit

final class MainMenu {
    private let model: MainMenuModel
    private let incognitoAction: UIAction
    private var subscriptions: Set<AnyCancellable> = []

    init(model: MainMenuModel) {
        self.model = model

        incognitoAction = .init(title: "Incognito", image: Self.image(forIncognito: false)) { _ in
            print(">>> toggle incognito")
            model.incognito.toggle()
        }

        setupObservers()
    }

    var menu: UIMenu {
        .init(children: [incognitoAction])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupObservers() {
        model.$incognito.dropFirst().removeDuplicates().sink { [weak self] incognito in
            print(">>> update incognitoAction: \(incognito)")
            self?.incognitoAction.image = Self.image(forIncognito: incognito)
        }.store(in: &subscriptions)
    }

    private static func image(forIncognito incognito: Bool) -> UIImage? {
        .init(systemName: incognito ? "checked.square" : "square")
    }
}
