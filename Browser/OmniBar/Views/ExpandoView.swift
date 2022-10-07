// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct ExpandoView: View {
    let namespace: Namespace.ID
    var height: CGFloat = 50

    var body: some View {
        Circle()
            .fill(Color(uiColor: .systemBackground))
            .matchedGeometryEffect(id: "expando", in: namespace)
            .frame(height: height)
            .shadow(radius: OmniBarUX.shadowRadius)
    }
}
