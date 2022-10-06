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
                    SmallCardView(
                        namespace: namespace,
                        model: cardDetail.model,
                        selected: selected,
                        zoomed: model.zoomed
                    ) {
                        if model.zoomed { return }
                        model.selectedCardId = cardDetail.id
                        withAnimation(CardUX.transitionAnimation) {
                            model.zoomed = true
                        }
                    }
                }
            }
            .padding(CardGridUX.spacing)
        }
    }

    var body: some View {
        GeometryReader { geom in
            ZStack(alignment: .top) {
                grid

                Color(uiColor: .systemBackground)
                    .frame(height: geom.safeAreaInsets.top)
                    .offset(y: model.zoomed ? 0 : -geom.safeAreaInsets.top)
                    .ignoresSafeArea()

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

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color(uiColor: .systemBackground))
                            .frame(height: 50)
                            .offset(x: -50, y: model.zoomed ? -50 : 100)
                    }
                }
                .ignoresSafeArea(edges: [.top, .bottom])
                .zIndex(2)
            }
            .onAppear {
                model.selectedCardId = model.cards[0].id
            }
        }
    }
}
