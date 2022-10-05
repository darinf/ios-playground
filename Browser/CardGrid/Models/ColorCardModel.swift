// Copyright 2022 Darin Fisher. All rights reserved.

import Foundation
import UIKit

private func pixelFromColor(_ color: UIColor) -> UIImage {
    let size = CGSize(width: 1, height: 1)
    return UIGraphicsImageRenderer(size: size).image { rendererContext in
        color.setFill()
        rendererContext.fill(CGRect(origin: .zero, size: size))
    }
}

class ColorCardModel: CardModel {
    let id: String
    let title: String
    let thumbnail: UIImage
    let favicon: UIImage

    init(title: String, color: UIColor) {
        self.id = UUID().uuidString
        self.title = title
        self.thumbnail = pixelFromColor(color)
        self.favicon = thumbnail
    }
}
