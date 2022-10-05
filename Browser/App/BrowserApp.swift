// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

@main
struct BrowserApp: App {
    let browserViewModel = BrowserViewModel()

    var body: some Scene {
        WindowGroup {
            BrowserView(model: browserViewModel)
        }
    }
}
