// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import UIKit

protocol CardModel: ObservableObject, Identifiable where ID == UUID {
    var id: ID { get }
    var nextId: ID? { get set }
    var title: String { get }
    var thumbnail: UIImage { get }
    var favicon: UIImage { get }
    func close()
    func updateThumbnail(completion: @escaping () -> Void)
}
