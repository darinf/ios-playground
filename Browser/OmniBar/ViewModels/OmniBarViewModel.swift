// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import SwiftUI

class OmniBarViewModel: ObservableObject {
    let urlFieldViewModel = UrlFieldViewModel()
    @Published var expanded: Bool = true
    @Published var docked: Bool = true
    @Published private(set) var hidden: Bool = false
    @Published var canEditCurrentUrl: Bool = true
    @Published var doneAnimatingHidden: Bool = true

    func update(hidden: Bool) {
        guard self.hidden != hidden else { return }
        doneAnimatingHidden = false
        withAnimation {
            self.hidden = hidden
        }
    }
}
