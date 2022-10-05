// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct SmallCardView<Card>: View where Card: CardModel {
    let namespace: Namespace.ID
    let model: CardViewModel<Card>
    let selected: Bool
    let zoomed: Bool

    var body: some View {
        Group {
            if selected && zoomed {
                Color.clear
            } else {
                CardView(namespace: namespace, model: model, selected: selected, zoomed: false)
            }
        }
        .transition(.identity.animation(.default))
    }
}

