// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

struct SmallCardView<Card>: View where Card: CardModel {
    let namespace: Namespace.ID
    let card: Card
    let selected: Bool
    let zoomed: Bool

    @State private var cardRadius: CGFloat = CardUX.cardRadius

    var body: some View {
        Group {
            if selected && zoomed {
                Color.clear
            } else {
                CardView(namespace: namespace, card: card, selected: selected, zoomed: zoomed)
            }
        }
        .transition(.identity.animation(.default))
    }
}

