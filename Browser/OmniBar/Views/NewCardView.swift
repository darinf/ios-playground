// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct NewCardView: View {
    let namespace: Namespace.ID
    var height: CGFloat = 40

    var body: some View {
        Circle()
            .fill(Color(uiColor: .systemBackground))
            .matchedGeometryEffect(id: "startSearch.circle", in: namespace)
            .frame(height: height)
            .shadow(radius: OmniBarUX.shadowRadius)
            .overlay(
                Image(systemName: "plus")
                    .foregroundColor(OmniBarUX.textColor)
                    .matchedGeometryEffect(id: "startSearch.icon", in: namespace)
            )
    }
}
