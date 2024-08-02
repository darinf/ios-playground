import Combine
import UIKit

final class CenterButtonView: UIView {
    enum Action {
        case clicked
    }

    private enum Metrics {
        static let plusModeWidth: CGFloat = 100
    }

    private let model: CenterButtonViewModel
    private let cornerRadius: CGFloat
    private let handler: (Action) -> Void
    private var subscriptions: Set<AnyCancellable> = []
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)

    private lazy var labelView = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.lineBreakMode = .byTruncatingHead
        return label
    }()

    private lazy var imageView = {
        let view = UIImageView(image: .init(systemName: "plus"))
        view.tintColor = Colors.foregroundText
        view.layer.opacity = 0
        return view
    }()

    private lazy var backgroundView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = cornerRadius
        DropShadow.apply(toLayer: view.layer)
        return view
    }()

    private lazy var backgroundViewFullWidthConstraint = {
        backgroundView.widthAnchor.constraint(equalTo: widthAnchor)
    }()

    private lazy var backgroundViewMinWidthConstraint = {
        backgroundView.widthAnchor.constraint(equalToConstant: Metrics.plusModeWidth)
    }()

    private lazy var progressContainerView = {
        ProgressContainerView(cornerRadius: cornerRadius)
    }()

    private lazy var pressGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(onPress))
        gesture.minimumPressDuration = 0
        return gesture
    }()

    init(model: CenterButtonViewModel, cornerRadius: CGFloat, handler: @escaping (Action) -> Void) {
        self.model = model
        self.cornerRadius = cornerRadius
        self.handler = handler
        super.init(frame: .zero)

        addSubview(backgroundView)
        addSubview(labelView)
        addSubview(imageView)

        backgroundView.addSubview(progressContainerView)
        backgroundView.sendSubviewToBack(progressContainerView)

        sendSubviewToBack(backgroundView)

        backgroundView.addGestureRecognizer(pressGestureRecognizer)

        setupConstraints()
        setupObservers()
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
        labelView.text = displayText
    }

    func setImage(_ image: UIImage?) {
        imageView.image = image
    }

    private func setupConstraints() {
        labelView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelView.centerXAnchor.constraint(equalTo: centerXAnchor),
            labelView.centerYAnchor.constraint(equalTo: centerYAnchor),
            labelView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -20)
        ])

        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])

        progressContainerView.activateContainmentConstraints(inside: backgroundView)
    }

    private func setupObservers() {
        model.$text.dropFirst().removeDuplicates().sink { [weak self] text in
            self?.setDisplayText(text)
        }.store(in: &subscriptions)

        model.$progress.dropFirst().removeDuplicates().sink { [weak self] progress in
            self?.setProgress(progress)
        }.store(in: &subscriptions)

        model.$mode.sink { [weak self] mode in
            self?.updateLayout(forMode: mode)
        }.store(in: &subscriptions)
    }

    private func updateLayout(forMode mode: CenterButtonViewModel.Mode) {
        switch mode {
        case .showAsPlus:
            backgroundViewFullWidthConstraint.isActive = false
            backgroundViewMinWidthConstraint.isActive = true
            UIView.animate(withDuration: 0.3) {
                self.layoutIfNeeded()
            }
            UIView.animate(withDuration: 0.15) {
                self.labelView.layer.opacity = 0
            } completion: { _ in
                UIView.animate(withDuration: 0.15, delay: 0.15) {
                    self.imageView.layer.opacity = 1
                }
            }
        case .showAsText:
            backgroundViewMinWidthConstraint.isActive = false
            backgroundViewFullWidthConstraint.isActive = true
            UIView.animate(withDuration: 0.3) {
                self.layoutIfNeeded()
            }
            UIView.animate(withDuration: 0.15) {
                self.imageView.layer.opacity = 0
            } completion: { _ in
                UIView.animate(withDuration: 0.15, delay: 0.15) {
                    self.labelView.layer.opacity = 1
                }
            }
        }
    }

    @objc private func onPress(_ gesture: UITapGestureRecognizer) {
        if case .ended = gesture.state {
            backgroundView.backgroundColor = .systemBackground
            feedbackGenerator.impactOccurred(intensity: 0.7)
            handler(.clicked)
        } else {
            backgroundView.backgroundColor = .systemFill
        }
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
