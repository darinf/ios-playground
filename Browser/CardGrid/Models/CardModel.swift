// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import UIKit

protocol CardModel: ObservableObject, Identifiable {
    var id: String { get }
    var title: String { get }
    var thumbnail: UIImage { get }
    var favicon: UIImage { get }
    func prepareToShowAsThumbnail(completion: @escaping () -> Void)
}
