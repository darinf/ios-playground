// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import SwiftUI

class OmniBarViewModel: ObservableObject {
    let urlFieldViewModel = UrlFieldViewModel()
    @Published var expanded: Bool = false
    @Published private(set) var hidden: Bool = false

    func update(hidden: Bool) {
        withAnimation {
            self.hidden = hidden
        }
    }
}
