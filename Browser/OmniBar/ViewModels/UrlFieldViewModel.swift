// Copyright 2022 Darin Fisher. All rights reserved.

import Combine
import SwiftUI

class UrlFieldViewModel: ObservableObject {
    @Published var input = ""
    @Published var hasFocus = false
    @Published private(set) var isLoading = false
    @Published private(set) var progress: Double = 0.0

    func reset() {
        input = ""
        hasFocus = false
        isLoading = false
        progress = 0.0
    }

    func update(isLoading: Bool) {
        withAnimation {
            self.isLoading = isLoading
        }
    }

    func update(progress: Double) {
        // Only animate left to right.
        if self.progress == 1.0 && progress < 1.0 {
            self.progress = progress
        } else {
            withAnimation {
                self.progress = progress
            }
        }
    }
}
