import UIKit

final class CardGridCellView: UICollectionViewCell {
    var card: Card? {
        didSet {
            updateThumbnail(card?.thumbnail)
        }
    }

    private var thumbnailView = {
        let imageView = UIImageView(image: nil)
        imageView.contentMode = .topLeft
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        return imageView
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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateThumbnail(_ thumbnail: UIImage?) {
        thumbnailView.image = thumbnail?.resizeTopAlignedToFill(newWidth: bounds.width)
    }
}
