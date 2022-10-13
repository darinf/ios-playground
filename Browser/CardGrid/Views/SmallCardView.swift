// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct SmallCardView<Card>: View where Card: CardModel {
    let namespace: Namespace.ID
    @ObservedObject var model: CardViewModel<Card>
    let selected: Bool
    let zoomed: Bool
    let handler: (_ action: CardView<Card>.Action) -> Void

    var body: some View {
        Group {
            if selected && zoomed {
                Color.clear
            } else {
                CardView(namespace: namespace, model: model, selected: selected, zoomed: false, handler: handler)
            }
        }
        .transition(.identity.animation(.default))
        .aspectRatio(CardUX.aspectRatio, contentMode: .fill)
        .zIndex(selected ? 1 : 0)
    }
}

