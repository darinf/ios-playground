//
//  SmallCardView.swift
//  CardGrid
//
//  Created by Darin Fisher on 10/4/22.
//

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

