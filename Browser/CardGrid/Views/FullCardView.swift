// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

// The transitional variant of `CardView` when zooming in/out.
struct FullCardView<Card>: View, Animatable where Card: CardModel {
    let namespace: Namespace.ID
    let model: CardViewModel<Card>

    var body: some View {
        CardView(namespace: namespace, model: model, selected: true, zoomed: true)
            .overlay(CloseButtonView<Card>(namespace: namespace, model: model))
            .zIndex(1)
            .transition(.identity.animation(.default))
            .padding(.bottom, OmniBarUX.dockedHeight)
            .ignoresSafeArea(edges: .bottom)
    }
}
