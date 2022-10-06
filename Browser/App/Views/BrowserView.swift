// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct BrowserView: View {
    @ObservedObject var model: BrowserViewModel

    var body: some View {
        ZStack {
            CardGridView(
                model: model.cardGridViewModel,
                bottomOverlay: { zoomed in
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color(uiColor: .systemBackground))
                            .frame(height: 50)
                            .offset(x: -50, y: zoomed ? -50 : 100)
                    }
                }
            )

            // probably have some transition event here to let us know when to show
            // the selected browser tab

        }
    }
}
