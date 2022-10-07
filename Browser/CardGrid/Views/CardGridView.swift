// Copyright 2022 Darin Fisher. All rights reserved.

import SwiftUI

enum CardGridUX {
    static let spacing: CGFloat = 18
}

struct CardGridView<Card, ZoomedContent, OverlayContent>: View where Card: CardModel, ZoomedContent: View, OverlayContent: View {
    @Namespace var namespace
    @ObservedObject var model: CardGridViewModel<Card>
    @ViewBuilder let bottomOverlay: (_ zoomed: Bool) -> OverlayContent
    @ViewBuilder let zoomedCard: (_ card: Card) -> ZoomedContent

    @State private var showContent = false

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
                    .onAnimationCompleted(for: model.zoomed) {
                        showContent = model.zoomed
                    }

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
                        .overlay(
                            Group {
                                if showContent {
                                    zoomedCard(cardDetail.model.card)
                                }
                            }
                        )
                        .ignoresSafeArea(edges: .bottom)
                    }
                }

                VStack {
                    Spacer()
                    bottomOverlay(model.zoomed)
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
