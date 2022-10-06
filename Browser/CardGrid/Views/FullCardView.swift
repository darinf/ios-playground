// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct FullCardView<Card>: View where Card: CardModel {
    let namespace: Namespace.ID
    let model: CardViewModel<Card>

    var body: some View {
        CardView(namespace: namespace, model: model, selected: true, zoomed: true)
            .zIndex(1)
            .ignoresSafeArea(edges: .bottom)
            .transition(.identity.animation(.default))
    }
}
