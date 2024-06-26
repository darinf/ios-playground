import Combine
import UIKit

final class URLBarView: CapsuleButton {
    let model = URLBarViewModel()

    private let onPanGesture: (CGFloat) -> Void
    private var subscriptions: Set<AnyCancellable> = []

    private lazy var panGestureRecognizer = {
        UIPanGestureRecognizer(target: self, action: #selector(onPan))
    }()

    init(cornerRadius: CGFloat, onPanGesture: @escaping (CGFloat) -> Void) {
        self.onPanGesture = onPanGesture
        super.init(cornerRadius: cornerRadius) { [model] in
            model.editing = true
        }

        backgroundColor = .systemBackground

        layer.cornerRadius = cornerRadius
        DropShadow.apply(toLayer: layer)

        isUserInteractionEnabled = true

        addGestureRecognizer(panGestureRecognizer)

        setupObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupObservers() {
        model.$displayText.dropFirst().sink { [weak self] displayText in
            print(">>> displayText: \(displayText)")
            self?.setTitle(displayText, for: .normal)
        }.store(in: &subscriptions)
    }

    @objc private func onPan() {
        let translation = panGestureRecognizer.translation(in: self)
        onPanGesture(translation.y)
    }
}
