import UIKit

final class URLBarView: UIView {
    private let onPanGesture: (CGFloat) -> Void

    private lazy var panGestureRecognizer = {
        UIPanGestureRecognizer(target: self, action: #selector(onPan))
    }()

    init(cornerRadius: CGFloat, onPanGesture: @escaping (CGFloat) -> Void) {
        self.onPanGesture = onPanGesture
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
        onPanGesture(translation.y)
    }
}
