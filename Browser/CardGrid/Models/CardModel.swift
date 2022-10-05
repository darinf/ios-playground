//
//  CardModel.swift
//  CardGrid
//
//  Created by Darin Fisher on 10/3/22.
//

import Combine
import UIKit

protocol CardModel: ObservableObject, Identifiable {
    var id: String { get }
    var title: String { get }
    var thumbnail: UIImage { get }
    var favicon: UIImage { get }
}
