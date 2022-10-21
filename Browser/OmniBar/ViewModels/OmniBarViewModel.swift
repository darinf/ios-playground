// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import SwiftUI

class OmniBarViewModel: ObservableObject {
    let urlFieldViewModel = UrlFieldViewModel()
    @Published var expanded: Bool = true
    @Published var docked: Bool = true
    @Published var canEditCurrentUrl: Bool = true
}
