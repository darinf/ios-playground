import UIKit

enum Colors {
    static let foregroundText: UIColor = .init(dynamicProvider: { traits in
        if case .dark = traits.userInterfaceStyle {
            return .white
        }
        return .black
    })
}
