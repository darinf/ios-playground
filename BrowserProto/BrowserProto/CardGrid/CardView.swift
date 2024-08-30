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
        CapsuleButton(cornerRadius: Metrics.closeButtonRadius, systemImage: "multiply") { [weak self] in
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
        addSubview(footerView)

        footerView.addArrangedSubview(iconView)
        footerView.addArrangedSubview(titleView)

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
                thumbnailShadowView.layer.borderWidth = 2
                thumbnailShadowView.layer.borderColor = UIColor.systemTeal.withAlphaComponent(0.5).cgColor
            } else {
                thumbnailShadowView.layer.borderWidth = 0
            }
        }.store(in: &subscriptions)

        model.$thumbnail.sink { [weak self] thumbnail in
            guard let self else { return }
            guard let thumbnail = thumbnail?.value else {
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

        model.$hideDecorations.dropFirst().sink { [weak self] hide in
            guard let self else { return }
            closeButton.layer.opacity = hide ? 0 : 1
            footerView.layer.opacity = hide ? 0 : 1
            thumbnailShadowView.layer.cornerRadius = hide ? 0 : Metrics.cornerRadius
            thumbnailClipView.layer.cornerRadius = hide ? 0 : Metrics.cornerRadius
        }.store(in: &subscriptions)

        model.$title.sink { [weak self] title in
            self?.titleView.text = title ?? ""
        }.store(in: &subscriptions)

        model.$favicon.sink { [weak self] favicon in
            self?.iconView.image = favicon?.value
        }.store(in: &subscriptions)
    }
}
