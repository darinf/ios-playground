// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct ShowTabsView: View {
    let namespace: Namespace.ID
    var height: CGFloat = 40

    var body: some View {
        Circle()
            .fill(Color(uiColor: .systemBackground))
            .matchedGeometryEffect(id: "showTabs.circle", in: namespace)
            .frame(height: height)
            .shadow(radius: OmniBarUX.shadowRadius)
            .overlay(
                Image(systemName: "square.on.square")
                    .matchedGeometryEffect(id: "showTabs.icon", in: namespace)
            )
    }
}
