//
//  CardGrid.swift
//  CardGrid
//
//  Created by Darin Fisher on 10/3/22.
//

import SwiftUI

enum CardGridUX {
    static let spacing: CGFloat = 18
}

struct CardGridView<Card>: View where Card: CardModel {
    let namespace: Namespace.ID
    let cards: [Card]
    @Binding var selectedCardId: String?
    @Binding var zoomed: Bool

    var body: some View {
        ScrollView {
            let columns = [
                GridItem(.adaptive(minimum: CardUX.minimumCardWidth),
                         spacing: CardGridUX.spacing)
            ]
            LazyVGrid(columns: columns, spacing: CardGridUX.spacing + CardUX.titleHeight + CardUX.verticalSpacing) {
                ForEach(cards) { card in
                    let selected = selectedCardId == card.id
                    InteractiveButtonView {
                        selectedCardId = card.id
                        withAnimation(CardUX.animation) {
                            zoomed = true
                        }
                    } label: {
                        SmallCardView(
                            namespace: namespace,
                            card: card,
                            selected: selected,
                            zoomed: zoomed
                        )
                        .aspectRatio(CardUX.aspectRatio, contentMode: .fill)
                    }
                    .zIndex(selected ? 1 : 0)
                }
            }
            .padding(CardGridUX.spacing)
        }
    }
}
