import UIKit

final class CardGridCellView: UICollectionViewCell {
    private enum Metrics {
        static let closeButtonRadius: CGFloat = 10
        static let margin: CGFloat = 5
    }

    var model: CardGridViewModel?

    var card: Card? {
        didSet {
            thumbnailView.image = card?.thumbnail?.resizeTopAlignedToFill(newWidth: bounds.width)
        }
    }

    private var thumbnailView = {
        let imageView = UIImageView(image: nil)
        imageView.contentMode = .topLeft
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var closeButton = {
        CapsuleButton(cornerRadius: Metrics.closeButtonRadius, systemImage: "multiply") { [weak self] in
            guard let self, let model, let card else { return }
            model.removeCard(byID: card.id)
        }
    }()

    override var isSelected: Bool {
        didSet {
            if isSelected {
                thumbnailView.layer.borderWidth = 2
                thumbnailView.layer.borderColor = UIColor.systemTeal.withAlphaComponent(0.5).cgColor
            } else {
                thumbnailView.layer.borderWidth = 0
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundView = thumbnailView
        DropShadow.apply(toLayer: layer)

        contentView.addSubview(closeButton)

        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        model = nil
        card = nil
    }

    private func setupConstraints() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: Metrics.closeButtonRadius * 2),
            closeButton.heightAnchor.constraint(equalToConstant: Metrics.closeButtonRadius * 2),
            closeButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Metrics.margin),
            closeButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -Metrics.margin)
        ])
    }
}
