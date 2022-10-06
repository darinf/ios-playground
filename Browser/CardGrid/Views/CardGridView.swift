// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

enum CardGridUX {
    static let spacing: CGFloat = 18
}

struct CardGridView<Card>: View where Card: CardModel {
    @Namespace var namespace
    @ObservedObject var model: CardGridViewModel<Card>

    var grid: some View {
        ScrollView(showsIndicators: false) {
            let columns = [
                GridItem(.adaptive(minimum: CardUX.minimumCardWidth),
                         spacing: CardGridUX.spacing)
            ]
            LazyVGrid(columns: columns, spacing: CardGridUX.spacing + CardUX.titleHeight + CardUX.verticalSpacing) {
                ForEach(model.cards) { cardDetail in
                    let selected = model.selectedCardId == cardDetail.id
                    InteractiveButtonView {
                        if model.zoomed { return }
                        model.selectedCardId = cardDetail.id
                        withAnimation(CardUX.transitionAnimation) {
                            model.zoomed = true
                        }
                    } label: {
                        SmallCardView(
                            namespace: namespace,
                            model: cardDetail.model,
                            selected: selected,
                            zoomed: model.zoomed
                        )
                        .aspectRatio(CardUX.aspectRatio, contentMode: .fill)
                    }
                    .zIndex(selected ? 1 : 0)
                }
            }
            .padding(CardGridUX.spacing)
        }
    }

    var body: some View {
        ZStack {
            grid
            if let selectedCardId = model.selectedCardId {
                if let cardDetail = model.cards.first(where: { $0.id == selectedCardId }), model.zoomed {
                    FullCardView(
                        namespace: namespace,
                        model: cardDetail.model
                    )
                    .onTapGesture {
                        withAnimation(CardUX.transitionAnimation) {
                            model.zoomed = false
                        }
                    }
                }
            }
        }
        .onAppear {
            model.selectedCardId = model.cards[0].id
        }
    }
}
