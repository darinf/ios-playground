// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct ShowCardsView: View {
    let namespace: Namespace.ID
    let height: CGFloat

    var body: some View {
        Circle()
            .fill(Color(uiColor: .systemBackground))
            .matchedGeometryEffect(id: "showTabs.circle", in: namespace)
            .frame(height: height)
            .shadow(radius: OmniBarUX.shadowRadius)
            .overlay(
                Image(systemName: "square.on.square")
                    .foregroundColor(OmniBarUX.textColor)
                    .matchedGeometryEffect(id: "showTabs.icon", in: namespace)
            )
    }
}
