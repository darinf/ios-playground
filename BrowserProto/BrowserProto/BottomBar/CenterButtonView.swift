import Combine
import UIKit

final class CenterButtonView: CapsuleButton {
    enum Action {
        case clicked
    }

    private let handler: (Action) -> Void

    private lazy var progressContainerView = {
        ProgressContainerView(cornerRadius: layer.cornerRadius)
    }()

    init(cornerRadius: CGFloat, handler: @escaping (Action) -> Void) {
        self.handler = handler
        super.init(cornerRadius: cornerRadius) {
            handler(.clicked)
        }

        addSubview(progressContainerView)
        sendSubviewToBack(progressContainerView)

        titleLabel?.font = .systemFont(ofSize: 14)
        titleLabel?.lineBreakMode = .byTruncatingHead

        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func resetProgressWithoutAnimation() {
        progressContainerView.progress = nil
    }

    func setProgress(_ progress: Double?) {
        if let progress {
            UIView.animate(withDuration: 0.2) { [self] in
                progressContainerView.progress = progress
                progressContainerView.layoutIfNeeded()
            }
        } else if progressContainerView.progress != nil {
            UIView.animate(withDuration: 0.2) { [self] in
                progressContainerView.progress = 1.0
                progressContainerView.layoutIfNeeded()
            } completion: { [self] _ in
                UIView.animate(withDuration: 0.01, delay: 0.35) { [self] in
                    progressContainerView.progress = nil
                    progressContainerView.layoutIfNeeded()
                }
            }
        }
    }

    func setDisplayText(_ displayText: String) {
        setTitle(displayText, for: .normal)
    }

    func setImage(_ image: UIImage?) {
        setImage(image, for: .normal)
    }

    private func setupConstraints() {
        progressContainerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressContainerView.topAnchor.constraint(equalTo: topAnchor),
            progressContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            progressContainerView.leftAnchor.constraint(equalTo: leftAnchor),
            progressContainerView.rightAnchor.constraint(equalTo: rightAnchor)
        ])
    }
}

private final class ProgressContainerView: UIView {
    var progress: Double? {
        didSet {
            setNeedsLayout()
        }
    }

    private lazy var progressView = {
        let view = UIView()
        view.backgroundColor = .systemTeal.withAlphaComponent(0.5)
        view.isUserInteractionEnabled = false
        return view
    }()

    init(cornerRadius: CGFloat) {
        super.init(frame: .zero)

        addSubview(progressView)

        layer.cornerRadius = cornerRadius
        clipsToBounds = true
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        progressView.frame = .init(
            origin: .zero,
            size: .init(
                width: (progress ?? 0) * bounds.width,
                height: bounds.height
            )
        )
    }
}
