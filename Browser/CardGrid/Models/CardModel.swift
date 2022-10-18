// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import UIKit

protocol CardModel: ObservableObject, Identifiable where ID == UUID {
    var id: ID { get }
    var title: String { get }
    var thumbnail: UIImage { get }
    var favicon: UIImage { get }
    func updateThumbnail(completion: @escaping () -> Void)
}
