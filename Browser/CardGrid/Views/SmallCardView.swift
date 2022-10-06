// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct SmallCardView<Card>: View where Card: CardModel {
    let namespace: Namespace.ID
    @ObservedObject var model: CardViewModel<Card>
    let selected: Bool
    let zoomed: Bool
    let action: () -> Void

    var body: some View {
        Button() {
            action()
        } label: {
            Group {
                if selected && zoomed {
                    Color.clear
                } else {
                    CardView(namespace: namespace, model: model, selected: selected, zoomed: false)
                }
            }
            .transition(.identity.animation(.default))
            .aspectRatio(CardUX.aspectRatio, contentMode: .fill)
        }
        .buttonStyle(.reportsPresses(pressed: $model.pressed))
        .zIndex(selected ? 1 : 0)
    }
}

