import UIKit

final class CardGridCellView: UICollectionViewCell {
    var card: Card? {
        didSet {
            updateThumbnail(card?.thumbnail)
        }
    }

    override var isSelected: Bool {
        didSet {
            updateSelectionIndicator()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .systemTeal
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateThumbnail(_ thumbnail: UIImage?) {
        guard let thumbnail else {
            backgroundColor = .systemTeal // TODO: use better fallback
            return
        }

        backgroundColor = .clear

        let imageView = UIImageView(image: thumbnail.resizeTopAlignedToFill(newWidth: bounds.width))
        imageView.contentMode = .topLeft
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        backgroundView = imageView

        DropShadow.apply(toLayer: layer)

        updateSelectionIndicator()
    }

    private func updateSelectionIndicator() {
        if isSelected {
            backgroundView?.layer.borderWidth = 2
            backgroundView?.layer.borderColor = UIColor.systemTeal.withAlphaComponent(0.5).cgColor
        } else {
            backgroundView?.layer.borderWidth = 0
        }
    }
}
