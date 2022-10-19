// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct ShowMenuView: View {
    let namespace: Namespace.ID
    let height: CGFloat

    var body: some View {
        Circle()
            .fill(Color(uiColor: .systemBackground))
            .matchedGeometryEffect(id: "menu.circle", in: namespace)
            .frame(height: height)
            .shadow(radius: OmniBarUX.shadowRadius)
            .overlay(
                Image(systemName: "ellipsis")
                    .foregroundColor(OmniBarUX.textColor)
                    .matchedGeometryEffect(id: "menu.icon", in: namespace)
            )
    }
}
