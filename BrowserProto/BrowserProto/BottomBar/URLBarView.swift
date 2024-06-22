import UIKit

final class URLBarView: UIView {
    private let onPanUp: (CGFloat) -> Void

    private lazy var panGestureRecognizer = {
        UIPanGestureRecognizer(target: self, action: #selector(onPan))
    }()

    init(cornerRadius: CGFloat, onPanUp: @escaping (CGFloat) -> Void) {
        self.onPanUp = onPanUp
        super.init(frame: .zero)

        backgroundColor = .systemBackground

        layer.cornerRadius = cornerRadius
        clipsToBounds = true

        addGestureRecognizer(panGestureRecognizer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func onPan() {
        let translation = panGestureRecognizer.translation(in: self)
        if translation.y < 0 {
            onPanUp(-translation.y)
        }
    }
}
