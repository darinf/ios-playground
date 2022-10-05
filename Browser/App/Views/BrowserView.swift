// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct BrowserView: View {
    @ObservedObject var model: BrowserViewModel

    var body: some View {
        CardGridView(model: model.cardGridViewModel)
        // probably have some transition event here to let us know when to show
        // the selected browser tab
    }
}
