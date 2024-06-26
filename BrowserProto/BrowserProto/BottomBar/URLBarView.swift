import Combine
import UIKit

final class URLBarView: UIView {
    let model = URLBarViewModel()

    private let onPanGesture: (CGFloat) -> Void
    private var subscriptions: Set<AnyCancellable> = []

    private lazy var label = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        label.textColor = Colors.foregroundText
        label.numberOfLines = 1
        return label
    }()

    private lazy var panGestureRecognizer = {
        UIPanGestureRecognizer(target: self, action: #selector(onPan))
    }()

    init(cornerRadius: CGFloat, onPanGesture: @escaping (CGFloat) -> Void) {
        self.onPanGesture = onPanGesture
        super.init(frame: .zero)

        backgroundColor = .systemBackground

        layer.cornerRadius = cornerRadius
        DropShadow.apply(toLayer: layer)
//        clipsToBounds = true

        isUserInteractionEnabled = true

        addGestureRecognizer(panGestureRecognizer)

        addSubview(label)

        setupObservers()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupObservers() {
        model.$displayText.dropFirst().sink { [weak self] displayText in
            print(">>> displayText: \(displayText)")
            self?.label.text = displayText
        }.store(in: &subscriptions)
    }

    private func setupConstraints() {
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
//            label.widthAnchor.constraint(equalTo: widthAnchor),
//            label.heightAnchor.constraint(equalTo: heightAnchor)
        ])
    }

//    override func layoutSubviews() {
//        print(">>> URLBarView.layoutSubviews")
//        label.frame = bounds
//    }

//    override var frame: CGRect {
//        didSet {
//            print(">>> didSet frame: \(frame)")
//        }
//    }

    @objc private func onPan() {
        let translation = panGestureRecognizer.translation(in: self)
        onPanGesture(translation.y)
    }
}
