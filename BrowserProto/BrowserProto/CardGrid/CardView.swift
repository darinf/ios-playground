import Combine
import UIKit

final class CardView: UIView {
    enum Action {
        case closed
    }

    enum Metrics {
        static let closeButtonRadius: CGFloat = 10
        static let margin: CGFloat = 5
        static let cornerRadius: CGFloat = 10
        static let footerHeight: CGFloat = 16
        static let footerPadding: CGFloat = 4
        static let footerIconDimension: CGFloat = footerHeight
        static let titleFontSize: CGFloat = 12
        static let bottomMargin = footerHeight + footerPadding
    }

    private let model: CardViewModel
    private let handler: (Action) -> Void
    private var subscriptions: Set<AnyCancellable> = []

    private lazy var closeButton = {
        CapsuleButton(
            cornerRadius: Metrics.closeButtonRadius,
            hitAreaInset: Metrics.margin,
            systemImage: "multiply"
        ) { [weak self] in
            self?.handler(.closed)
        }
    }()

    private lazy var footerView = {
        let view = UIStackView()
        view.spacing = Metrics.footerPadding
        return view
    }()

    private lazy var titleView = {
        let label = UILabel()
        label.tintColor = .black
        label.font = .systemFont(ofSize: Metrics.titleFontSize, weight: .medium)
        label.text = "Hello World"
        return label
    }()

    private lazy var iconView = {
        let view = UIImageView(image: .init(systemName: "globe"))
        view.tintColor = .black
        return view
    }()

    private var imageContentView: ImageContentView?
    private var tiledContentView: TiledContentView?

    init(model: CardViewModel, handler: @escaping (Action) -> Void = { _ in }) {
        self.model = model
        self.handler = handler
        super.init(frame: .zero)

        addSubview(closeButton)
        addSubview(footerView)

        footerView.addArrangedSubview(iconView)
        footerView.addArrangedSubview(titleView)

        if let card = model.card {
            titleView.text = card.title
            iconView.image = card.favicon?.value

            switch card.content {
            case let .image(image):
                setupAsImage(image)
            case let .tiled(images, overage: overage):
                setupAsTiled(images, overage: overage)
            }
        }

        bringSubviewToFront(closeButton)

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

        footerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            footerView.topAnchor.constraint(equalTo: bottomAnchor, constant: Metrics.footerPadding),
            footerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            footerView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor),
            footerView.heightAnchor.constraint(equalToConstant: Metrics.footerHeight)
        ])

        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: Metrics.footerIconDimension),
            iconView.heightAnchor.constraint(equalToConstant: Metrics.footerIconDimension)
        ])
    }

    private func setupObservers() {
        model.$selected.sink { [weak self] selected in
            guard let self else { return }
            if selected {
                imageContentView?.layer.borderWidth = 2
                imageContentView?.layer.borderColor = UIColor.systemTeal.withAlphaComponent(0.5).cgColor
            } else {
                imageContentView?.layer.borderWidth = 0
            }
        }.store(in: &subscriptions)

        model.$hideDecorations.dropFirst().sink { [weak self] hide in
            guard let self else { return }
            closeButton.layer.opacity = hide ? 0 : 1
            footerView.layer.opacity = hide ? 0 : 1
            imageContentView?.layer.cornerRadius = hide ? 0 : Metrics.cornerRadius
            imageContentView?.thumbnailView.layer.cornerRadius = hide ? 0 : Metrics.cornerRadius
        }.store(in: &subscriptions)
    }

    private func setupAsImage(_ image: ImageRef?) {
        let imageContentView = ImageContentView(image: image)
        self.imageContentView = imageContentView

        addSubview(imageContentView)
        imageContentView.activateContainmentConstraints(inside: self)
    }

    private func setupAsTiled(_ images: [ImageRef?], overage: Int) {
        let tiledContentView = TiledContentView(images: images, overage: overage)
        self.tiledContentView = tiledContentView

        addSubview(tiledContentView)
        tiledContentView.activateContainmentConstraints(inside: self)
    }
}

private final class ImageContentView: UIView {
    private let image: ImageRef?

    lazy var thumbnailView = {
        ThumbnailView(image: image?.value)
    }()

    init(image: ImageRef?) {
        self.image = image
        super.init(frame: .zero)

        thumbnailView.layer.cornerRadius = CardView.Metrics.cornerRadius
        addSubview(thumbnailView)

        layer.cornerRadius = CardView.Metrics.cornerRadius
        DropShadow.apply(toLayer: layer)

        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        thumbnailView.activateContainmentConstraints(inside: self)
    }
}

private final class TiledContentView: UIView {
    private let images: [ImageRef?]
    private let overage: Int

    lazy var clipView = {
        let view = UIView()
        view.layer.cornerRadius = CardView.Metrics.cornerRadius
        view.clipsToBounds = true
        return view
    }()

    private lazy var thumbnailViews: [ThumbnailView] = {
        (0..<3).map { .init(image: imageAt($0)) }
    }()

    init(images: [ImageRef?], overage: Int) {
        self.images = images
        self.overage = overage
        super.init(frame: .zero)

        clipView.addSubview(thumbnailViews[0])
        clipView.addSubview(thumbnailViews[1])
        clipView.addSubview(thumbnailViews[2])
        addSubview(clipView)

        layer.cornerRadius = CardView.Metrics.cornerRadius
        DropShadow.apply(toLayer: layer)

        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        clipView.activateContainmentConstraints(inside: self)
        
        thumbnailViews.forEach {
            NSLayoutConstraint.activate([
                $0.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.48),
                $0.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.48)
            ])
        }

        thumbnailViews[0].translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            thumbnailViews[0].topAnchor.constraint(equalTo: topAnchor),
            thumbnailViews[0].leftAnchor.constraint(equalTo: leftAnchor)
        ])

        thumbnailViews[1].translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            thumbnailViews[1].topAnchor.constraint(equalTo: topAnchor),
            thumbnailViews[1].rightAnchor.constraint(equalTo: rightAnchor)
        ])

        thumbnailViews[2].translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            thumbnailViews[2].bottomAnchor.constraint(equalTo: bottomAnchor),
            thumbnailViews[2].leftAnchor.constraint(equalTo: leftAnchor)
        ])
    }

    private func imageAt(_ index: Int) -> UIImage? {
        guard index < images.endIndex else { return nil }
        return images[index]?.value
    }
}

private final class ThumbnailView: UIView {
    lazy var imageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        return view
    }()

    init(image: UIImage?) {
        super.init(frame: .zero)

        clipsToBounds = true

        addSubview(imageView)
        imageView.image = image
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.widthAnchor.constraint(equalTo: widthAnchor)
        ])

        guard let image else { return }

        // Allow the height of the imageView to overflow the bounds of its
        // container. We will just clip the part the spills over.
        let aspectRatio = image.size.height / image.size.width
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: aspectRatio)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
