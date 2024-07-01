import Combine
import UIKit

final class URLBarView: CapsuleButton {
    enum Action {
        case clicked
    }

    private let handler: (Action) -> Void

    init(cornerRadius: CGFloat, handler: @escaping (Action) -> Void) {
        self.handler = handler
        super.init(cornerRadius: cornerRadius) {
            handler(.clicked)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setProgress(_ progress: Double?) {
        print(">>> showProgress: \(progress)")
    }

    func setDisplayText(_ displayText: String) {
        setTitle(displayText, for: .normal)
    }
}
