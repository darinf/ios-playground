import Combine
import UIKit

final class CardView: UIView {
    enum Action {
        case closed
    }

    private enum Metrics {
        static let closeButtonRadius: CGFloat = 10
        static let margin: CGFloat = 5
        static let cornerRadius: CGFloat = 10
    }

    private let model: CardViewModel
    private let handler: (Action) -> Void
    private var subscriptions: Set<AnyCancellable> = []

    private lazy var closeButton = {
        CapsuleButton(cornerRadius: Metrics.closeButtonRadius, systemImage: "multiply") { [weak self] in
            self?.handler(.closed)
        }
    }()

    private lazy var thumbnailShadowView = {
        let view = UIView()
        view.layer.cornerRadius = Metrics.cornerRadius
        DropShadow.apply(toLayer: view.layer)
        return view
    }()

    private lazy var thumbnailClipView = {
        let view = UIView()
        view.layer.cornerRadius = Metrics.cornerRadius
        view.clipsToBounds = true
        return view
    }()

    private lazy var thumbnailView = {
        let imageView = UIImageView(image: nil)
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private var thumbnailViewHeightConstraint: NSLayoutConstraint?

    init(model: CardViewModel, handler: @escaping (Action) -> Void = { _ in }) {
        self.model = model
        self.handler = handler
        super.init(frame: .zero)

        addSubview(thumbnailShadowView)
        addSubview(closeButton)

        thumbnailShadowView.addSubview(thumbnailClipView)
        thumbnailClipView.addSubview(thumbnailView)

        setupConstraints()
        setupObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: Metrics.closeButtonRadius * 2),
            closeButton.heightAnchor.constraint(equalToConstant: Metrics.closeButtonRadius * 2),
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.margin),
            closeButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -Metrics.margin)
        ])

        thumbnailShadowView.activateContainmentConstraints(inside: self)
        thumbnailClipView.activateContainmentConstraints(inside: thumbnailShadowView)

        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            thumbnailView.topAnchor.constraint(equalTo: thumbnailClipView.topAnchor),
            thumbnailView.widthAnchor.constraint(equalTo: thumbnailClipView.widthAnchor),
        ])
    }

    private func setupObservers() {
        model.$selected.sink { [weak self] selected in
            guard let self else { return }
            if selected {
                thumbnailShadowView.layer.borderWidth = 2
                thumbnailShadowView.layer.borderColor = UIColor.systemTeal.withAlphaComponent(0.5).cgColor
            } else {
                thumbnailShadowView.layer.borderWidth = 0
            }
        }.store(in: &subscriptions)

        model.$thumbnail.sink { [weak self] thumbnail in
            guard let self else { return }
            guard let thumbnail else {
                thumbnailView.image = nil
                thumbnailViewHeightConstraint = nil
                return
            }

            thumbnailView.image = thumbnail

            let aspectRatio = thumbnail.size.height / thumbnail.size.width
            thumbnailViewHeightConstraint = thumbnailView.heightAnchor.constraint(
                equalTo: thumbnailView.widthAnchor, multiplier: aspectRatio
            )
            thumbnailViewHeightConstraint?.isActive = true
        }.store(in: &subscriptions)
    }
}
